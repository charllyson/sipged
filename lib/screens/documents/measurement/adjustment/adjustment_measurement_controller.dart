import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';
import 'package:sisged/_widgets/formats/format_field.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart';

import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_datas/documents/measurement/reports/report_measurement_data.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_utils/handle_selection_utils.dart';

class AdjustmentMeasurementController extends ChangeNotifier
    with FormValidationMixin {
  // ---- deps / blocs ----
  final ReportMeasurementBloc _measurementBloc = ReportMeasurementBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final ApostillesBloc _apostillesBloc = ApostillesBloc();

  final ContractData contract;

  // ---- estado UI ----
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // ---- dados carregados ----
  List<ReportMeasurementData> adjustments = [];
  double totalApostilles = 0.0; // soma das apostilas
  double totalAdditives = 0.0;  // soma dos aditivos

  // ---- seleção ----
  ReportMeasurementData? selectedAdjustment;
  String? currentAdjustmentId;

  // ---- controllers do form ----
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  AdjustmentMeasurementController({required this.contract}) {
    _init();
  }

  void _init() {
    setupValidation(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl],
      _validateForm,
    );
  }

  Future<void> postFrameInit(BuildContext context) async {
    final user = context.read<UserProvider>().userData;
    isEditable = _canEditUser(user);
    await loadInitialData();
  }

  // ---- permissões (ajuste o nome do módulo se usar outro) ----
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    // Permissão granular opcional por módulo
    final perms = user.modulePermissions['adjustment_measurement'];
    if (perms != null) {
      return (perms['edit'] == true) || (perms['create'] == true);
    }
    return false;
  }

  // ---------- LOAD ----------
  Future<void> loadInitialData() async {
    if (contract.id == null) {
      adjustments = [];
      orderCtrl.clear();
      processCtrl.clear();
      valueCtrl.clear();
      dateCtrl.clear();
      notifyListeners();
      return;
    }

    totalApostilles =
    await _apostillesBloc.getAllApostillesValue(contract.id!);
    totalAdditives =
    await _additivesBloc.getAllAdditivesValue(contract.id!);
    adjustments = await _measurementBloc
        .getAllMeasurementsOfContract(uidContract: contract.id!);

    // define próxima ordem
    final last = adjustments
        .map((e) => e.orderAdjustmentMeasurement ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();

    notifyListeners();
  }

  // ---------- DERIVADOS p/ gráficos/tabela ----------
  List<String> get labels =>
      adjustments.map((m) => (m.orderAdjustmentMeasurement ?? 0).toString()).toList();

  List<double> get values =>
      adjustments.map((m) => m.valueAdjustmentMeasurement ?? 0.0).toList();

  double get totalAdjustments => values.fold(0.0, (a, b) => a + b);

  double get valorTotalDisponivel => totalApostilles + totalAdditives;

  double get saldo => valorTotalDisponivel - totalAdjustments;

  // ---------- FORM ----------
  void _validateForm() {
    final ok = areFieldsFilled(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl],
      minLength: 1,
    );
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

  void createNew() {
    selectedLine = null;
    selectedAdjustment = null;
    currentAdjustmentId = null;

    final last = adjustments
        .map((e) => e.orderAdjustmentMeasurement ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

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
      final novo = ReportMeasurementData(
        contractId: contract.id!,
        idAdjustmentMeasurement: currentAdjustmentId,
        orderAdjustmentMeasurement: int.tryParse(orderCtrl.text),
        numberAdjustmentProcessMeasurement: processCtrl.text,
        valueAdjustmentMeasurement: parseCurrencyToDouble(valueCtrl.text),
        dateAdjustmentMeasurement: convertDDMMYYYYToDateTime(dateCtrl.text),
      );

      await _measurementBloc.saveOrUpdateMeasurement(novo);

      adjustments = await _measurementBloc
          .getAllMeasurementsOfContract(uidContract: contract.id!);
      createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reajuste salvo com sucesso!'),
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

  Future<void> deleteAdjustment(BuildContext context, String id) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      await _measurementBloc.deletarMedicao(contract.id!, id);
      adjustments = await _measurementBloc
          .getAllMeasurementsOfContract(uidContract: contract.id!);

      if (currentAdjustmentId == id) {
        createNew();
      } else {
        selectedLine = null;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reajuste apagado com sucesso.'),
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

  // ---------- Seleção (gráfico/tabela) ----------
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
    if (contract.id == null || selectedAdjustment?.idAdjustmentMeasurement == null) return;
    await _measurementBloc.salvarUrlPdfDaMedicao(
      contractId: contract.id!,
      measurementId: selectedAdjustment!.idAdjustmentMeasurement!,
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
