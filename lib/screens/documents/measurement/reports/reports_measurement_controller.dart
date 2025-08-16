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

class ReportsMeasurementController extends ChangeNotifier with FormValidationMixin {
  final ReportsBloc _measurementBloc = ReportsBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final UserBloc _userBloc = UserBloc();

  final ContractData contract;

  // estado
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // dados carregados
  List<ReportData> reports = [];
  double valorInicialContrato = 0.0;
  double totalAditivos = 0.0;

  // seleção
  ReportData? selectedReport;
  String? currentReportId;

  // controllers de input
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  ReportsMeasurementController({required this.contract}) {
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
    if (contract.id == null) return;

    valorInicialContrato = contract.initialValueContract ?? 0.0;
    totalAditivos        = await _additivesBloc.getAllAdditivesValue(contract.id!);
    reports              = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);

    final last = reports.map((e) => e.orderReportMeasurement ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();

    notifyListeners();
  }

  // ---------- DERIVADOS p/ gráficos/tabela ----------
  List<String> get labels =>
      reports.map((m) => (m.orderReportMeasurement ?? 0).toString()).toList();

  List<double> get values =>
      reports.map((m) => m.valueReportMeasurement ?? 0.0).toList();

  double get totalMedicoes =>
      values.fold(0.0, (a, b) => a + b);

  double get valorTotalDisponivel =>
      valorInicialContrato + totalAditivos;

  double get saldo =>
      valorTotalDisponivel - totalMedicoes;

  // ---------- FORM ----------
  void _validateForm() {
    final ok = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(ReportData data) {
    selectedReport = data;
    currentReportId = data.idReportMeasurement;

    orderCtrl.text   = (data.orderReportMeasurement ?? '').toString();
    processCtrl.text = data.numberProcessReportMeasurement ?? '';
    valueCtrl.text   = priceToString(data.valueReportMeasurement);
    dateCtrl.text    = convertDateTimeToDDMMYYYY(data.dateReportMeasurement);

    _validateForm();
    notifyListeners();
  }

  Future<void> createNew() async {
    selectedLine = null;
    selectedReport = null;
    currentReportId = null;

    final last = reports.map((e) => e.orderReportMeasurement ?? 0).fold(0, (a, b) => a > b ? a : b);
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

    final novo = ReportData(
      idReportMeasurement: currentReportId,
      contractId: contract.id!,
      orderReportMeasurement: int.tryParse(orderCtrl.text),
      numberProcessReportMeasurement: processCtrl.text,
      valueReportMeasurement: parseCurrencyToDouble(valueCtrl.text),
      dateReportMeasurement: convertDDMMYYYYToDateTime(dateCtrl.text),
    );

    await _measurementBloc.saveOrUpdateMeasurement(novo);
    reports = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);
    await createNew();

    isSaving = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medição salva com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> deleteReport(BuildContext context, String id) async {
    if (contract.id == null) return;
    await _measurementBloc.deletarMedicao(contract.id!, id);
    reports = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);
    selectedLine = null;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medição apagada com sucesso.'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------- Seleção (gráfico/tabela) ----------
  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < reports.length) {
      handleSelect(reports[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(ReportData data) {
    handleGenericSelection<ReportData>(
      data: data,
      list: reports,
      getOrder: (e) => e.orderReportMeasurement,
      onSetState: (index) {
        selectedLine = index;
        selectedReport = data;
        currentReportId = data.idReportMeasurement;
        fillFields(data);
      },
    );
  }

  // ---------- PDF ----------
  Future<void> savePdfUrl(String url) async {
    if (contract.id == null || selectedReport?.idReportMeasurement == null) return;
    await _measurementBloc.salvarUrlPdfDaMedicao(
      contractId: contract.id!,
      measurementId: selectedReport!.idReportMeasurement!,
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
