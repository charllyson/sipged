import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_datas/system/user_data.dart';

import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';

import 'package:sisged/_datas/documents/contracts/apostilles/apostilles_store.dart';
import 'package:sisged/_datas/documents/contracts/apostilles/apostilles_data.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_utils/handle_selection_utils.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';

class ApostillesController extends ChangeNotifier with FormValidationMixin {
  final ApostillesStore store;
  final ContractData contract;

  final ApostillesStorageBloc apostillesStorageBloc;

  // Estado
  late Future<List<ApostillesData>> futureApostilles;
  List<ApostillesData> _lastSnapshot = [];
  ApostillesData? selectedApostille;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = false;

  String? currentApostilleId;
  int? selectedLine;

  // Controllers
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final processCtrl = TextEditingController();

  ApostillesController({
    required this.store,
    required this.contract,
    ApostillesStorageBloc? storageBloc, // injetável
  }) : apostillesStorageBloc = storageBloc ?? ApostillesStorageBloc() {
    _init();
  }

  void _init() {
    futureApostilles = _getAll();
    _setNextOrder();
    setupValidation([dateCtrl, valueCtrl, processCtrl], _validateForm);
  }

  Future<void> postFrameInit(BuildContext context) async {
    final user = context.read<UserProvider>().userData;
    isEditable = _canEditUser(user);
    notifyListeners();
  }

  // Permissões (ajuste a chave do módulo se necessário)
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    final perms = user.modulePermissions['apostilles']; // <— nome do módulo
    if (perms != null) {
      return (perms['edit'] == true) || (perms['create'] == true);
    }
    return false;
  }

  // Loads
  Future<List<ApostillesData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    return store.listFor(contract.id!);
  }

  Future<void> reload() async {
    if (contract.id == null) return;
    await store.refreshFor(contract.id!);
    futureApostilles = Future.value(store.listFor(contract.id!));
    notifyListeners();
  }

  // Validation
  void _validateForm() {
    final valid = dateCtrl.text.isNotEmpty &&
        valueCtrl.text.isNotEmpty &&
        processCtrl.text.isNotEmpty;

    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // Fill / Clear
  Future<void> _setNextOrder() async {
    if (contract.id == null) return;
    await store.ensureFor(contract.id!);
    final list = store.listFor(contract.id!);
    final last = list.map((e) => e.apostilleOrder ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();
    notifyListeners();
  }

  void fillFields(ApostillesData data) {
    selectedApostille = data;
    editingMode = true;
    currentApostilleId = data.id;

    orderCtrl.text = (data.apostilleOrder ?? '').toString();
    dateCtrl.text = data.apostilleData != null
        ? convertDateTimeToDDMMYYYY(data.apostilleData!)
        : '';
    valueCtrl.text = priceToString(data.apostilleValue);
    processCtrl.text = data.apostilleNumberProcess ?? '';

    _validateForm();
    notifyListeners();
  }

  void createNew() {
    editingMode = false;
    currentApostilleId = null;
    selectedApostille = null;

    dateCtrl.clear();
    valueCtrl.clear();
    processCtrl.clear();

    _setNextOrder();
    _validateForm();
    notifyListeners();
  }

  // Save / Update
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final novo = ApostillesData(
        id: currentApostilleId,
        apostilleOrder: int.tryParse(orderCtrl.text),
        apostilleData: convertDDMMYYYYToDateTime(dateCtrl.text),
        apostilleValue: stringToDouble(valueCtrl.text),
        apostilleNumberProcess: processCtrl.text,
      );

      await store.saveOrUpdate(contract.id!, novo);
      futureApostilles = Future.value(store.listFor(contract.id!));
      createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editingMode
                  ? 'Apostilamento atualizado com sucesso!'
                  : 'Apostilamento salvo com sucesso!',
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

  // Delete
  Future<void> deleteApostille(BuildContext context, String id) async {
    if (contract.id == null) return;
    await store.delete(contract.id!, id);
    await reload();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apostilamento removido com sucesso!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Graph/Table selection
  void applySnapshot(List<ApostillesData> list) => _lastSnapshot = list;

  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < _lastSnapshot.length) {
      handleApostilleSelection(_lastSnapshot[index]);
    } else {
      notifyListeners();
    }
  }

  void handleApostilleSelection(ApostillesData data) {
    handleGenericSelection<ApostillesData>(
      data: data,
      list: _lastSnapshot,
      getOrder: (e) => e.apostilleOrder,
      onSetState: (index) {
        selectedApostille = data;
        currentApostilleId = data.id;
        editingMode = true;
        selectedLine = index;
        fillFields(data);
      },
    );
  }

  // Upload + metadado (Storage)
  Future<void> uploadPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedApostille?.id == null) return;
    final url = await apostillesStorageBloc.uploadWithPicker(
      contract: contract,
      apostille: selectedApostille!,
      onProgress: onProgress,
    );
    await apostillesStorageBloc.salvarUrlPdfDaApostila(
      contractId: contract.id!,
      apostilleId: selectedApostille!.id!,
      url: url,
    );
  }

  @override
  void dispose() {
    removeValidation([dateCtrl, valueCtrl, processCtrl], _validateForm);
    orderCtrl.dispose();
    dateCtrl.dispose();
    valueCtrl.dispose();
    processCtrl.dispose();
    super.dispose();
  }
}
