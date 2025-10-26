// lib/_blocs/process/contracts/additives/additive_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ✅ usa o módulo novo de PhysFin (apenas o modelo para tipar retorno do helper)
import 'package:siged/_blocs/process/phys_fin/physics_finance_data.dart';

// anexos
import 'package:siged/_widgets/list/files/attachment.dart';

// usuário/permissões
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

// storage + dados do aditivo
import 'package:siged/_blocs/process/additives/additives_storage_bloc.dart';
import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';

// ✅ NOVO: store dedicado do cronograma físico-financeiro
import 'package:siged/_blocs/process/phys_fin/physics_finance_store.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/handle_selection_utils.dart';

// viewer interno PDF
import 'package:siged/_services/pdf/pdf_preview.dart';

// notificações
import 'package:intl/intl.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class AdditiveController extends ChangeNotifier with FormValidationMixin {
  final AdditivesStore store;
  final ContractData contract;
  final AdditivesStorageBloc additivesStorageBloc;

  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

  late Future<List<AdditiveData>> futureAdditives;
  List<AdditiveData> _lastSnapshotData = [];
  AdditiveData? selectedAdditive;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = false;

  String? currentAdditiveId;
  int? selectedLine;

  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final addDaysExecCtrl = TextEditingController();
  final addDaysContractCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final typeCtrl = TextEditingController();

  // SideListBox
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;

  bool get canAddFile => isEditable && selectedAdditive?.id != null;

  AdditiveController({
    required this.contract,
    required this.store,
    AdditivesStorageBloc? storageBloc,
  }) : additivesStorageBloc = storageBloc ?? AdditivesStorageBloc() {
    _init();
  }

  // === helpers para rótulo rico ===
  String _userName() {
    final u = _currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  Future<void> _init() async {
    futureAdditives = _getAll();
    _setNextOrder();

    setupValidation(
      [dateCtrl, valueCtrl, addDaysExecCtrl, addDaysContractCtrl, processCtrl, typeCtrl],
      _validateForm,
    );

    typeCtrl.addListener(_onTypeChanged);
  }

  void _onTypeChanged() {
    _validateForm();
    notifyListeners();
  }

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
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;
    final canEdit   = perms.userCanModule(user: user, module: 'additives', action: 'edit');
    final canCreate = perms.userCanModule(user: user, module: 'additives', action: 'create');
    return canEdit || canCreate;
  }

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

  bool exibeValor() =>
      ['VALOR', 'REEQUILÍBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeCtrl.text.toUpperCase());

  bool exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeCtrl.text.toUpperCase());

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

  void applySnapshot(List<AdditiveData> list) {
    _lastSnapshotData = list;
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

  void fillFields(AdditiveData data) {
    selectedAdditive = data;
    editingMode = true;
    currentAdditiveId = data.id;

    typeCtrl.text = data.typeOfAdditive ?? '';
    orderCtrl.text = (data.additiveOrder ?? '').toString();
    dateCtrl.text = data.additiveDate != null ? dateTimeToDDMMYYYY(data.additiveDate!) : '';
    valueCtrl.text = data.additiveValue != null ? priceToString(data.additiveValue) : '';
    addDaysExecCtrl.text = data.additiveValidityExecutionDays?.toString() ?? '';
    addDaysContractCtrl.text = data.additiveValidityContractDays?.toString() ?? '';
    processCtrl.text = data.additiveNumberProcess ?? '';

    _validateForm();
    _refreshSideList();
    notifyListeners();
  }

  // =================== NOVO: lógica do DROPDOWN de ordem ===================
  Set<int> get _existingOrders {
    final base = _lastSnapshotData.isNotEmpty
        ? _lastSnapshotData
        : (contract.id == null ? const <AdditiveData>[] : store.listFor(contract.id!));
    return base.map((e) => e.additiveOrder ?? 0).where((e) => e > 0).toSet();
  }

  int get _nextAvailableOrder {
    final set = _existingOrders;
    if (set.isEmpty) return 1;
    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }
    final max = set.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  List<String> get orderOptions {
    final set = _existingOrders;
    final maxPlusOne = set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  Set<String> get greyOrderItems => _existingOrders.map((e) => e.toString()).toSet();

  void onChangeOrderDropdown(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    // se existe -> seleciona
    final list = _lastSnapshotData.isNotEmpty
        ? _lastSnapshotData
        : (contract.id == null ? const <AdditiveData>[] : store.listFor(contract.id!));

    final idx = list.indexWhere((m) => (m.additiveOrder ?? -1) == picked);
    if (idx >= 0) {
      handleAdditiveSelection(list[idx]);
      return;
    }

    // não existe -> inicia novo com a ordem escolhida
    createNew();
    orderCtrl.text = picked.toString();
    notifyListeners();
  }
  // ========================================================================

  Future<void> _setNextOrder() async {
    // passa a usar o próximo disponível (não apenas max+1)
    orderCtrl.text = _nextAvailableOrder.toString();
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

    sideItems = const <dynamic>[];
    selectedSideIndex = null;

    _setNextOrder();
    _validateForm();
    notifyListeners();
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');

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
        pdfUrl: selectedAdditive?.pdfUrl,
        attachments: selectedAdditive?.attachments,
      );

      await store.saveOrUpdate(contract.id!, novo);
      await reload();
      createNew();

      NotificationCenter.instance.show(
        AppNotification(
          title: Text(editingMode ? 'Aditivo atualizado' : 'Aditivo salvo'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
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

  Future<void> deleteAdditive(BuildContext context, String additiveId) async {
    if (contract.id == null) return;

    try {
      await store.delete(contract.id!, additiveId);
      await reload();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Aditivo deletado'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao deletar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    }
  }

  // ===== SideListBox com rótulos =====
  Future<void> _refreshSideList() async {
    final a = selectedAdditive;
    if (a == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 1) já tem attachments no doc
    if ((a.attachments ?? const []).isNotEmpty) {
      sideItems = List<dynamic>.from(a.attachments!);
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 2) migração do pdfUrl legado
    if ((a.pdfUrl ?? '').isNotEmpty && a.id != null && contract.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento do aditivo',
        url: a.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.id,
      );
      await store.bloc.setAttachments(
        contractId: contract.id!,
        additiveId: a.id!,
        attachments: [att],
      );
      selectedAdditive = a..attachments = [att]..pdfUrl = null;
      sideItems = [att];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 3) materializa arquivos do Storage
    if (contract.id != null && a.id != null) {
      final files = await additivesStorageBloc.listarArquivosDoAditivo(
        contractId: contract.id!,
        additiveId: a.id!,
      );
      if (files.isNotEmpty) {
        final list = files
            .map((f) => Attachment(
          id: f.name,
          label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          url: f.url,
          path: 'contracts/${contract.id}/additives/${a.id}/${f.name}',
          ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
              .firstMatch(f.name)
              ?.group(0) ??
              '',
          createdAt: DateTime.now(),
          createdBy: _currentUser?.id,
        ))
            .toList();
        await store.bloc.setAttachments(
          contractId: contract.id!,
          additiveId: a.id!,
          attachments: list,
        );
        selectedAdditive = a..attachments = list;
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

  void _selectSideIndex(int i) {
    selectedSideIndex = i;
    notifyListeners();
  }

  String _suggestLabelFromName(String original) {
    final base = original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = selectedAdditive?.additiveOrder ?? 0;
    return 'Aditivo $ord - $base';
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

  Future<void> handleAddFile(BuildContext context) async {
    final cId = contract.id;
    final aId = selectedAdditive?.id;
    final a = selectedAdditive;
    if (cId == null || aId == null || a == null) return;

    try {
      isSaving = true; notifyListeners();

      final (Uint8List bytes, String originalName) = await additivesStorageBloc.pickFileBytes();

      final suggestion = _suggestLabelFromName(originalName);
      final label = await _askLabel(context, suggestion: suggestion);
      if (label == null) { isSaving = false; notifyListeners(); return; }

      final att = await additivesStorageBloc.uploadAttachmentBytes(
        contract: contract,
        additive: a,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current = List<Attachment>.from(a.attachments ?? const []);
      current.add(att);

      await store.bloc.setAttachments(
        contractId: cId,
        additiveId: aId,
        attachments: current,
      );

      selectedAdditive = a..attachments = current;
      await _refreshSideList();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo adicionado'),
          subtitle: Text(att.label),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao anexar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleEditLabelFile(int index, BuildContext context) async {
    final a = selectedAdditive;
    if (a == null || a.attachments == null || index < 0 || index >= a.attachments!.length) return;

    try {
      isSaving = true; notifyListeners();

      final att = a.attachments![index];
      final suggestion = att.label.isNotEmpty ? att.label : _suggestLabelFromName(att.id);
      final newLabel = await _askLabel(context, suggestion: suggestion);
      if (newLabel == null) { isSaving = false; notifyListeners(); return; }

      a.attachments![index] = Attachment(
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

      await store.bloc.setAttachments(
        contractId: contract.id!,
        additiveId: a.id!,
        attachments: a.attachments!,
      );

      await _refreshSideList();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Nome do anexo atualizado'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao renomear: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleDeleteFile(int index, BuildContext context) async {
    final a = selectedAdditive;
    if (a == null || a.id == null || contract.id == null) return;

    try {
      isSaving = true; notifyListeners();

      final atts = a.attachments ?? [];
      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await additivesStorageBloc.deleteStorageByPath(removed.path);
        }
        await store.bloc.setAttachments(
          contractId: contract.id!,
          additiveId: a.id!,
          attachments: atts,
        );
        selectedAdditive = a..attachments = atts;
      } else if ((a.pdfUrl ?? '').isNotEmpty) {
        await store.storage.salvarUrlPdfDoAditivo(
          contractId: contract.id!,
          additiveId: a.id!,
          url: '',
        );
        selectedAdditive = a..pdfUrl = null;
      }

      await _refreshSideList();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo removido'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao remover: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  // ✅ ABERTURA INTERNA (fullscreen no mobile)
  Future<void> handleOpenFile(BuildContext context, int index) async {
    if (index < 0 || index >= sideItems.length) return;
    final url = sideItems[index].url;
    if (url.isEmpty) return;

    _selectSideIndex(index);

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url!),
      ),
    );
  }

  // Legado (mantido para uploads por picker clássico)
  Future<void> uploadValidityPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedAdditive?.id == null) return;
    final url = await store.storage.uploadWithPicker(
      contract: contract,
      additive: selectedAdditive!,
      onProgress: onProgress,
    );
    await store.storage.salvarUrlPdfDoAditivo(
      contractId: contract.id!,
      additiveId: selectedAdditive!.id!,
      url: url,
    );
    selectedAdditive = selectedAdditive!..pdfUrl = url;
    await _refreshSideList();
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
