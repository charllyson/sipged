// lib/_controllers/documents/contracts/validity/validity_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:sisged/_datas/documents/contracts/additive/additive_data.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_datas/documents/contracts/validity/validity_data.dart';
import 'package:sisged/_datas/system/user_data.dart';

class ValidityController extends ChangeNotifier with FormValidationMixin {
  // Blocs Firestore
  final ContractBloc _contractsBloc = ContractBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final ValidityBloc _validityBloc = ValidityBloc();

  // Storage
  final ValidityStorageBloc validityStorageBloc;

  final ContractData contract;

  // Futures usados na tela/Timeline
  late Future<List<ValidityData>> futureValidity = Future.value([]);
  late Future<List<AdditiveData>> futureAdditives = Future.value([]);
  late Future<List<ContractData>> futureContractList = Future.value([]);

  // Estado UI
  bool isSaving = false;
  bool formValidated = false;
  bool isEditable = false;

  // Dados selecionados
  String? currentValidityId;
  ValidityData? selectedValidityData;
  List<String> availableOrders = [];

  // Controllers
  final orderCtrl = TextEditingController();
  final orderTypeCtrl = TextEditingController();
  final orderDateCtrl = TextEditingController();

  ValidityController({
    required this.contract,
    ValidityStorageBloc? storageBloc, // injetável
  }) : validityStorageBloc = storageBloc ?? ValidityStorageBloc() {
    _init();
  }

  Future<void> _init() async {
    if (contract.id != null) {
      await _loadInitialData(contract.id!);
      await _loadValidityAndOrders();
    } else {
      orderCtrl.text = '1';
    }
    setupValidation([orderTypeCtrl, orderDateCtrl], _validateForm);
  }

  Future<void> postFrameInit(BuildContext context) async {
    final user = context.read<UserProvider>().userData;
    isEditable = _canEditUser(user);
    notifyListeners();
  }

  // ---- permissões (ajuste o nome do módulo se usar outro) ----
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    // Permissão granular por módulo (opcional)
    final perms = user.modulePermissions['validity']; // ex.: módulo "validity"
    if (perms != null) {
      return (perms['edit'] == true) || (perms['create'] == true);
    }
    return false;
  }

  // Loads
  Future<void> _loadInitialData(String contractId) async {
    futureValidity =
        _validityBloc.getAllValidityOfContract(uidContract: contractId);
    futureAdditives =
        _additivesBloc.getAllAdditivesOfContract(uidContract: contractId);
    futureContractList = _contractsBloc
        .getSpecificContract(uidContract: contractId)
        .then((c) => [c!]);
    notifyListeners();
  }

  Future<void> _loadValidityAndOrders() async {
    if (contract.id == null) return;
    final validities = await _validityBloc.getAllValidityOfContract(
      uidContract: contract.id!,
    );

    final existingOrders = validities
        .map((v) => int.tryParse(v.orderNumber?.toString() ?? ''))
        .whereType<int>()
        .toList();

    final nextOrder =
    existingOrders.isEmpty ? 1 : (existingOrders.reduce((a, b) => a > b ? a : b) + 1);

    final newOrdersAvailable = getRulesOrders(validities);

    orderCtrl.text = nextOrder.toString();
    availableOrders = newOrdersAvailable;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (contract.id == null) return;
    await _loadInitialData(contract.id!);
    await _loadValidityAndOrders();
  }

  // Regras de sequência das ordens
  List<String> getRulesOrders(List<ValidityData> validities) {
    final List<String> newOrders = [];
    final String? lastOrder = validities.isEmpty ? null : validities.last.ordertype;

    if (lastOrder == null) {
      newOrders.addAll(ValidityData.typeOfOrder);
    } else if (lastOrder == 'ORDEM DE INÍCIO') {
      newOrders.addAll(['ORDEM DE PARALISAÇÃO', 'ORDEM DE FINALIZAÇÃO']);
    } else if (lastOrder == 'ORDEM DE PARALISAÇÃO') {
      newOrders.add('ORDEM DE REINÍCIO');
    } else if (lastOrder == 'ORDEM DE REINÍCIO') {
      newOrders.addAll(['ORDEM DE PARALISAÇÃO', 'ORDEM DE FINALIZAÇÃO']);
    } else if (lastOrder != 'ORDEM DE FINALIZAÇÃO') {
      newOrders.addAll(ValidityData.typeOfOrder);
    }
    return newOrders;
  }

  // Form
  void _validateForm() {
    final valid = areFieldsFilled([orderTypeCtrl, orderDateCtrl], minLength: 1);
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // CRUD
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final newValidity = ValidityData(
        id: currentValidityId,
        uidContract: contract.id,
        orderNumber: int.tryParse(orderCtrl.text),
        ordertype: orderTypeCtrl.text,
        orderdate: convertDDMMYYYYToDateTime(orderDateCtrl.text),
      );

      await _validityBloc.salvarOuAtualizarValidade(newValidity);
      await refreshAll();

      currentValidityId = null;
      selectedValidityData = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordem salva com sucesso!'),
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

  Future<void> deleteValidity(BuildContext context, String validityId) async {
    if (contract.id == null) return;

    try {
      await _validityBloc.deletarValidade(contract.id!, validityId);
      await refreshAll();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordem apagada com sucesso!'),
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
    }
  }

  void fillFields(ValidityData data) {
    selectedValidityData = data;
    currentValidityId = data.id;

    orderCtrl.text = data.orderNumber?.toString() ?? '';
    orderDateCtrl.text =
    data.orderdate != null ? convertDateTimeToDDMMYYYY(data.orderdate!) : '';
    orderTypeCtrl.text = data.ordertype ?? '';

    if (data.ordertype != null && !availableOrders.contains(data.ordertype)) {
      availableOrders.add(data.ordertype!);
    }
    _validateForm();
    notifyListeners();
  }

  Future<void> createNew() async {
    currentValidityId = null;
    selectedValidityData = null;
    orderTypeCtrl.clear();
    orderDateCtrl.clear();
    await _loadValidityAndOrders();
    _validateForm();
    notifyListeners();
  }

  // Handlers auxiliares para o form
  void onChangeDate(DateTime? date) {
    selectedValidityData?.orderdate = date;
    notifyListeners();
  }

  // Upload + metadado (Storage)
  Future<void> uploadPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedValidityData?.id == null) return;
    final url = await validityStorageBloc.uploadWithPicker(
      contract: contract,
      validade: selectedValidityData!,
      onProgress: onProgress,
    );
    await validityStorageBloc.salvarUrlPdfDaValidade(
      contractId: contract.id!,
      validadeId: selectedValidityData!.id!,
      url: url,
    );
  }

  @override
  void dispose() {
    removeValidation([orderTypeCtrl, orderDateCtrl], _validateForm);
    orderCtrl.dispose();
    orderTypeCtrl.dispose();
    orderDateCtrl.dispose();
    super.dispose();
  }
}
