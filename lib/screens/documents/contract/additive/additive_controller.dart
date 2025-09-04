// ==============================
// lib/screens/contracts/additives/additive_controller.dart
// ==============================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/documents/contracts/additives/additive_data.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_utils/handle_selection_utils.dart';

class AdditiveController extends ChangeNotifier with FormValidationMixin {
  // Injetados
  final AdditivesStore store;
  final ContractData contract;
  final AdditivesStorageBloc additivesStorageBloc;

  // User (via UserBloc)
  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

  // State
  late Future<List<AdditiveData>> futureAdditives;
  List<AdditiveData> _lastSnapshotData = [];
  AdditiveData? selectedAdditive;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = false;

  String? currentAdditiveId;
  int? selectedLine;

  // Controllers
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final addDaysExecCtrl = TextEditingController();
  final addDaysContractCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final typeCtrl = TextEditingController();

  AdditiveController({
    required this.contract,
    required this.store,
    AdditivesStorageBloc? storageBloc,
  }) : additivesStorageBloc = storageBloc ?? AdditivesStorageBloc() {
    _init();
  }

  // INIT
  Future<void> _init() async {
    futureAdditives = _getAll();
    _setNextOrder();

    setupValidation(
      [dateCtrl, valueCtrl, addDaysExecCtrl, addDaysContractCtrl, processCtrl, typeCtrl],
      _validateForm,
    );

    // 🔧 Rebuild imediato quando o tipo muda (PRAZO, VALOR, RENOVAÇÃO, etc.)
    typeCtrl.addListener(_onTypeChanged);
  }

  void _onTypeChanged() {
    _validateForm();
    notifyListeners();
  }

  // Pós-frame: depende de BuildContext
  Future<void> postFrameInit(BuildContext context) async {
    final userBloc = context.read<UserBloc>();
    _currentUser = userBloc.state.current;
    isEditable = _canEditUser(_currentUser);
    notifyListeners();

    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
      final newEditable = _canEditUser(st.current);
      if (newEditable != isEditable) {
        isEditable = newEditable;
        _currentUser = st.current;
        notifyListeners();
      }
    });
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    final perms = user.modulePermissions['additives'];
    if (perms != null) {
      return (perms['edit'] == true) || (perms['create'] == true);
    }
    return false;
  }

  // LOADS
  Future<List<AdditiveData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    return store.listFor(contract.id!);
  }

  Future<void> reload() async {
    if (contract.id == null) return;
    await store.refreshFor(contract.id!);
    futureAdditives = Future.value(store.listFor(contract.id!));
    notifyListeners();
  }

  // UI helpers
  bool exibeValor() =>
      ['VALOR', 'REEQUILÍBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeCtrl.text.toUpperCase());

  bool exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeCtrl.text.toUpperCase());

  // VALIDATION
  void _validateForm() {
    final obrig = <TextEditingController>[dateCtrl, processCtrl, typeCtrl];

    final tipo = typeCtrl.text.toUpperCase();
    if (tipo == 'VALOR' || tipo == 'REEQUILÍBRIO') {
      obrig.add(valueCtrl);
    } else if (tipo == 'PRAZO') {
      obrig.addAll([addDaysExecCtrl, addDaysContractCtrl]);
    } else if (tipo == 'RATIFICAÇÃO' || tipo == 'RENOVAÇÃO') {
      obrig.addAll([valueCtrl, addDaysExecCtrl, addDaysContractCtrl]);
    }

    final valid = areFieldsFilled(obrig, minLength: 1);
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // FILL / CLEAR
  void fillFields(AdditiveData data) {
    selectedAdditive = data;
    editingMode = true;
    currentAdditiveId = data.id;

    typeCtrl.text = data.typeOfAdditive ?? '';
    orderCtrl.text = (data.additiveOrder ?? '').toString();
    dateCtrl.text = data.additiveDate != null
        ? convertDateTimeToDDMMYYYY(data.additiveDate!)
        : '';
    valueCtrl.text = data.additiveValue != null ? priceToString(data.additiveValue) : '';
    addDaysExecCtrl.text = data.additiveValidityExecutionDays?.toString() ?? '';
    addDaysContractCtrl.text = data.additiveValidityContractDays?.toString() ?? '';
    processCtrl.text = data.additiveNumberProcess ?? '';

    _validateForm();
    notifyListeners();
  }

  Future<void> _setNextOrder() async {
    if (contract.id == null) return;
    final list = await _getAll();
    final last = list.map((e) => e.additiveOrder ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();
    notifyListeners();
  }

  void createNew() {
    editingMode = false;
    currentAdditiveId = null;
    selectedAdditive = null;

    dateCtrl.clear();
    valueCtrl.clear();
    addDaysExecCtrl.clear();
    addDaysContractCtrl.clear();
    processCtrl.clear();
    typeCtrl.clear();

    _setNextOrder();
    _validateForm();
    notifyListeners();
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');

  // SAVE / UPDATE
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final novo = AdditiveData(
        id: currentAdditiveId,
        additiveNumberProcess: processCtrl.text,
        additiveOrder: int.tryParse(orderCtrl.text),
        additiveDate: convertDDMMYYYYToDateTime(dateCtrl.text),
        additiveValue: stringToDouble(valueCtrl.text),
        additiveValidityContractDays: int.tryParse(_onlyDigits(addDaysContractCtrl.text)),
        additiveValidityExecutionDays: int.tryParse(_onlyDigits(addDaysExecCtrl.text)),
        typeOfAdditive: typeCtrl.text,
      );

      await store.saveOrUpdate(contract.id!, novo);
      await reload();
      createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editingMode ? 'Aditivo atualizado com sucesso!' : 'Aditivo salvo com sucesso!',
            ),
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

  // DELETE
  Future<void> deleteAdditive(BuildContext context, String additiveId) async {
    if (contract.id == null) return;
    await store.delete(contract.id!, additiveId);
    await reload();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aditivo deletado com sucesso!'), backgroundColor: Colors.red),
      );
    }
  }

  // TABLE / GRAPH selection
  void applySnapshot(List<AdditiveData> list) {
    _lastSnapshotData = list; // sem notify
  }

  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < _lastSnapshotData.length) {
      handleAdditiveSelection(_lastSnapshotData[index]);
    } else {
      notifyListeners();
    }
  }

  void handleAdditiveSelection(AdditiveData data) {
    handleGenericSelection<AdditiveData>(
      data: data,
      list: _lastSnapshotData,
      getOrder: (e) => e.additiveOrder,
      onSetState: (index) {
        selectedAdditive = data;
        currentAdditiveId = data.id;
        editingMode = true;
        selectedLine = index;
        fillFields(data);
      },
    );
  }

  // PDF (upload + salvar URL)
  Future<void> uploadValidityPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedAdditive?.id == null) return;
    final url = await additivesStorageBloc.uploadWithPicker(
      contract: contract,
      additive: selectedAdditive!,
      onProgress: onProgress,
    );
    await additivesStorageBloc.salvarUrlPdfDoAditivo(
      contractId: contract.id!,
      additiveId: selectedAdditive!.id!,
      url: url,
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    typeCtrl.removeListener(_onTypeChanged);
    removeValidation(
      [dateCtrl, valueCtrl, addDaysExecCtrl, addDaysContractCtrl, processCtrl, typeCtrl],
      _validateForm,
    );
    orderCtrl.dispose();
    dateCtrl.dispose();
    valueCtrl.dispose();
    addDaysExecCtrl.dispose();
    addDaysContractCtrl.dispose();
    processCtrl.dispose();
    typeCtrl.dispose();
    super.dispose();
  }
}