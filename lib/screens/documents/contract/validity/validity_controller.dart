// lib/_controllers/documents/contracts/validity/validity_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';

import '../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../_blocs/documents/contracts/contracts/contract_bloc.dart';
import '../../../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../../../_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import '../../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_datas/documents/contracts/validity/validity_data.dart';

class ValidityController extends ChangeNotifier with FormValidationMixin {
  // Blocs Firestore
  final ContractBloc _contractsBloc = ContractBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final ValidityBloc _validityBloc = ValidityBloc();

  // Storage (‼️ novo)
  final ValidityStorageBloc validityStorageBloc;

  // Permissões
  final UserBloc _userBloc = UserBloc();

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
    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user != null) {
      isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
      notifyListeners();
    }
  }

  // Loads
  Future<void> _loadInitialData(String contractId) async {
    futureValidity = _validityBloc.getAllValidityOfContract(uidContract: contractId);
    futureAdditives = _additivesBloc.getAllAdditivesOfContract(uidContract: contractId);
    futureContractList = _contractsBloc.getSpecificContract(uidContract: contractId).then((c) => [c!]);
    notifyListeners();
  }

  Future<void> _loadValidityAndOrders() async {
    if (contract.id == null) return;
    final validities = await _validityBloc.getAllValidityOfContract(uidContract: contract.id!);
    final existingOrders = validities
        .map((v) => int.tryParse(v.orderNumber?.toString() ?? ''))
        .whereType<int>()
        .toList();

    final nextOrder = existingOrders.isEmpty
        ? 1
        : (existingOrders.reduce((a, b) => a > b ? a : b) + 1);

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
    isSaving = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem salva com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> deleteValidity(BuildContext context, String validityId) async {
    if (contract.id == null) return;
    await _validityBloc.deletarValidade(contract.id!, validityId);
    await refreshAll();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem apagada com sucesso!'), backgroundColor: Colors.red),
      );
    }
  }

  void fillFields(ValidityData data) {
    selectedValidityData = data;
    currentValidityId = data.id;

    orderCtrl.text = data.orderNumber?.toString() ?? '';
    orderDateCtrl.text = data.orderdate != null
        ? convertDateTimeToDDMMYYYY(data.orderdate!)
        : '';
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


  // ------- (Opcional) helper de upload + metadado usando o storage bloc -------
  Future<void> uploadPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedValidityData?.id == null) return;
    final c = contract;
    final v = selectedValidityData!;
    final url = await validityStorageBloc.uploadWithPicker(
      contract: c,
      validade: v,
      onProgress: onProgress,
    );
    await validityStorageBloc.salvarUrlPdfDaValidade(
      contractId: c.id!,
      validadeId: v.id!,
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
