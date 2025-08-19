import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';
import 'package:sisged/_widgets/formats/format_field.dart';

import '../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import '../../../../_blocs/documents/measurement/report/report_measurement_bloc.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_datas/documents/measurement/reports/report_measurement_data.dart';
import '../../../../_utils/handle_selection_utils.dart';

class AdjustmentMeasurementController extends ChangeNotifier with FormValidationMixin {
  final ReportMeasurementBloc _measurementBloc = ReportMeasurementBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final ApostillesBloc _apostillesBloc = ApostillesBloc();
  final UserBloc _userBloc = UserBloc();

  final ContractData contract;

  // estado
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // dados carregados
  List<ReportMeasurementData> adjustments = [];
  double totalApostilles = 0.0;   // soma das apostilas
  double totalAdditives = 0.0;    // soma dos aditivos

  // seleção
  ReportMeasurementData? selectedAdjustment;
  String? currentAdjustmentId;

  // controllers de input
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  AdjustmentMeasurementController({required this.contract}) {
    _init();
  }

  Future<void> _init() async {
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

    totalApostilles = await _apostillesBloc.getAllApostillesValue(contract.id!);
    totalAdditives  = await _additivesBloc.getAllAdditivesValue(contract.id!);
    adjustments     = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);

    // define próxima ordem
    final last = adjustments.map((e) => e.orderAdjustmentMeasurement ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();

    notifyListeners();
  }

  // ---------- DERIVADOS p/ gráficos/tabela ----------
  List<String> get labels =>
      adjustments.map((m) => (m.orderAdjustmentMeasurement ?? 0).toString()).toList();

  List<double> get values =>
      adjustments.map((m) => m.valueAdjustmentMeasurement ?? 0.0).toList();

  double get totalAdjustments =>
      values.fold(0.0, (a, b) => a + b);

  double get valorTotalDisponivel =>
      totalApostilles + totalAdditives;

  double get saldo =>
      valorTotalDisponivel - totalAdjustments;

  // ---------- FORM ----------
  void _validateForm() {
    final ok = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(ReportMeasurementData data) {
    selectedAdjustment = data;
    currentAdjustmentId = data.idAdjustmentMeasurement;

    orderCtrl.text   = (data.orderAdjustmentMeasurement ?? '').toString();
    processCtrl.text = data.numberAdjustmentProcessMeasurement ?? '';
    valueCtrl.text   = priceToString(data.valueAdjustmentMeasurement);
    dateCtrl.text    = convertDateTimeToDDMMYYYY(data.dateAdjustmentMeasurement);

    _validateForm();
    notifyListeners();
  }

  Future<void> createNew() async {
    selectedLine = null;
    selectedAdjustment = null;
    currentAdjustmentId = null;

    final last = adjustments.map((e) => e.orderAdjustmentMeasurement ?? 0).fold(0, (a, b) => a > b ? a : b);
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

    final novo = ReportMeasurementData(
      contractId: contract.id!,
      idAdjustmentMeasurement: currentAdjustmentId,
      orderAdjustmentMeasurement: int.tryParse(orderCtrl.text),
      numberAdjustmentProcessMeasurement: processCtrl.text,
      valueAdjustmentMeasurement: parseCurrencyToDouble(valueCtrl.text),
      dateAdjustmentMeasurement: convertDDMMYYYYToDateTime(dateCtrl.text),
    );

    await _measurementBloc.saveOrUpdateMeasurement(novo);

    adjustments = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);
    await createNew();

    isSaving = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reajuste salvo com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> deleteAdjustment(BuildContext context, String id) async {
    if (contract.id == null) return;
    await _measurementBloc.deletarMedicao(contract.id!, id);
    adjustments = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);
    selectedLine = null;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reajuste apagado com sucesso.'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------- Seleção (gráfico/tabela) ----------
  void applySelectionList(List<ReportMeasurementData> list) {
    // se quiser manter uma cópia; hoje usamos `adjustments` direto
  }

  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < adjustments.length) {
      handleSelect(adjustments[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(ReportMeasurementData data) {
    handleGenericSelection<ReportMeasurementData>(
      data: data,
      list: adjustments,
      getOrder: (e) => e.orderAdjustmentMeasurement,
      onSetState: (index) {
        selectedLine = index;
        selectedAdjustment = data;
        currentAdjustmentId = data.idAdjustmentMeasurement;
        fillFields(data);
      },
    );
  }

  // ---------- PDF ----------
  Future<void> savePdfUrl(String url) async {
    if (contract.id == null || selectedAdjustment?.idReportMeasurement == null) return;
    await _measurementBloc.salvarUrlPdfDaMedicao(
      contractId: contract.id!,
      measurementId: selectedAdjustment!.idReportMeasurement!,
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
