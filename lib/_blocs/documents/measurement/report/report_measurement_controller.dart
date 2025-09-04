import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // segue ok
import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/handle_selection_utils.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'report_measurement_bloc.dart';
import 'report_measurement_storage_bloc.dart';

class ReportMeasurementController extends ChangeNotifier with FormValidationMixin {
  ReportMeasurementController({
    required this.contract,
    ReportMeasurementBloc? measurementBloc,
    AdditivesBloc? additivesBloc,
    ReportMeasurementStorageBloc? storageBloc,
  })  : _measurementBloc = measurementBloc ?? ReportMeasurementBloc(),
        _additivesBloc = additivesBloc ?? AdditivesBloc(),
        _storageBloc = storageBloc ?? ReportMeasurementStorageBloc() {
    _initValidation();
  }

  // ---- deps / bloc ----
  final ReportMeasurementBloc _measurementBloc; // REPORT-only
  final AdditivesBloc _additivesBloc;
  final ReportMeasurementStorageBloc _storageBloc;

  // ---- contexto ----
  final ContractData contract;
  UserData? _currentUser;

  // assinatura do UserBloc
  StreamSubscription<UserState>? _userSub;

  // ---- estado UI ----
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // ---- dados / paginação ----
  final int _itemsPerPage = 50;
  List<ReportMeasurementData> _all = <ReportMeasurementData>[];
  List<ReportMeasurementData> selectorUniverse = <ReportMeasurementData>[];
  List<ReportMeasurementData> _pageItems = <ReportMeasurementData>[];

  int _currentPage = 1;
  int _totalPages = 1;

  // Expostos para a UI (tabela)
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  List<ReportMeasurementData> get reports => _pageItems;
  ReportMeasurementStorageBloc get reportMeasurementStorageBloc => _storageBloc;

  // ---- agregados (contrato) ----
  double valorInicialContrato = 0.0;
  double totalAditivos = 0.0;

  double get valorTotalDisponivel => valorInicialContrato + totalAditivos;
  double get totalMedicoes =>
      selectorUniverse.fold<double>(0.0, (a, e) => a + (e.value ?? 0.0));
  double get saldo => valorTotalDisponivel - totalMedicoes;

  // ---- seleção ----
  ReportMeasurementData? selectedReport;
  String? currentReportId;

  // ---- controllers do form ----
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // ---- derivados p/ gráfico ----
  List<String> get labels =>
      selectorUniverse.map((m) => (m.order ?? 0).toString()).toList();

  List<double> get values =>
      selectorUniverse.map((m) => (m.value ?? 0.0)).toList();

  // ================= LIFECYCLE =================
  void _initValidation() {
    setupValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
  }

  /// chame em addPostFrameCallback no widget
  Future<void> init(BuildContext context) async {
    // lê usuário atual do UserBloc
    final userBloc = context.read<UserBloc>();
    _currentUser = userBloc.state.current;
    isEditable = _canEditUser(_currentUser);

    // assina mudanças do UserBloc para atualizar permissões
    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
      final prevId = _currentUser?.id;
      _currentUser = st.current;
      final nowId = _currentUser?.id;

      final newEditable = _canEditUser(_currentUser);
      if (newEditable != isEditable || prevId != nowId) {
        isEditable = newEditable;
        notifyListeners();
      }
    });

    await _loadInitialData();
  }

  Future<void> postFrameInit(BuildContext context) => init(context);

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  // ================= PERMISSÕES =================
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    final perms = user.modulePermissions['report_measurement'];
    if (perms != null) return (perms['edit'] == true) || (perms['create'] == true);

    return false;
  }

  // ================= LOAD / PAGE =================
  Future<void> _loadInitialData() async {
    if (contract.id == null) {
      _all = [];
      selectorUniverse = [];
      _refreshPagination();
      notifyListeners();
      return;
    }

    valorInicialContrato = contract.initialValueContract ?? 0.0;
    totalAditivos        = await _additivesBloc.getAllAdditivesValue(contract.id!);

    _all = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);

    // ordena por ordem; fallback por data
    _all.sort((a, b) {
      final ao = a.order ?? -1;
      final bo = b.order ?? -1;
      if (ao != bo) return ao.compareTo(bo);
      final ad = a.date?.millisecondsSinceEpoch ?? 0;
      final bd = b.date?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });

    selectorUniverse = List<ReportMeasurementData>.from(_all);

    // sugere próxima ordem
    final lastOrder = selectorUniverse.isNotEmpty
        ? selectorUniverse
        .map((e) => e.order ?? 0)
        .reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (lastOrder + 1).toString();

    _currentPage = 1;
    _refreshPagination();
    notifyListeners();
  }

  void _refreshPagination() {
    final total = selectorUniverse.length;
    _totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > total) ? total : start + _itemsPerPage;
    _pageItems = (start < end) ? selectorUniverse.sublist(start, end) : <ReportMeasurementData>[];
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _refreshPagination();
    notifyListeners();
  }

  // ================= FORM =================
  void _validateForm() {
    final ok = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(ReportMeasurementData data) {
    selectedReport  = data;
    currentReportId = data.id;

    orderCtrl.text   = (data.order ?? '').toString();
    processCtrl.text = data.numberprocess ?? '';
    valueCtrl.text   = priceToString(data.value);
    dateCtrl.text    = convertDateTimeToDDMMYYYY(data.date);

    _validateForm();
    notifyListeners();
  }

  void createNew() {
    selectedLine    = null;
    selectedReport  = null;
    currentReportId = null;

    final nextOrder = (selectorUniverse.isNotEmpty
        ? selectorUniverse
        .map((e) => e.order ?? 0)
        .reduce((a, b) => a > b ? a : b)
        : 0) + 1;

    orderCtrl.text = nextOrder.toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();

    _validateForm();
    notifyListeners();
  }

  // ================= CRUD (REPORT) =================
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final novo = ReportMeasurementData(
        id: currentReportId,
        contractId: contract.id!,
        order: int.tryParse(orderCtrl.text),
        numberprocess: processCtrl.text,
        value: parseCurrencyToDouble(valueCtrl.text),
        date: convertDDMMYYYYToDateTime(dateCtrl.text),
      );

      // ⬇️ agora chama o método REPORT-only
      await _measurementBloc.saveOrUpdateReport(novo);

      await _loadInitialData(); // recarrega + repagina
      createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medição salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteReport(BuildContext context, String id) async {
    if (contract.id == null) return;
    isSaving = true;
    notifyListeners();

    try {
      await _measurementBloc.deletarMedicao(contract.id!, id);
      await _loadInitialData();

      if (currentReportId == id) {
        createNew();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medição apagada com sucesso.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao apagar: $e')),
        );
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ================= Seleção (gráfico/tabela) =================
  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < selectorUniverse.length) {
      handleSelect(selectorUniverse[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(ReportMeasurementData data) {
    handleGenericSelection<ReportMeasurementData>(
      data: data,
      list: selectorUniverse,
      getOrder: (e) => e.order,
      onSetState: (index) {
        selectedLine    = index;
        selectedReport  = data;
        currentReportId = data.id;
        fillFields(data);
      },
    );
  }

  // ================= PDF (Storage) =================
  Future<void> uploadPdf({
    required void Function(double progress) onProgress,
  }) async {
    if (contract.id == null || selectedReport?.id == null) return;

    final url = await _storageBloc.uploadWithPicker(
      contract: contract,
      reportMeasurement: selectedReport!, // objeto atual
      onProgress: onProgress,
    );

    await _storageBloc.salvarUrlPdfDaReportMeasurement(
      contractId: contract.id!,
      reportMeasurementId: selectedReport!.id!, // 👈 nome correto
      url: url,
    );
  }

  Future<void> savePdfUrl(String url) async {
    if (contract.id == null || selectedReport?.id == null) return;
    await _storageBloc.salvarUrlPdfDaReportMeasurement(
      contractId: contract.id!,
      reportMeasurementId: selectedReport!.id!, // 👈 nome correto
      url: url,
    );
  }
}
