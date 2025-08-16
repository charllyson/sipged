import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';

import '../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../_blocs/documents/measurement/measurement_bloc.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/documents/measurement/measurement_data.dart';
import '../../../../_utils/handle_selection_utils.dart';

class RevisionMeasurementController extends ChangeNotifier with FormValidationMixin {
  final ReportsBloc _measurementBloc = ReportsBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final UserBloc _userBloc = UserBloc();

  final ContractData contract;

  // estado
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // dados carregados (universo completo)
  List<ReportData> revision = [];

  // paginação
  final int _itemsPerPage = 50;
  List<ReportData> selectorUniverse = []; // pode receber filtros no futuro
  List<ReportData> pageItems = [];        // página atual
  int currentPage = 1;
  int totalPages = 1;

  double valorInicialContrato = 0.0;
  double totalAditivos = 0.0;

  // seleção
  ReportData? selectedRevision;
  String? currentRevisionId;

  // controllers de input
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  RevisionMeasurementController({required this.contract}) {
    _init();
  }

  void _init() {
    setupValidation(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl],
      _validateForm,
    );
  }

  Future<void> postFrameInit(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user != null) {
      isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
    }
    await loadInitialData();
  }

  // ---------- LOAD ----------
  Future<void> loadInitialData() async {
    if (contract.id == null) {
      revision = [];
      selectorUniverse = [];
      _refreshPagination();
      notifyListeners();
      return;
    }

    valorInicialContrato = contract.initialValueContract ?? 0.0;
    totalAditivos        = await _additivesBloc.getAllAdditivesValue(contract.id!);
    revision             = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);

    // ordena por ordem, fallback por data de revisão
    revision.sort((a, b) {
      final ao = a.orderRevisionMeasurement ?? -1;
      final bo = b.orderRevisionMeasurement ?? -1;
      if (ao != bo) return ao.compareTo(bo);
      final ad = a.dateRevisionMeasurement?.millisecondsSinceEpoch ?? 0;
      final bd = b.dateRevisionMeasurement?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });

    selectorUniverse = List.of(revision);

    // sugere próxima ordem
    final last = selectorUniverse.isNotEmpty
        ? selectorUniverse.map((e) => e.orderRevisionMeasurement ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (last + 1).toString();

    currentPage = 1;
    _refreshPagination();
    notifyListeners();
  }

  // ---------- PAGINAÇÃO ----------
  void _refreshPagination() {
    final total = selectorUniverse.length;
    totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > total) ? total : start + _itemsPerPage;
    pageItems = (start < end) ? selectorUniverse.sublist(start, end) : [];
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > totalPages) return;
    currentPage = page;
    _refreshPagination();
    notifyListeners();
  }

  // ---------- DERIVADOS p/ gráficos/tabela ----------
  List<String> get labels =>
      selectorUniverse.map((m) => (m.orderRevisionMeasurement ?? 0).toString()).toList();

  List<double> get values =>
      selectorUniverse.map((m) => m.valueRevisionMeasurement ?? 0.0).toList();

  double get totalMedicoes => values.fold(0.0, (a, b) => a + b);
  double get valorTotalDisponivel => valorInicialContrato + totalAditivos;
  double get saldo => valorTotalDisponivel - totalMedicoes;

  // ---------- FORM ----------
  void _validateForm() {
    final ok = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(ReportData data) {
    selectedRevision = data;
    currentRevisionId = data.idRevisionMeasurement;

    orderCtrl.text   = (data.orderRevisionMeasurement ?? '').toString();
    processCtrl.text = data.numberRevisionProcessMeasurement ?? '';
    valueCtrl.text   = priceToString(data.valueRevisionMeasurement);
    dateCtrl.text    = convertDateTimeToDDMMYYYY(data.dateRevisionMeasurement);

    _validateForm();
    notifyListeners();
  }

  Future<void> createNew() async {
    selectedLine = null;
    selectedRevision = null;
    currentRevisionId = null;

    final last = selectorUniverse.isNotEmpty
        ? selectorUniverse.map((e) => e.orderRevisionMeasurement ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;

    orderCtrl.text = (last + 1).toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();

    _validateForm();
    notifyListeners();
  }

  // ---------- CRUD ----------
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final novo = ReportData(
        idRevisionMeasurement: currentRevisionId,
        contractId: contract.id!,
        orderRevisionMeasurement: int.tryParse(orderCtrl.text),
        numberRevisionProcessMeasurement: processCtrl.text,
        valueRevisionMeasurement: parseCurrencyToDouble(valueCtrl.text),
        dateRevisionMeasurement: convertDDMMYYYYToDateTime(dateCtrl.text),
      );

      await _measurementBloc.saveOrUpdateMeasurement(novo);

      // recarrega lista e mantém paginação
      await loadInitialData();
      formValidated = true;
      await createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medição salva com sucesso!'), backgroundColor: Colors.green),
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
    try {
      await _measurementBloc.deletarMedicao(contract.id!, id);
      await loadInitialData();
      selectedLine = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medição apagada com sucesso.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover: $e')),
        );
      }
    }
  }

  // ---------- Seleção (gráfico/tabela) ----------
  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < selectorUniverse.length) {
      handleSelect(selectorUniverse[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(ReportData data) {
    handleGenericSelection<ReportData>(
      data: data,
      list: selectorUniverse,
      getOrder: (e) => e.orderRevisionMeasurement,
      onSetState: (index) {
        selectedLine = index;
        selectedRevision = data;
        currentRevisionId = data.idRevisionMeasurement;
        fillFields(data);
      },
    );
  }

  // ---------- PDF ----------
  Future<void> savePdfUrl(String url) async {
    if (contract.id == null || selectedRevision?.idRevisionMeasurement == null) return;
    await _measurementBloc.salvarUrlPdfDaMedicao(
      contractId: contract.id!,
      measurementId: selectedRevision!.idRevisionMeasurement!,
      url: url,
    );
  }

  @override
  void dispose() {
    removeValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }
}
