// lib/_controllers/documents/contracts/additives/additive_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';

import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';

import '../../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../../_datas/documents/contracts/additive/additive_store.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_utils/handle_selection_utils.dart';

class AdditiveController extends ChangeNotifier with FormValidationMixin {
  // ✅ Injetados
  final AdditivesStore store;
  final UserBloc userBloc;

  // Acesso ao bloc Firestore (se necessário em pontos específicos)
  // Prefira usar os métodos do Store (saveOrUpdate/delete etc.)
  final ContractData contract;

  final AdditivesStorageBloc additivesStorageBloc;


  // --- State
  late Future<List<AdditiveData>> futureAdditives;
  List<AdditiveData> _lastSnapshotData = [];
  AdditiveData? selectedAdditive;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = false;

  String? currentAdditiveId;
  int? selectedLine;

  // --- Controllers
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
    required this.userBloc,
    AdditivesStorageBloc? storageBloc, // injetável
  }) : additivesStorageBloc = storageBloc ?? AdditivesStorageBloc() {
    _init();
  }

  // --------- INIT ---------
  Future<void> _init() async {
    futureAdditives = _getAll();
    _setNextOrder();
    setupValidation(
      [
        dateCtrl,
        valueCtrl,
        addDaysExecCtrl,
        addDaysContractCtrl,
        processCtrl,
        typeCtrl,
      ],
      _validateForm,
    );
  }

  // Chamar após inserir no widget tree (tem BuildContext)
  Future<void> postFrameInit(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user != null) {
      isEditable = userBloc.getUserCreateEditPermissions(userData: user);
      notifyListeners();
    }
  }

  // --------- LOADS ---------
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

  // --------- UI HELPERS ---------
  bool exibeValor() =>
      ['VALOR', 'REEQUILÍBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeCtrl.text.toUpperCase());

  bool exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeCtrl.text.toUpperCase());

  // --------- VALIDATION ---------
  void _validateForm() {
    final obrig = <TextEditingController>[
      dateCtrl,
      processCtrl,
      typeCtrl,
    ];

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

  // --------- FILL / CLEAR ---------
  void fillFields(AdditiveData data) {
    selectedAdditive = data;
    editingMode = true;
    currentAdditiveId = data.id;

    typeCtrl.text = data.typeOfAdditive ?? '';
    orderCtrl.text = (data.additiveOrder ?? '').toString();
    dateCtrl.text = data.additiveDate != null ? convertDateTimeToDDMMYYYY(data.additiveDate!) : '';
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

  // --------- SAVE / UPDATE (Firestore via Store) ---------
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

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

    isSaving = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editingMode ? 'Aditivo atualizado com sucesso!' : 'Aditivo salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --------- DELETE (Firestore via Store) ---------
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

  // --------- TABLE / GRAPH SELECTION ---------
  void applySnapshot(List<AdditiveData> list) {
    _lastSnapshotData = list; // sem notify (evita rebuilds durante build)
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

  // --------- PDF (metadado via Store; upload via Store se desejar) ---------
  Future<void> uploadValidityPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedAdditive?.id == null) return;
    final c = contract;
    final v = selectedAdditive!;
    final url = await additivesStorageBloc.uploadWithPicker(
      contract: c,
      additive: v,
      onProgress: onProgress,
    );
    await additivesStorageBloc.salvarUrlPdfDoAditivo(
      contractId: c.id!,
      additiveId: v.id!,
      url: url,
    );
  }

  // Exemplo de uso de upload (chame da UI quando quiser):
  // await store.uploadPdfWithProgress(
  //   contract: contract,
  //   additive: selectedAdditive!,
  //   onProgress: (p) { /* setState progress */ },
  // );

  // --------- DISPOSE ---------
  @override
  void dispose() {
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
