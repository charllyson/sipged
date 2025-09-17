import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_bloc.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/handle_selection_utils.dart';

// bloc + model de Ajustes
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_bloc.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_storage_bloc.dart';

class AdjustmentMeasurementController extends ChangeNotifier
    with FormValidationMixin {
  AdjustmentMeasurementController({
    required this.contract,
    AdjustmentMeasurementBloc? adjustmentBloc,
    AdjustmentMeasurementStorageBloc? storageBloc,
    AdditivesBloc? additivesBloc,
    ApostillesBloc? apostillesBloc,
  })  : _adjustmentBloc = adjustmentBloc ?? AdjustmentMeasurementBloc(),
        _storageBloc = storageBloc ?? AdjustmentMeasurementStorageBloc(),
        _additivesBloc = additivesBloc ?? AdditivesBloc(),
        _apostillesBloc = apostillesBloc ?? ApostillesBloc() {
    _init();
  }

  // ---- deps / blocs ----
  final AdjustmentMeasurementBloc _adjustmentBloc;
  final AdjustmentMeasurementStorageBloc _storageBloc;
  final AdditivesBloc _additivesBloc;
  final ApostillesBloc _apostillesBloc;

  final ContractData contract;

  // 👇 assinatura do UserBloc
  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

  // ---- estado UI ----
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // ---- dados carregados ----
  List<AdjustmentMeasurementData> adjustments = [];
  double totalApostilles = 0.0;
  double totalAdditives = 0.0;

  // ---- seleção ----
  AdjustmentMeasurementData? selectedAdjustment;
  String? currentAdjustmentId;

  // ---- controllers do form ----
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // ================= INIT =================
  void _init() {
    setupValidation(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl],
      _validateForm,
    );
  }

  Future<void> postFrameInit(BuildContext context) async {
    final userBloc = context.read<UserBloc>();
    _currentUser = userBloc.state.current;
    isEditable = _canEditUser(_currentUser);

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

    await loadInitialData();
  }

  // ---------- permissões ----------
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

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

    totalApostilles = await _apostillesBloc.getAllApostillesValue(contract.id!);
    totalAdditives  = await _additivesBloc.getAllAdditivesValue(contract.id!);

    adjustments = await _adjustmentBloc.getAllAdjustmentsOfContract(uidContract:  contract.id!);

    final last = adjustments
        .map((e) => e.order ?? 0)
        .fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();

    notifyListeners();
  }

  // ---------- DERIVADOS ----------
  List<String> get labels =>
      adjustments.map((m) => (m.order ?? 0).toString()).toList();

  List<double> get values =>
      adjustments.map((m) => m.value ?? 0.0).toList();

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

  void fillFields(AdjustmentMeasurementData data) {
    selectedAdjustment = data;
    currentAdjustmentId = data.id;

    orderCtrl.text   = (data.order ?? '').toString();
    processCtrl.text = data.numberprocess ?? '';
    valueCtrl.text   = priceToString(data.value);
    dateCtrl.text    = dateTimeToDDMMYYYY(data.date);

    _validateForm();
    notifyListeners();
  }

  void createNew() {
    selectedLine = null;
    selectedAdjustment = null;
    currentAdjustmentId = null;

    final last = adjustments
        .map((e) => e.order ?? 0)
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
      final novo = AdjustmentMeasurementData(
        id: currentAdjustmentId,
        order: int.tryParse(orderCtrl.text),
        numberprocess: processCtrl.text,
        value: parseCurrencyToDouble(valueCtrl.text),
        date: convertDDMMYYYYToDateTime(dateCtrl.text),
      );

      await _adjustmentBloc.saveOrUpdateAdjustment(
        measurementId: selectedAdjustment?.id ?? '',
        contractId: contract.id!,
        adj: novo,
      );

      adjustments = await _adjustmentBloc.getAllAdjustmentsOfContract(uidContract:  contract.id!);
      createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reajuste salvo com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
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
      await _adjustmentBloc.deleteAdjustment(contractId: contract.id!, adjustmentId: id);
      adjustments = await _adjustmentBloc.getAllAdjustmentsOfContract(uidContract:  contract.id!);

      if (currentAdjustmentId == id) {
        createNew();
      } else {
        selectedLine = null;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reajuste apagado com sucesso.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao apagar: $e')));
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ---------- Seleção ----------
  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < adjustments.length) {
      handleSelect(adjustments[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(AdjustmentMeasurementData data) {
    handleGenericSelection<AdjustmentMeasurementData>(
      data: data,
      list: adjustments,
      getOrder: (e) => e.order,
      onSetState: (index) {
        selectedLine = index;
        selectedAdjustment = data;
        currentAdjustmentId = data.id;
        fillFields(data);
      },
    );
  }

  // ---------- PDF ----------
  Future<void> uploadPdf({
    required void Function(double progress) onProgress,
  }) async {
    if (contract.id == null || selectedAdjustment?.id == null) return;

    final url = await _storageBloc.uploadWithPicker(
      contract: contract,
      adj: selectedAdjustment!,
      adjustmentId: selectedAdjustment!.id!,
      onProgress: onProgress,
    );

    await _storageBloc.salvarUrlPdfDoAdjustment(
      contractId: contract.id!,
      adjustmentId: selectedAdjustment!.id!,
      url: url,
    );
  }

  Future<void> savePdfUrl(String url) async {
    if (contract.id == null || selectedAdjustment?.id == null) return;
    await _storageBloc.salvarUrlPdfDoAdjustment(
      contractId: contract.id!,
      adjustmentId: selectedAdjustment!.id!,
      url: url,
    );
  }

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
}
