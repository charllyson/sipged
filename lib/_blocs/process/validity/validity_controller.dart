// ==============================
// lib/_blocs/process/contracts/validity/validity_controller.dart
// ==============================
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/validity/validity_bloc.dart';
import 'package:siged/_blocs/process/validity/validity_data.dart';
import 'package:siged/_blocs/process/validity/validity_storage_bloc.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

// ✅ novo visualizador interno de PDF
import 'package:siged/_services/pdf/pdf_preview.dart';

// ✅ papéis/permissões
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

// ✅ user
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

// ✅ util
import 'package:siged/_utils/formats/date_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// 🔔 Notificações (novo)
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ValidityController extends ChangeNotifier with FormValidationMixin {
  // Blocs Firestore
  final ProcessBloc _contractsBloc = ProcessBloc();
  final AdditivesBloc _additivesBloc = AdditivesBloc();
  final ValidityBloc _validityBloc = ValidityBloc();

  // Store + Storage
  final ValidityStorageBloc validityStorageBloc;
  final ProcessData contract;

  // Futures usados na tela/Timeline
  late Future<List<ValidityData>> futureValidity = Future.value([]);
  late Future<List<AdditiveData>> futureAdditives = Future.value([]);
  late Future<List<ProcessData>> futureContractList = Future.value([]);

  // Snapshot em memória das validades (para dropdown de ordem)
  List<ValidityData> _lastSnapshot = [];

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

  // Tipos válidos para o próximo registro (seu dropdown existente)
  List<String> availableOrders = [];

  // Controllers
  final orderCtrl = TextEditingController();      // número da ordem (agora vem do dropdown inteligente)
  final orderTypeCtrl = TextEditingController();  // tipo da ordem (seu dropdown antigo)
  final orderDateCtrl = TextEditingController();

  // ===== SideListBox (arquivos) - compatível com String ou Attachment =====
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;

  // === helpers selo rico ===
  String _userName() {
    final u = _currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

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
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;

    final canEdit = perms.userCanModule(user: user, module: 'validity', action: 'edit');
    final canCreate = perms.userCanModule(user: user, module: 'validity', action: 'create');
    return canEdit || canCreate;
  }

  // Loads
  Future<void> _loadInitialData(String contractId) async {
    futureValidity = _validityBloc.getAllValidityOfContract(uidContract: contractId);
    futureAdditives = _additivesBloc.getAllAdditivesOfContract(uidContract: contractId);
    futureContractList =
        _contractsBloc.getSpecificContract(uidContract: contractId).then((c) => [c!]);
    notifyListeners();
  }

  Future<void> _loadValidityAndOrders() async {
    if (contract.id == null) return;
    final validities = await _validityBloc.getAllValidityOfContract(
      uidContract: contract.id!,
    );

    // mantém snapshot para o dropdown inteligente
    _lastSnapshot = validities;

    // define próxima ordem disponível (menor buraco -> ou max+1)
    final set = _existingOrders;
    final nextOrder = _nextAvailableOrder(set);

    orderCtrl.text = nextOrder.toString();
    availableOrders = getRulesOrders(validities);
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (contract.id == null) return;
    await _loadInitialData(contract.id!);
    await _loadValidityAndOrders();
  }

  // Regras de sequência das ordens (TIPO)
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

  // =================== ORDEM (dropdown inteligente) ===================

  Set<int> get _existingOrders =>
      _lastSnapshot.map((v) => v.orderNumber ?? 0).where((n) => n > 0).toSet();

  int _nextAvailableOrder(Set<int> set) {
    if (set.isEmpty) return 1;
    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }
    final max = set.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  /// Opções para o dropdown numérico: 1..maxExistente+1
  List<String> get orderNumberOptions {
    final set = _existingOrders;
    final maxPlusOne = set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  /// Itens ocupados (renderizados em cinza)
  Set<String> get greyOrderItems => _existingOrders.map((e) => e.toString()).toSet();

  /// Seleção do dropdown:
  /// - existente → seleciona a validade
  /// - livre → inicia novo com essa ordem
  void onChangeOrderNumber(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    final idx = _lastSnapshot.indexWhere((x) => (x.orderNumber ?? -1) == picked);
    if (idx >= 0) {
      fillFields(_lastSnapshot[idx]);
      return;
    }

    // livre → inicia novo, setando a ordem escolhida
    createNew();
    orderCtrl.text = picked.toString();
    notifyListeners();
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
        // mantém anexos/pdfUrl se estiver atualizando
        pdfUrl: selectedValidityData?.pdfUrl,
        attachments: selectedValidityData?.attachments,
      );

      await _validityBloc.salvarOuAtualizarValidade(newValidity);
      await refreshAll();

      currentValidityId = null;
      selectedValidityData = null;

      // limpa painel lateral
      sideItems = const <dynamic>[];
      selectedSideIndex = null;

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Ordem salva'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao salvar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
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

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Ordem apagada'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao apagar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    }
  }

  void fillFields(ValidityData data) {
    selectedValidityData = data;
    currentValidityId = data.id;

    orderCtrl.text = data.orderNumber?.toString() ?? '';
    orderDateCtrl.text = data.orderdate != null ? dateTimeToDDMMYYYY(data.orderdate!) : '';
    orderTypeCtrl.text = data.ordertype ?? '';

    if (data.ordertype != null && !availableOrders.contains(data.ordertype)) {
      availableOrders.add(data.ordertype!);
    }

    _validateForm();

    // carrega/migra anexos
    _refreshSideList();

    notifyListeners();
  }

  Future<void> createNew() async {
    currentValidityId = null;
    selectedValidityData = null;
    orderTypeCtrl.clear();
    orderDateCtrl.clear();

    // limpa painel
    sideItems = const <dynamic>[];
    selectedSideIndex = null;

    await _loadValidityAndOrders();
    _validateForm();
    notifyListeners();
  }

  void onChangeDate(DateTime? date) {
    selectedValidityData?.orderdate = date;
    notifyListeners();
  }

  // ===== SideListBox (multi-anexos com rótulo) =====

  String _suggestLabelFromName(String original) {
    final base = original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = selectedValidityData?.orderNumber ?? int.tryParse(orderCtrl.text) ?? 0;
    return 'Ordem $ord - $base';
  }

  Future<String?> _askLabel(BuildContext context, {required String suggestion}) async {
    final ctrl = TextEditingController(text: suggestion);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nome do arquivo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Rótulo do arquivo'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
  }

  bool get canAddFile => isEditable && selectedValidityData?.id != null;

  Future<void> _refreshSideList() async {
    final v = selectedValidityData;
    if (v == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 1) já tem attachments -> usa-os
    if ((v.attachments ?? const []).isNotEmpty) {
      sideItems = List<dynamic>.from(v.attachments!);
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 2) migração do pdfUrl legado -> cria attachment único e salva
    if ((v.pdfUrl ?? '').isNotEmpty && v.id != null && contract.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento da validade',
        url: v.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.id,
      );
      await _validityBloc.setAttachments(
        contractId: contract.id!,
        validityId: v.id!,
        attachments: [att],
      );
      selectedValidityData = v..attachments = [att]..pdfUrl = null;
      sideItems = [att];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 3) não há metadado -> materializa arquivos existentes na pasta no Storage
    if (contract.id != null && v.id != null) {
      final files = await validityStorageBloc.listarArquivosDaValidade(
        contractId: contract.id!,
        validityId: v.id!,
      );
      if (files.isNotEmpty) {
        final list = files
            .map((f) => Attachment(
          id: f.name,
          label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          url: f.url,
          path: 'contracts/${contract.id}/orders/${v.id}/${f.name}',
          ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(f.name)?.group(0) ?? '',
          createdAt: DateTime.now(),
          createdBy: _currentUser?.id,
        ))
            .toList();
        await _validityBloc.setAttachments(
          contractId: contract.id!,
          validityId: v.id!,
          attachments: list,
        );
        selectedValidityData = v..attachments = list;
        sideItems = List<dynamic>.from(list);
        selectedSideIndex = null;
        notifyListeners();
        return;
      }
    }

    sideItems = const <dynamic>[];
    selectedSideIndex = null;
    notifyListeners();
  }

  Future<void> addFile(BuildContext context) async {
    final v = selectedValidityData;
    if (contract.id == null || v?.id == null || v == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final (Uint8List bytes, String originalName) = await validityStorageBloc.pickFileBytes();

      final suggestion = _suggestLabelFromName(originalName);
      final label = await _askLabel(context, suggestion: suggestion);
      if (label == null) {
        isSaving = false;
        notifyListeners();
        return;
      }

      final att = await validityStorageBloc.uploadAttachmentBytes(
        contract: contract,
        validity: v,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current = List<Attachment>.from(v.attachments ?? const []);
      current.add(att);

      await _validityBloc.setAttachments(
        contractId: contract.id!,
        validityId: v.id!,
        attachments: current,
      );

      selectedValidityData = v..attachments = current;
      await _refreshSideList();

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Adicionado "${att.label}"'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Falha ao adicionar arquivo: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> editLabelFile(int index, BuildContext context) async {
    final v = selectedValidityData;
    if (v == null || v.attachments == null || index < 0 || index >= v.attachments!.length) return;

    try {
      isSaving = true;
      notifyListeners();

      final att = v.attachments![index];
      final suggestion = att.label.isNotEmpty ? att.label : _suggestLabelFromName(att.id);
      final newLabel = await _askLabel(context, suggestion: suggestion);
      if (newLabel == null) {
        isSaving = false;
        notifyListeners();
        return;
      }

      v.attachments![index] = Attachment(
        id: att.id,
        label: newLabel.isEmpty ? suggestion : newLabel,
        url: att.url,
        path: att.path,
        ext: att.ext,
        size: att.size,
        createdAt: att.createdAt,
        createdBy: att.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentUser?.id,
      );

      await _validityBloc.setAttachments(
        contractId: contract.id!,
        validityId: v.id!,
        attachments: v.attachments!,
      );

      await _refreshSideList();

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Nome do anexo atualizado'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao renomear'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteFileAt(int index, BuildContext context) async {
    final v = selectedValidityData;
    if (v == null || v.id == null || contract.id == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final atts = v.attachments ?? [];
      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await validityStorageBloc.deleteStorageByPath(removed.path);
        }
        await _validityBloc.setAttachments(
          contractId: contract.id!,
          validityId: v.id!,
          attachments: atts,
        );
        selectedValidityData = v..attachments = atts;
      } else if ((v.pdfUrl ?? '').isNotEmpty) {
        await validityStorageBloc.salvarUrlPdfDaValidade(
          contractId: contract.id!,
          validadeId: v.id!,
          url: '',
        );
        selectedValidityData = v..pdfUrl = null;
      }

      await _refreshSideList();

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo removido'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao remover anexo'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // 🔥 Abre PDF em modal interno com PdfPreview
  Future<void> openFileAt(BuildContext context, int i) async {
    final v = selectedValidityData;
    if (v == null) return;

    String? url;
    if ((v.attachments ?? []).isNotEmpty) {
      if (i < 0 || i >= v.attachments!.length) return;
      url = v.attachments![i].url;
    } else {
      url = v.pdfUrl; // legado
    }

    if (url == null || url.isEmpty) return;

    selectedSideIndex = i;
    notifyListeners();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url!),
      ),
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
