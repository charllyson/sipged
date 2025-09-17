import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_bloc.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_data.dart';

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

  // ==== User (via UserBloc) ====
  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

  // Dados selecionados
  String? currentValidityId;
  ValidityData? selectedValidityData;
  List<String> availableOrders = [];

  // Controllers
  final orderCtrl = TextEditingController();
  final orderTypeCtrl = TextEditingController();
  final orderDateCtrl = TextEditingController();

  // ===== SideListBox (arquivos) =====
  /// nomes para UI
  final List<String> fileNames = [];
  /// URLs reais (mesmo índice)
  final List<String> fileUrls = [];
  int? selectedFileIndex;

  ValidityController({
    required this.contract,
    ValidityStorageBloc? storageBloc,
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
    final userBloc = context.read<UserBloc>();
    _currentUser = userBloc.state.current;
    isEditable = _canEditUser(_currentUser);
    notifyListeners();

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
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;
    final perms = user.modulePermissions['validity'];
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

    orderCtrl.text = nextOrder.toString();
    availableOrders = getRulesOrders(validities);
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

      // limpa arquivos do painel
      fileNames.clear();
      fileUrls.clear();
      selectedFileIndex = null;

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
    data.orderdate != null ? dateTimeToDDMMYYYY(data.orderdate!) : '';
    orderTypeCtrl.text = data.ordertype ?? '';

    if (data.ordertype != null && !availableOrders.contains(data.ordertype)) {
      availableOrders.add(data.ordertype!);
    }

    _validateForm();

    // 👉 carrega arquivos do item selecionado
    _loadFilesForCurrentValidity();

    notifyListeners();
  }

  Future<void> createNew() async {
    currentValidityId = null;
    selectedValidityData = null;
    orderTypeCtrl.clear();
    orderDateCtrl.clear();

    // limpa painel de arquivos
    fileNames.clear();
    fileUrls.clear();
    selectedFileIndex = null;

    await _loadValidityAndOrders();
    _validateForm();
    notifyListeners();
  }

  // Handlers do form
  void onChangeDate(DateTime? date) {
    selectedValidityData?.orderdate = date;
    notifyListeners();
  }

  // ====== SideListBox: arquivos ======
  Future<void> _loadFilesForCurrentValidity() async {
    fileNames.clear();
    fileUrls.clear();
    selectedFileIndex = null;

    final a = selectedValidityData;
    final c = contract;
    if (a == null || a.id == null || c.id == null) {
      notifyListeners();
      return;
    }

    try {
      // 1) tenta ler um metadado de compatibilidade 'pdfUrl' no documento
      final legacyUrl = a.pdfUrl;
      if (legacyUrl != null && legacyUrl.isNotEmpty) {
        fileNames.add(_extractFileName(legacyUrl));
        fileUrls.add(legacyUrl);
      } else {
        // 2) tenta descobrir a URL pelo caminho padrão do Storage
        final url = await validityStorageBloc.getUrl(c, a);
        if (url != null && url.isNotEmpty) {
          fileNames.add(_extractFileName(url));
          fileUrls.add(url);
        }
      }
    } catch (_) {
      // silencioso — lista fica vazia
    }
    notifyListeners();
  }

  Future<void> addFile(BuildContext context) async {
    if (contract.id == null || selectedValidityData?.id == null) return;

    try {
      String? lastMsg;
      final url = await validityStorageBloc.uploadWithPicker(
        contract: contract,
        validade: selectedValidityData!,
        onProgress: (p) {
          final msg = 'Enviando arquivo ${(p * 100).toStringAsFixed(0)}%';
          if (msg != lastMsg && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), duration: const Duration(milliseconds: 700)),
            );
            lastMsg = msg;
          }
        },
      );

      await validityStorageBloc.salvarUrlPdfDaValidade(
        contractId: contract.id!,
        validadeId: selectedValidityData!.id!,
        url: url,
      );

      fileNames.add(_extractFileName(url));
      fileUrls.add(url);
      selectedFileIndex = fileNames.length - 1;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo adicionado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao adicionar arquivo: $e')),
        );
      }
    }
  }

  void openFileAt(int i, BuildContext context) async {
    if (i < 0 || i >= fileUrls.length) return;
    selectedFileIndex = i;
    notifyListeners();
    final url = fileUrls[i];
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> removeFileAt(int i, BuildContext context) async {
    if (i < 0 || i >= fileUrls.length) return;

    // Opcional: tentar deletar no storage se tiver caminho mapeável
    // Aqui removemos apenas da UI para manter compatibilidade
    fileNames.removeAt(i);
    fileUrls.removeAt(i);
    if (selectedFileIndex != null) {
      if (fileNames.isEmpty) {
        selectedFileIndex = null;
      } else if (selectedFileIndex! >= fileNames.length) {
        selectedFileIndex = fileNames.length - 1;
      }
    }
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo removido.'), backgroundColor: Colors.red),
      );
    }
  }

  String _extractFileName(String urlOrPath) {
    final idx = urlOrPath.lastIndexOf('/');
    if (idx >= 0 && idx < urlOrPath.length - 1) {
      return urlOrPath.substring(idx + 1);
    }
    return urlOrPath;
  }

  // Upload + metadado (atalho legado)
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
    _userSub?.cancel();
    removeValidation([orderTypeCtrl, orderDateCtrl], _validateForm);
    orderCtrl.dispose();
    orderTypeCtrl.dispose();
    orderDateCtrl.dispose();
    super.dispose();
  }
}
