import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
// ⬇️ abre PDF internamente
import 'package:siged/_services/pdf/pdf_preview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/handle_selection_utils.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/screens/process/measurement/create/create_detailed_reports_page.dart';

import 'report_measurement_bloc.dart';
import 'report_measurement_storage_bloc.dart';

// ✅ papéis/permissões
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

// ✅ formato de data/hora do rótulo rico
import 'package:intl/intl.dart';

class ReportMeasurementController extends ChangeNotifier with FormValidationMixin {
  ReportMeasurementController({
    required this.contract,
    ReportMeasurementBloc? measurementBloc,
    AdditivesBloc? additivesBloc,
    ReportMeasurementStorageBloc? storageBloc,
  })  : _measurementBloc = measurementBloc ?? ReportMeasurementBloc(),
        _additivesBloc = additivesBloc ?? AdditivesBloc(),
        _storageBloc = storageBloc ?? ReportMeasurementStorageBloc() {
    _initValidation();
  }

  // ---- deps / bloc ----
  final ReportMeasurementBloc _measurementBloc; // REPORT-only
  final AdditivesBloc _additivesBloc;
  final ReportMeasurementStorageBloc _storageBloc;

  // ---- contexto ----
  final ContractData contract;
  UserData? _currentUser;
  StreamSubscription<UserState>? _userSub;

  // ---- estado UI ----
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  // ---- SideListBox (arquivos) ----
  List<Attachment> sideItems = <Attachment>[];
  int? selectedSideIndex;

  // ---- dados / paginação ----
  final int _itemsPerPage = 50;
  List<ReportMeasurementData> _all = <ReportMeasurementData>[];
  List<ReportMeasurementData> selectorUniverse = <ReportMeasurementData>[];
  List<ReportMeasurementData> _pageItems = <ReportMeasurementData>[];

  int _currentPage = 1;
  int _totalPages = 1;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  List<ReportMeasurementData> get reports => _pageItems;
  ReportMeasurementStorageBloc get reportMeasurementStorageBloc => _storageBloc;

  // ---- agregados (contrato) ----
  double valorInicialContrato = 0.0;
  double totalAditivos = 0.0;

  double get valorTotalDisponivel => valorInicialContrato + totalAditivos;
  double get totalMedicoes =>
      selectorUniverse.fold<double>(0.0, (a, e) => a + (e.value ?? 0.0));
  double get saldo => valorTotalDisponivel - totalMedicoes;

  // ---- seleção ----
  ReportMeasurementData? selectedReport;
  String? currentReportId;

  // ---- controllers do form ----
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // ---- derivados p/ gráfico ----
  List<String> get labels =>
      selectorUniverse.map((m) => (m.order ?? 0).toString()).toList();
  List<double> get values =>
      selectorUniverse.map((m) => (m.value ?? 0.0)).toList();

  // ================= helpers para rótulo rico =================
  String _userName() {
    final u = _currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  // ================= LIFECYCLE =================
  void _initValidation() {
    setupValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
  }

  Future<void> init(BuildContext context) async {
    final userBloc = context.read<UserBloc>();
    _currentUser = userBloc.state.current;
    isEditable = _canEditUser(_currentUser);

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

    await _loadInitialData();
  }

  Future<void> postFrameInit(BuildContext context) => init(context);

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  // ================= PERMISSÕES =================
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;
    final canEdit = perms.userCanModule(user: user, module: 'report_measurement', action: 'edit');
    final canCreate = perms.userCanModule(user: user, module: 'report_measurement', action: 'create');
    return canEdit || canCreate;
  }

  Future<void> openBoletimModal(BuildContext context) async {
    final numero = selectedReport?.order ?? int.tryParse(orderCtrl.text) ?? 0;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateDetailedReportPage(
          titulo: 'Boletim de Medição Nº $numero',
          contractData: contract,
          measurement: selectedReport, // se null, cai no orçamento contratado
        ),
      ),
    );
  }


  // ================= LOAD / PAGE =================
  Future<void> _loadInitialData() async {
    if (contract.id == null) {
      _all = [];
      selectorUniverse = [];
      _refreshPagination();
      notifyListeners();
      return;
    }

    valorInicialContrato = contract.initialValueContract ?? 0.0;
    totalAditivos        = await _additivesBloc.getAllAdditivesValue(contract.id!);

    _all = await _measurementBloc.getAllMeasurementsOfContract(uidContract: contract.id!);

    _all.sort((a, b) {
      final ao = a.order ?? -1;
      final bo = b.order ?? -1;
      if (ao != bo) return ao.compareTo(bo);
      final ad = a.date?.millisecondsSinceEpoch ?? 0;
      final bd = b.date?.millisecondsSinceEpoch ?? 0;
      return ad.compareTo(bd);
    });

    selectorUniverse = List<ReportMeasurementData>.from(_all);

    final lastOrder = selectorUniverse.isNotEmpty
        ? selectorUniverse.map((e) => e.order ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (lastOrder + 1).toString();

    _currentPage = 1;
    _refreshPagination();

    sideItems = const <Attachment>[];
    selectedSideIndex = null;

    notifyListeners();
  }

  void _refreshPagination() {
    final total = selectorUniverse.length;
    _totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > total) ? total : start + _itemsPerPage;
    _pageItems = (start < end) ? selectorUniverse.sublist(start, end) : <ReportMeasurementData>[];
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _refreshPagination();
    notifyListeners();
  }

  // ================= FORM =================
  void _validateForm() {
    final ok = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(ReportMeasurementData data) {
    selectedReport  = data;
    currentReportId = data.id;

    orderCtrl.text   = (data.order ?? '').toString();
    processCtrl.text = data.numberprocess ?? '';
    valueCtrl.text   = priceToString(data.value);
    dateCtrl.text    = dateTimeToDDMMYYYY(data.date);

    _validateForm();
    _refreshSideFiles();
    notifyListeners();
  }

  void createNew() {
    selectedLine    = null;
    selectedReport  = null;
    currentReportId = null;

    final nextOrder = (selectorUniverse.isNotEmpty
        ? selectorUniverse.map((e) => e.order ?? 0).reduce((a, b) => a > b ? a : b)
        : 0) + 1;

    orderCtrl.text = nextOrder.toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();

    sideItems = const <Attachment>[];
    selectedSideIndex = null;

    _validateForm();
    notifyListeners();
  }

  // ================= CRUD (REPORT) =================
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true; notifyListeners();
    try {
      final novo = ReportMeasurementData(
        id: currentReportId,
        contractId: contract.id!,
        order: int.tryParse(orderCtrl.text),
        numberprocess: processCtrl.text,
        value: parseCurrencyToDouble(valueCtrl.text),
        date: convertDDMMYYYYToDateTime(dateCtrl.text),
        attachments: selectedReport?.attachments, // preserva anexos
      );

      await _measurementBloc.saveOrUpdateReport(novo);

      await _loadInitialData();
      createNew();

      // ✅ toast sucesso com rótulo rico
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Medição salva'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } catch (e) {
      // ✅ toast erro
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao salvar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> deleteReport(BuildContext context, String id) async {
    if (contract.id == null) return;
    isSaving = true; notifyListeners();

    try {
      await _measurementBloc.deletarMedicao(contract.id!, id);
      await _loadInitialData();

      if (currentReportId == id) {
        createNew();
      }

      // ✅ toast sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Medição apagada'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } catch (e) {
      // ✅ toast erro
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao apagar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  // ================= Seleção (gráfico/tabela) =================
  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < selectorUniverse.length) {
      handleSelect(selectorUniverse[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(ReportMeasurementData data) {
    handleGenericSelection<ReportMeasurementData>(
      data: data,
      list: selectorUniverse,
      getOrder: (e) => e.order,
      onSetState: (index) {
        selectedLine    = index;
        selectedReport  = data;
        currentReportId = data.id;
        fillFields(data);
      },
    );
  }

  // ================= SideListBox helpers =================
  Future<void> _refreshSideFiles() async {
    if (selectedReport == null) {
      sideItems = const <Attachment>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 1) MIGRAÇÃO
    final hasNoAttachments = selectedReport!.attachments == null || selectedReport!.attachments!.isEmpty;
    final legacyUrl = selectedReport!.pdfUrl ?? '';

    if (hasNoAttachments && legacyUrl.isNotEmpty && contract.id != null && selectedReport!.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'PDF da medição',
        url: legacyUrl,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.id,
      );
      final list = <Attachment>[att];

      await FirebaseFirestore.instance
          .collection('contracts').doc(contract.id)
          .collection(ReportMeasurementData.collectionName).doc(selectedReport!.id)
          .set({
        'attachments': list.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      selectedReport = selectedReport!..attachments = list;
    }

    // 2) Preferir attachments novos
    final atts = selectedReport!.attachments ?? const <Attachment>[];
    if (atts.isNotEmpty) {
      sideItems = List<Attachment>.from(atts);
      selectedSideIndex = (selectedSideIndex != null && selectedSideIndex! < atts.length)
          ? selectedSideIndex
          : 0;
      notifyListeners();
      return;
    }

    // 3) Fallback Storage PDF único
    try {
      final exists = await _storageBloc.exists(contract, selectedReport!);
      if (exists) {
        final url = await _storageBloc.getUrl(contract, selectedReport!) ?? '';
        if (url.isNotEmpty) {
          sideItems = <Attachment>[
            Attachment(
              id: 'legacy-pdf',
              label: 'PDF da medição',
              url: url,
              path: '',
              ext: '.pdf',
            ),
          ];
          selectedSideIndex = 0;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // ignora
    }

    sideItems = const <Attachment>[];
    selectedSideIndex = null;
    notifyListeners();
  }

  void selectSideIndex(int i) {
    selectedSideIndex = i;
    notifyListeners();
  }

  // ================= Anexos com rótulo =================

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?'); if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#'); if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String _labelSuggestion(String originalName) {
    final ord = selectedReport?.order ?? int.tryParse(orderCtrl.text) ?? 0;
    final noExt = _baseName(originalName);
    return ord > 0 ? 'Medição #$ord - $noExt' : noExt;
  }

  Future<String?> _askLabelDialog(BuildContext context, String suggestion) async {
    final ctrl = TextEditingController(text: suggestion);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome do arquivo (rótulo)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Ex.: Medição #05 - PDF'),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
  }

  Future<void> addAttachment(BuildContext context) async {
    if (!isEditable) return;
    if (contract.id == null || selectedReport?.id == null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Selecione a medição'),
          type: AppNotificationType.warning,
            details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
      return;
    }

    try {
      final pick = await FilePicker.platform.pickFiles(withData: true);
      if (pick == null || pick.files.single.bytes == null) return;

      final file = pick.files.single;
      final suggested = _labelSuggestion(file.name);
      final label = (await _askLabelDialog(context, suggested))?.trim() ?? suggested;

      isSaving = true; notifyListeners();

      final att = await _storageBloc.uploadAttachmentBytes(
        contract: contract,
        measurement: selectedReport!,
        bytes: file.bytes!,
        originalName: file.name,
        label: label,
      );

      final newList = [...(selectedReport!.attachments ?? const <Attachment>[])];
      newList.insert(0, att);
      selectedReport = selectedReport!..attachments = newList;

      await FirebaseFirestore.instance
          .collection('contracts').doc(contract.id)
          .collection(ReportMeasurementData.collectionName).doc(selectedReport!.id)
          .set({
        'attachments': newList.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _refreshSideFiles();

      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Adicionado "${att.label}"'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao anexar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> editAttachmentLabel(BuildContext context, int index) async {
    if (!isEditable) return;
    if (selectedReport == null || index < 0 || index >= sideItems.length) return;

    final current = sideItems[index];
    final newLabel = await _askLabelDialog(context, current.label);
    if (newLabel == null || newLabel.isEmpty || newLabel == current.label) return;

    try {
      isSaving = true; notifyListeners();

      sideItems[index] = current..label = newLabel;
      selectedReport = selectedReport!..attachments = List.of(sideItems);

      await FirebaseFirestore.instance
          .collection('contracts').doc(contract.id)
          .collection(ReportMeasurementData.collectionName).doc(selectedReport!.id)
          .set({
        'attachments': sideItems.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Nome atualizado'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao renomear: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> deleteAttachmentAt(BuildContext context, int index) async {
    if (!isEditable) return;
    if (selectedReport == null || index < 0 || index >= sideItems.length) return;

    final att = sideItems[index];

    try {
      isSaving = true; notifyListeners();

      await _storageBloc.deleteStorageByPath(att.path);

      sideItems.removeAt(index);
      selectedReport = selectedReport!..attachments = List.of(sideItems);

      await FirebaseFirestore.instance
          .collection('contracts').doc(contract.id)
          .collection(ReportMeasurementData.collectionName).doc(selectedReport!.id)
          .set({
        'attachments': sideItems.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo removido.'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao remover: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11))
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  /// ⬇️ Abre o anexo em Dialog interno com PdfPreview
  Future<void> handleOpenAttachment(BuildContext context, int index) async {
    if (index < 0 || index >= sideItems.length) return;
    final url = sideItems[index].url;
    if (url.isEmpty) return;

    selectSideIndex(index);

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url),
      ),
    );
  }
}
