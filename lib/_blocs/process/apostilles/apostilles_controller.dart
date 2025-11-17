// ==============================
// lib/_blocs/process/contracts/apostilles/apostilles_controller.dart
// ==============================
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_storage_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

// ⬇️ abre dentro do app
import 'package:siged/_services/pdf/pdf_preview.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/formats/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/handle/handle_selection_utils.dart';

// ✅ papéis/permissões
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

// ✅ notificações ricas
import 'package:intl/intl.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ApostillesController extends ChangeNotifier with FormValidationMixin {
  // Injetados
  final ApostillesStore store;
  final ProcessData contract;
  final ApostillesStorageBloc apostillesStorageBloc;

  // User (via UserBloc)
  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

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
  final orderController = TextEditingController();
  final dateController = TextEditingController();
  final valueController = TextEditingController();
  final processController = TextEditingController();

  // SideListBox (String | Attachment)
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;

  bool get canAddFile => isEditable && selectedApostille?.id != null;

  ApostillesController({
    required this.store,
    required this.contract,
    ApostillesStorageBloc? storageBloc,
  }) : apostillesStorageBloc = storageBloc ?? ApostillesStorageBloc() {
    _init();
  }

  // === helpers p/ rótulo rico ===
  String _userName() {
    final u = _currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  // ======= ORDENS: dropdown inteligente =======
  Set<int> get _existingOrders =>
      _lastSnapshot.map((v) => v.apostilleOrder ?? 0).where((n) => n > 0).toSet();

  int _nextAvailableOrder(Set<int> set) {
    if (set.isEmpty) return 1;
    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }
    final max = set.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  /// Opções mostradas no dropdown (1 .. maxExistente+1)
  List<String> get orderNumberOptions {
    final set = _existingOrders;
    final maxPlusOne = set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  /// Itens em cinza (já usados)
  Set<String> get greyOrderItems => _existingOrders.map((e) => e.toString()).toSet();

  /// Clique num item do dropdown
  void onChangeOrderNumber(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    final idx = _lastSnapshot.indexWhere((x) => (x.apostilleOrder ?? -1) == picked);
    if (idx >= 0) {
      // já existe -> carrega registro
      handleApostilleSelection(_lastSnapshot[idx]);
    } else {
      // livre -> inicia novo naquela ordem
      createNew();
      orderController.text = '$picked';
      notifyListeners();
    }
  }

  void _init() {
    futureApostilles = _getAll();
    _setNextOrder();
    setupValidation([dateController, valueController, processController], _validateForm);
  }

  /// Pós-frame: depende de BuildContext
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

    final canEdit   = perms.userCanModule(user: user, module: 'apostilles', action: 'edit');
    final canCreate = perms.userCanModule(user: user, module: 'apostilles', action: 'create');
    return canEdit || canCreate;
  }

  // LOADS
  Future<List<ApostillesData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    final list = store.listFor(contract.id!);
    _lastSnapshot = list;

    // Define próxima ordem livre
    final next = _nextAvailableOrder(_existingOrders);
    orderController.text = '$next';

    return list;
  }

  Future<void> reload() async {
    if (contract.id == null) return;
    await store.refreshFor(contract.id!);
    final list = store.listFor(contract.id!);
    futureApostilles = Future.value(list);
    _lastSnapshot = list;

    // atualiza a próxima ordem
    final next = _nextAvailableOrder(_existingOrders);
    orderController.text = '$next';

    notifyListeners();
  }

  // VALIDATION
  void _validateForm() {
    final valid = dateController.text.isNotEmpty &&
        valueController.text.isNotEmpty &&
        processController.text.isNotEmpty;

    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // FILL / CLEAR
  Future<void> _setNextOrder() async {
    if (contract.id == null) return;
    await store.ensureFor(contract.id!);
    final list = store.listFor(contract.id!);
    _lastSnapshot = list;

    final next = _nextAvailableOrder(_existingOrders);
    orderController.text = '$next';
    notifyListeners();
  }

  void fillFields(ApostillesData data) {
    selectedApostille = data;
    editingMode = true;
    currentApostilleId = data.id;

    orderController.text = (data.apostilleOrder ?? '').toString();
    dateController.text = data.apostilleData != null ? dateTimeToDDMMYYYY(data.apostilleData!) : '';
    valueController.text = priceToString(data.apostilleValue);
    processController.text = data.apostilleNumberProcess ?? '';

    _validateForm();
    _refreshSideList();
    notifyListeners();
  }

  void createNew() {
    editingMode = false;
    currentApostilleId = null;
    selectedApostille = null;

    dateController.clear();
    valueController.clear();
    processController.clear();

    sideItems = const <dynamic>[];
    selectedSideIndex = null;

    // mantém a ordem já escolhida no dropdown se houver; senão calcula próxima
    if (orderController.text.trim().isEmpty) {
      final next = _nextAvailableOrder(_existingOrders);
      orderController.text = '$next';
    }

    _validateForm();
    notifyListeners();
  }

  // SAVE / UPDATE
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final novo = ApostillesData(
        id: currentApostilleId,
        apostilleOrder: int.tryParse(orderController.text),
        apostilleData: convertDDMMYYYYToDateTime(dateController.text),
        apostilleValue: stringToDouble(valueController.text),
        apostilleNumberProcess: processController.text,
        pdfUrl: selectedApostille?.pdfUrl,
        attachments: selectedApostille?.attachments,
      );

      await store.saveOrUpdate(contract.id!, novo);
      await reload();
      createNew();

      // ✅ toast sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: Text(editingMode ? 'Apostilamento atualizado' : 'Apostilamento salvo'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      // ✅ toast erro
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

  // DELETE
  Future<void> deleteApostille(BuildContext context, String id) async {
    if (contract.id == null) return;
    try {
      await store.delete(contract.id!, id);
      await reload();

      // ✅ toast sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Apostilamento removido'),
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
    }
  }

  // TABLE / GRAPH selection
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

  // ====== SideListBox / anexos ======

  Future<void> _refreshSideList() async {
    final a = selectedApostille;
    if (a == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 1) se já houver attachments no doc, usa-os
    if ((a.attachments ?? const []).isNotEmpty) {
      sideItems = List<dynamic>.from(a.attachments!);
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 2) se houver pdfUrl legado, cria um attachment único e salva
    if ((a.pdfUrl ?? '').isNotEmpty && a.id != null && contract.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento do apostilamento',
        url: a.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.uid,
      );
      await store.bloc.setAttachments(
        contractId: contract.id!,
        apostilleId: a.id!,
        attachments: [att],
      );
      selectedApostille = a..attachments = [att]..pdfUrl = null;
      sideItems = [att];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 3) materializa arquivos do Storage se existirem
    if (contract.id != null && a.id != null) {
      final files = await apostillesStorageBloc.listarArquivosDaApostila(
        contractId: contract.id!,
        apostilleId: a.id!,
      );
      if (files.isNotEmpty) {
        final list = files
            .map((f) => Attachment(
          id: f.name,
          label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          url: f.url,
          path: 'contracts/${contract.id}/apostilles/${a.id}/${f.name}',
          ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
              .firstMatch(f.name)
              ?.group(0) ??
              '',
          createdAt: DateTime.now(),
          createdBy: _currentUser?.uid,
        ))
            .toList();
        await store.bloc.setAttachments(
          contractId: contract.id!,
          apostilleId: a.id!,
          attachments: list,
        );
        selectedApostille = a..attachments = list;
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
    final ord = selectedApostille?.apostilleOrder ?? 0;
    return 'Apostilamento $ord - $base';
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
    final aId = selectedApostille?.id;
    final a = selectedApostille;
    if (cId == null || aId == null || a == null) return;

    try {
      isSaving = true; notifyListeners();

      final (Uint8List bytes, String originalName) = await apostillesStorageBloc.pickFileBytes();

      final suggestion = _suggestLabelFromName(originalName);
      final label = await _askLabel(context, suggestion: suggestion);
      if (label == null) { isSaving = false; notifyListeners(); return; }

      final att = await apostillesStorageBloc.uploadAttachmentBytes(
        contract: contract,
        apostille: a,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current = List<Attachment>.from(a.attachments ?? const []);
      current.add(att);

      await store.bloc.setAttachments(
        contractId: cId,
        apostilleId: aId,
        attachments: current,
      );

      selectedApostille = a..attachments = current;
      await _refreshSideList();

      // ✅ toast sucesso
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
    final a = selectedApostille;
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
        updatedBy: _currentUser?.uid,
      );

      await store.bloc.setAttachments(
        contractId: contract.id!,
        apostilleId: a.id!,
        attachments: a.attachments!,
      );

      await _refreshSideList();

      // ✅ toast sucesso
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
    final a = selectedApostille;
    if (a == null || a.id == null || contract.id == null) return;

    try {
      isSaving = true; notifyListeners();

      final atts = a.attachments ?? [];
      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await apostillesStorageBloc.deleteStorageByPath(removed.path);
        }
        await store.bloc.setAttachments(
          contractId: contract.id!,
          apostilleId: a.id!,
          attachments: atts,
        );
        selectedApostille = a..attachments = atts;
      } else if ((a.pdfUrl ?? '').isNotEmpty) {
        await store.storage.salvarUrlPdfDaApostila(
          contractId: contract.id!,
          apostilleId: a.id!,
          url: '',
        );
        selectedApostille = a..pdfUrl = null;
      }

      await _refreshSideList();

      // ✅ toast sucesso
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

  /// ⬇️ Abre o PDF em Dialog interno com PdfPreview
  Future<void> handleOpenFile(BuildContext context, int index) async {
    final a = selectedApostille;
    if (a == null) return;

    String? url;
    if ((a.attachments ?? []).isNotEmpty) {
      final att = a.attachments![index];
      url = att.url;
      _selectSideIndex(index);
    } else {
      url = a.pdfUrl;
    }
    if (url == null || url.isEmpty) return;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url!),
      ),
    );
  }

  // Legado (mantido)
  Future<void> uploadValidityPdf({
    required void Function(double) onProgress,
  }) async {
    if (contract.id == null || selectedApostille?.id == null) return;
    final url = await store.storage.uploadWithPicker(
      contract: contract,
      apostille: selectedApostille!,
      onProgress: onProgress,
    );
    await store.storage.salvarUrlPdfDaApostila(
      contractId: contract.id!,
      apostilleId: selectedApostille!.id!,
      url: url,
    );
    selectedApostille = selectedApostille!..pdfUrl = url;
    await _refreshSideList();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation([dateController, valueController, processController], _validateForm);
    orderController.dispose();
    dateController.dispose();
    valueController.dispose();
    processController.dispose();
    super.dispose();
  }
}
