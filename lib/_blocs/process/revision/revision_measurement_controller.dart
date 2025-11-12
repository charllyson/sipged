// lib/_blocs/process/revision/revision_measurement_controller.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
// ⬇️ abre PDF dentro do app
import 'package:siged/_services/pdf/pdf_preview.dart';

import 'package:siged/_blocs/process/revision/revision_measurement_bloc.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_data.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_storage_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/formats/date_utils.dart'
    show dateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;
import 'package:siged/_utils/handle/handle_selection_utils.dart';

// roles/perms
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// 🗓️ formato do selo
import 'package:intl/intl.dart';

class RevisionMeasurementController extends ChangeNotifier
    with FormValidationMixin {
  RevisionMeasurementController({
    required this.contract,
    required RevisionMeasurementBloc measurementBloc,
    required AdditivesBloc additivesBloc,
    RevisionMeasurementStorageBloc? storageBloc,
  })  : _measurementBloc = measurementBloc,
        _additivesBloc = additivesBloc,
        _storageBloc = storageBloc ?? RevisionMeasurementStorageBloc();

  // --- Dependências
  final RevisionMeasurementBloc _measurementBloc;
  final AdditivesBloc _additivesBloc;
  final RevisionMeasurementStorageBloc _storageBloc;

  // --- Contexto
  final ProcessData contract;
  UserData? currentUser;

  StreamSubscription<UserState>? _userSub;

  // --- Estado UI
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedIndex;

  // --- Dados
  List<RevisionMeasurementData> _all = <RevisionMeasurementData>[];
  List<RevisionMeasurementData> _selectorUniverse = <RevisionMeasurementData>[];

  // --- Paginação
  final int _itemsPerPage = 50;
  int _currentPage = 1;
  int _totalPages = 1;
  List<RevisionMeasurementData> _pageItems = <RevisionMeasurementData>[];

  // --- Seleção
  RevisionMeasurementData? _selected;
  String? _currentId;

  // --- Totais
  double _valorInicialContrato = 0.0;
  double _totalAditivos = 0.0;

  // --- Controllers
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // --- SideListBox (arquivos) - compat: String/Attachment
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;

  bool get canAddFile => isEditable && _selected?.id != null;
  String? get currentPdfUrl => _selected?.pdfUrl;

  // --- Guard init ---
  bool _didInit = false;

  // === helpers selo rico ===
  String _userName() {
    final u = currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  // === Getters usados pela UI ===
  List<RevisionMeasurementData> get revision => _all;
  List<RevisionMeasurementData> get selectorUniverse => _selectorUniverse;
  List<RevisionMeasurementData> get pageItems => _pageItems;

  RevisionMeasurementData? get selectedRevision => _selected;
  String? get currentRevisionId => _currentId;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  double get valorInicialContrato => _valorInicialContrato;
  double get totalAditivos => _totalAditivos;

  List<String> get labels =>
      _selectorUniverse.map((m) => (m.order ?? 0).toString()).toList();

  List<double> get values =>
      _selectorUniverse.map((m) => m.value ?? 0.0).toList();

  double get totalMedicoes => values.fold<double>(0.0, (a, b) => a + b);
  double get valorTotalDisponivel => _valorInicialContrato + _totalAditivos;
  double get saldo => valorTotalDisponivel - totalMedicoes;

  // =================== NOVO: helpers do dropdown de ordem ===================
  Set<int> get _existingOrders =>
      _selectorUniverse.map((e) => e.order ?? 0).where((e) => e > 0).toSet();

  int get nextAvailableOrder {
    if (_existingOrders.isEmpty) return 1;
    // primeiro “buraco” entre 1..N
    for (int i = 1; i <= (_existingOrders.length + 1); i++) {
      if (!_existingOrders.contains(i)) return i;
    }
    // senão, max+1
    final max = _existingOrders.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  List<String> get orderOptions {
    final maxPlusOne = _existingOrders.isEmpty
        ? 1
        : _existingOrders.reduce((a, b) => a > b ? a : b) + 1;
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  Set<String> get greyOrderItems =>
      _existingOrders.map((e) => e.toString()).toSet();

  void onChangeOrderDropdown(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    final idx = _selectorUniverse.indexWhere((m) => (m.order ?? -1) == picked);
    if (idx >= 0) {
      // já existe -> seleciona o registro
      handleSelect(_selectorUniverse[idx]);
      return;
    }

    // não existe -> inicia form novo com a ordem escolhida
    createNew();
    orderCtrl.text = picked.toString();
    notifyListeners();
  }
  // ========================================================================

  // === Init/Dispose ===
  Future<void> init(BuildContext context) async {
    if (_didInit) return;
    _didInit = true;

    final userBloc = context.read<UserBloc>();
    currentUser = userBloc.state.current;
    isEditable = _canEditUser(currentUser);

    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
      final prevId = currentUser?.id;
      currentUser = st.current;
      final nowId = currentUser?.id;

      final newEditable = _canEditUser(currentUser);
      if (newEditable != isEditable || prevId != nowId) {
        isEditable = newEditable;
        notifyListeners();
      }
    });

    setupValidation(
        [orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    await _loadInitial();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation(
        [orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  // === Permissões (módulo: measurement_revision) ===
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;

    final canEdit = perms.userCanModule(
      user: user,
      module: 'measurement_revision',
      action: 'edit',
    );
    final canCreate = perms.userCanModule(
      user: user,
      module: 'measurement_revision',
      action: 'create',
    );
    return canEdit || canCreate;
  }

  // === Load ===
  Future<void> _loadInitial() async {
    _valorInicialContrato = contract.initialValueContract ?? 0.0;
    if (contract.id != null) {
      _totalAditivos = await _additivesBloc.getAllAdditivesValue(contract.id!);
      _all = await _measurementBloc.getAllRevisionsOfContract(
          uidContract: contract.id!);
    } else {
      _totalAditivos = 0.0;
      _all = [];
    }

    _all.sort((a, b) {
      final ao = a.order ?? -1;
      final bo = b.order ?? -1;
      if (ao != bo) return ao.compareTo(bo);
      final ad = a.date?.millisecondsSinceEpoch ?? 0;
      final bd = b.date?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });

    _selectorUniverse = List<RevisionMeasurementData>.from(_all);

    // ✅ usa sempre o “próximo disponível”
    orderCtrl.text = nextAvailableOrder.toString();

    _currentPage = 1;
    _refreshPagination();

    await _refreshSideList();
    notifyListeners();
  }

  void _refreshPagination() {
    final total = _selectorUniverse.length;
    _totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (_currentPage - 1) * _itemsPerPage;
    final end =
    (start + _itemsPerPage > total) ? total : start + _itemsPerPage;
    _pageItems = (start < end)
        ? _selectorUniverse.sublist(start, end)
        : <RevisionMeasurementData>[];
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _refreshPagination();
    notifyListeners();
  }

  // === Form/Validação ===
  void _validateFormInternal() {
    final valid =
    areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl],
        minLength: 1);
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // === Seleção ===
  void onSelectGraphIndex(int index) {
    selectedIndex = index;
    if (index >= 0 && index < _selectorUniverse.length) {
      handleSelect(_selectorUniverse[index]);
    } else {
      notifyListeners();
    }
  }

  void selectRow(RevisionMeasurementData data) {
    final idx = _selectorUniverse.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.id;

    orderCtrl.text = '${data.order ?? ''}';
    processCtrl.text = data.numberprocess ?? '';
    valueCtrl.text = priceToString(data.value);
    dateCtrl.text = dateTimeToDDMMYYYY(data.date);

    _validateFormInternal();
    _refreshSideList();
    notifyListeners();
  }

  void handleSelect(RevisionMeasurementData data) {
    handleGenericSelection<RevisionMeasurementData>(
      data: data,
      list: _selectorUniverse,
      getOrder: (e) => e.order,
      onSetState: (index) {
        selectedIndex = index;
        _selected = data;
        _currentId = data.id;
        selectRow(data);
      },
    );
  }

  void createNew() {
    selectedIndex = null;
    _selected = null;
    _currentId = null;

    // ✅ agora também usa “próximo disponível”
    orderCtrl.text = nextAvailableOrder.toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();

    _validateFormInternal();
    _refreshSideList();
    notifyListeners();
  }

  // === CRUD ===
  Future<bool> saveOrUpdate({
    required Future<bool> Function() onConfirm,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    final confirmed = await onConfirm();
    if (!confirmed) return false;

    try {
      isSaving = true;
      notifyListeners();

      final novo = RevisionMeasurementData(
        id: _currentId,
        contractId: contract.id!,
        order: int.tryParse(orderCtrl.text),
        numberprocess: processCtrl.text,
        value: parseCurrencyToDouble(valueCtrl.text),
        date: convertDDMMYYYYToDateTime(dateCtrl.text),
        pdfUrl: _selected?.pdfUrl,
        attachments: _selected?.attachments,
      );

      await _measurementBloc.saveOrUpdateRevision(
        contractId: contract.id!,
        revisionMeasurementId: _currentId ?? '',
        rev: novo,
      );

      await _loadInitial();
      createNew();

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Revisão salva'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      onSuccess?.call();
      return true;
    } catch (_) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao salvar revisão'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      onError?.call();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteById(
      String idRevisionMeasurement, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    try {
      await _measurementBloc.deleteRevision(
        contractId: contract.id!,
        revisionId: idRevisionMeasurement,
      );
      await _loadInitial();
      selectedIndex = null;

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Revisão apagada'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      onSuccess?.call();
    } catch (_) {
      // 🔔 erro
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao apagar revisão'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      onError?.call();
    } finally {
      notifyListeners();
    }
  }

  // === SideListBox: helpers ===
  Future<void> _refreshSideList() async {
    final r = _selected;
    if (r == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // MIGRAÇÃO: se só tem pdfUrl -> cria attachment único
    if ((r.attachments == null || r.attachments!.isEmpty) &&
        (r.pdfUrl ?? '').isNotEmpty &&
        r.id != null &&
        contract.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'PDF da Revisão',
        url: r.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: currentUser?.id,
      );
      final list = <Attachment>[att];

      await _measurementBloc.setAttachments(
        contractId: contract.id!,
        revisionId: r.id!,
        attachments: list,
      );
      _selected = r..attachments = list;
      _selected!.pdfUrl = null;
    }

    final atts = _selected?.attachments ?? const <Attachment>[];
    if (atts.isNotEmpty) {
      sideItems = List<dynamic>.from(atts);
      selectedSideIndex =
      (selectedSideIndex != null && selectedSideIndex! < atts.length)
          ? selectedSideIndex
          : null;
    } else if ((r.pdfUrl ?? '').isNotEmpty) {
      sideItems = const <dynamic>['PDF da Revisão'];
      selectedSideIndex = 0;
    } else {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
    }
    notifyListeners();
  }

  String _defaultLabelFromOriginal(String original) {
    final base =
    original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = _selected?.order ?? 0;
    return 'Revisão $ord - $base';
  }

  Future<String?> _askLabel(BuildContext context,
      {required String suggestion}) async {
    final ctrl = TextEditingController(text: suggestion);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nome do arquivo'),
        content: TextField(
          controller: ctrl,
          decoration:
          const InputDecoration(labelText: 'Rótulo do arquivo'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
  }

  BuildContext? _ctx;
  void attachBuildContext(BuildContext c) => _ctx = c;

  Future<void> handleAddFile() async {
    if (!canAddFile || contract.id == null || _selected?.id == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final (Uint8List bytes, String original) =
      await _storageBloc.pickFileBytes();

      final suggestion = _defaultLabelFromOriginal(original);
      final label = await _askLabel(_ctx!, suggestion: suggestion);
      if (label == null) {
        isSaving = false;
        notifyListeners();
        return;
      }

      final att = await _storageBloc.uploadAttachmentBytes(
        contract: contract,
        revision: _selected!,
        bytes: bytes,
        originalName: original,
        label: label.isEmpty ? suggestion : label,
      );

      final current =
      List<Attachment>.from(_selected?.attachments ?? const []);
      current.add(att);

      _selected = _selected!..attachments = current;
      await _measurementBloc.setAttachments(
        contractId: contract.id!,
        revisionId: _selected!.id!,
        attachments: current,
      );

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
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao anexar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleEditLabelFile(int index) async {
    final r = _selected;
    if (r == null ||
        r.attachments == null ||
        index < 0 ||
        index >= r.attachments!.length) return;

    try {
      isSaving = true;
      notifyListeners();

      final att = r.attachments![index];
      final suggestion =
      att.label.isNotEmpty ? att.label : _defaultLabelFromOriginal(att.id);
      final newLabel = await _askLabel(_ctx!, suggestion: suggestion);
      if (newLabel == null) {
        isSaving = false;
        notifyListeners();
        return;
      }

      r.attachments![index] = Attachment(
        id: att.id,
        label: newLabel.isEmpty ? suggestion : newLabel,
        url: att.url,
        path: att.path,
        ext: att.ext,
        size: att.size,
        createdAt: att.createdAt,
        createdBy: att.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: currentUser?.id,
      );

      await _measurementBloc.setAttachments(
        contractId: contract.id!,
        revisionId: r.id!,
        attachments: r.attachments!,
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

  Future<void> handleDeleteFile(int index) async {
    final r = _selected;
    if (contract.id == null || r?.id == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final atts = r!.attachments ?? [];
      if (atts.isNotEmpty && index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await _storageBloc.deleteStorageByPath(removed.path);
        }
        await _measurementBloc.setAttachments(
          contractId: contract.id!,
          revisionId: r.id!,
          attachments: atts,
        );
        _selected = r..attachments = atts;
      } else if ((r.pdfUrl ?? '').isNotEmpty) {
        await _measurementBloc.salvarUrlPdfDaRevisionMeasurement(
          contractId: contract.id!,
          revisionMeasurementId: r.id!,
          url: '',
        );
        _selected = r..pdfUrl = null;
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

  /// ⬇️ Abre o arquivo em Dialog interno com PdfPreview
  Future<void> handleOpenFile(BuildContext context, int index) async {
    final r = _selected;
    if (r == null) return;

    String? url;
    if ((r.attachments ?? []).isNotEmpty) {
      if (index < 0 || index >= r.attachments!.length) return;
      url = r.attachments![index].url;
    } else {
      // fallback do legado (lista com 1 string)
      url = r.pdfUrl;
    }

    if (url == null || url.isEmpty) return;

    selectedSideIndex = index;
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

  // === PDF (compat) ===
  Future<void> savePdfUrl(String url) async {
    if (_selected?.id == null || contract.id == null) return;
    await _measurementBloc.salvarUrlPdfDaRevisionMeasurement(
      contractId: contract.id!,
      revisionMeasurementId: _selected!.id!,
      url: url,
    );
    _selected = _selected!..pdfUrl = url;
    await _refreshSideList();
  }
}
