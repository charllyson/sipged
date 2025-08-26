import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 👈 novo
import 'package:sisged/_blocs/system/user/user_bloc.dart';
import 'package:sisged/_blocs/system/user/user_state.dart';

import 'package:sisged/_utils/validates/form_validation_mixin.dart';
import 'package:sisged/_utils/formats/format_field.dart';
import 'package:sisged/_utils/date_utils.dart'
    show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart';

import 'package:sisged/_blocs/system/user/user_data.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:sisged/_utils/handle_selection_utils.dart';

class RevisionMeasurementController extends ChangeNotifier with FormValidationMixin {
  RevisionMeasurementController({
    required ReportMeasurementBloc measurementBloc,
    required AdditivesBloc additivesBloc,
  })  : _measurementBloc = measurementBloc,
        _additivesBloc = additivesBloc;

  // --- Dependências
  final ReportMeasurementBloc _measurementBloc;
  final AdditivesBloc _additivesBloc;

  // 👇 assinatura do UserBloc
  StreamSubscription<UserState>? _userSub;

  // --- Contexto
  late ContractData contract; // não-nulo
  UserData? currentUser;

  // --- Estado UI
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedIndex;

  // --- Dados
  List<ReportMeasurementData> _all = <ReportMeasurementData>[];
  List<ReportMeasurementData> _selectorUniverse = <ReportMeasurementData>[];

  // --- Paginação
  final int _itemsPerPage = 50;
  int _currentPage = 1;
  int _totalPages = 1;
  List<ReportMeasurementData> _pageItems = <ReportMeasurementData>[];

  // --- Seleção
  ReportMeasurementData? _selected;
  String? _currentId;

  // --- Totais
  double _valorInicialContrato = 0.0;
  double _totalAditivos = 0.0;

  // --- Controllers de formulário
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // === Getters usados pela UI ===
  List<ReportMeasurementData> get revision => _all;
  List<ReportMeasurementData> get selectorUniverse => _selectorUniverse;
  List<ReportMeasurementData> get pageItems => _pageItems;

  ReportMeasurementData? get selectedRevision => _selected;
  String? get currentRevisionId => _currentId;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  double get valorInicialContrato => _valorInicialContrato;
  double get totalAditivos => _totalAditivos;

  List<String> get labels =>
      _selectorUniverse.map((m) => (m.orderRevisionMeasurement ?? 0).toString()).toList();

  List<double> get values =>
      _selectorUniverse.map((m) => m.valueRevisionMeasurement ?? 0.0).toList();

  double get totalMedicoes => values.fold<double>(0.0, (a, b) => a + b);
  double get valorTotalDisponivel => _valorInicialContrato + _totalAditivos;
  double get saldo => valorTotalDisponivel - totalMedicoes;

  // === Init/Dispose ===
  Future<void> init(BuildContext context, {required ContractData contractData}) async {
    contract = contractData; // garantido não-nulo

    // 👇 pega o usuário atual do UserBloc e calcula permissão
    final userBloc = context.read<UserBloc>();
    currentUser = userBloc.state.current;
    isEditable = _canEditUser(currentUser);

    // 👇 assina mudanças do UserBloc para refletir permissões em tempo real
    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
      final prevId = currentUser?.id;
      currentUser = st.current;
      final nowId = currentUser?.id;

      final newEditable = _canEditUser(currentUser);
      if (newEditable != isEditable || prevId != nowId) {
        isEditable = newEditable;
        notifyListeners();
      }
    });

    setupValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    await _loadInitial();
  }

  @override
  void dispose() {
    _userSub?.cancel(); // 👈 importante
    removeValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  // === Permissões (ajuste se usar módulo/granular) ===
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    final perms = user.modulePermissions['measurement_revision'];
    if (perms != null) return (perms['edit'] == true) || (perms['create'] == true);
    return false;
  }

  // === Load ===
  Future<void> _loadInitial() async {
    _valorInicialContrato = contract.initialValueContract ?? 0.0;
    _totalAditivos = await _additivesBloc.getAllAdditivesValue(contract.id!);

    _all = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);

    _all.sort((a, b) {
      final ao = a.orderRevisionMeasurement ?? -1;
      final bo = b.orderRevisionMeasurement ?? -1;
      if (ao != bo) return ao.compareTo(bo);
      final ad = a.dateRevisionMeasurement?.millisecondsSinceEpoch ?? 0;
      final bd = b.dateRevisionMeasurement?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });

    _selectorUniverse = List<ReportMeasurementData>.from(_all);

    // Sugerir próxima ordem
    final last = _selectorUniverse.isNotEmpty
        ? _selectorUniverse
        .map((e) => e.orderRevisionMeasurement ?? 0)
        .reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (last + 1).toString();

    _currentPage = 1;
    _refreshPagination();
    notifyListeners();
  }

  void _refreshPagination() {
    final total = _selectorUniverse.length;
    _totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > total) ? total : start + _itemsPerPage;
    _pageItems = (start < end) ? _selectorUniverse.sublist(start, end) : <ReportMeasurementData>[];
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _refreshPagination();
    notifyListeners();
  }

  // === Form/Validação ===
  void _validateFormInternal() {
    final valid = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // === Seleção (gráfico/tabela) ===
  void onSelectGraphIndex(int index) {
    selectedIndex = index;
    if (index >= 0 && index < _selectorUniverse.length) {
      handleSelect(_selectorUniverse[index]);
    } else {
      notifyListeners();
    }
  }

  void selectRow(ReportMeasurementData data) {
    final idx = _selectorUniverse.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.idRevisionMeasurement;

    orderCtrl.text = (data.orderRevisionMeasurement ?? '').toString();
    processCtrl.text = data.numberRevisionProcessMeasurement ?? '';
    valueCtrl.text = priceToString(data.valueRevisionMeasurement);
    dateCtrl.text = convertDateTimeToDDMMYYYY(data.dateRevisionMeasurement);

    _validateFormInternal();
    notifyListeners();
  }

  void handleSelect(ReportMeasurementData data) {
    handleGenericSelection<ReportMeasurementData>(
      data: data,
      list: _selectorUniverse,
      getOrder: (e) => e.orderRevisionMeasurement,
      onSetState: (index) {
        selectedIndex = index;
        _selected = data;
        _currentId = data.idRevisionMeasurement;
        selectRow(data); // preenche campos
      },
    );
  }

  void createNew() {
    final last = _selectorUniverse.isNotEmpty
        ? _selectorUniverse
        .map((e) => e.orderRevisionMeasurement ?? 0)
        .reduce((a, b) => a > b ? a : b)
        : 0;

    selectedIndex = null;
    _selected = null;
    _currentId = null;

    orderCtrl.text = (last + 1).toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();

    _validateFormInternal();
    notifyListeners();
  }

  // === CRUD ===
  Future<bool> saveOrUpdate({
    required Future<bool> Function() onConfirm,
    VoidCallback? onSuccessSnack,
    VoidCallback? onErrorSnack,
  }) async {
    final confirmed = await onConfirm();
    if (!confirmed) return false;

    try {
      isSaving = true;
      notifyListeners();

      final novo = ReportMeasurementData(
        idRevisionMeasurement: _currentId,
        contractId: contract.id!,
        orderRevisionMeasurement: int.tryParse(orderCtrl.text),
        numberRevisionProcessMeasurement: processCtrl.text,
        valueRevisionMeasurement: parseCurrencyToDouble(valueCtrl.text),
        dateRevisionMeasurement: convertDDMMYYYYToDateTime(dateCtrl.text),
      );

      await _measurementBloc.saveOrUpdateMeasurement(novo);
      await _loadInitial(); // recarrega lista/paginação
      createNew();

      onSuccessSnack?.call();
      return true;
    } catch (_) {
      onErrorSnack?.call();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveExact(
      ReportMeasurementData data, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    try {
      isSaving = true;
      notifyListeners();

      final toSave = ReportMeasurementData(
        idRevisionMeasurement: data.idRevisionMeasurement,
        contractId: contract.id!,
        orderRevisionMeasurement: data.orderRevisionMeasurement,
        numberRevisionProcessMeasurement: data.numberRevisionProcessMeasurement,
        valueRevisionMeasurement: data.valueRevisionMeasurement,
        dateRevisionMeasurement: data.dateRevisionMeasurement,
      );

      await _measurementBloc.saveOrUpdateMeasurement(toSave);
      await _loadInitial();
      createNew();
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteById(
      String idRevisionMeasurement, {
        VoidCallback? onSuccessSnack,
        VoidCallback? onErrorSnack,
      }) async {
    try {
      await _measurementBloc.deletarMedicao(contract.id!, idRevisionMeasurement);
      await _loadInitial();
      selectedIndex = null;
      onSuccessSnack?.call();
    } catch (_) {
      onErrorSnack?.call();
    } finally {
      notifyListeners();
    }
  }

  // === PDF ===
  Future<void> savePdfUrl(String url) async {
    if (_selected?.idRevisionMeasurement == null) return;
    await _measurementBloc.salvarUrlPdfDaMedicao(
      contractId: contract.id!,
      measurementId: _selected!.idRevisionMeasurement!,
      url: url,
    );
  }
}
