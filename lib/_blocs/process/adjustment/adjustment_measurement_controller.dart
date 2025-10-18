// ignore_for_file: unnecessary_this
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

// ⬇️ usamos o preview interno
import 'package:siged/_services/pdf/pdf_preview.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_bloc.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/handle_selection_utils.dart';

import 'package:siged/_blocs/process/adjustment/adjustment_measurement_bloc.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_storage_bloc.dart';

import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// 🗓️ formato do selo rico
import 'package:intl/intl.dart';

class AdjustmentMeasurementController extends ChangeNotifier with FormValidationMixin {
  AdjustmentMeasurementController({
    required this.contract,
    AdjustmentMeasurementBloc? adjustmentBloc,
    AdjustmentMeasurementStorageBloc? storageBloc,
    AdditivesBloc? additivesBloc,
    ApostillesBloc? apostillesBloc,
  })  : _adjustmentBloc = adjustmentBloc ?? AdjustmentMeasurementBloc(),
        _storageBloc = storageBloc ?? AdjustmentMeasurementStorageBloc(),
        _additivesBloc = additivesBloc ?? AdditivesBloc(),
        _apostillesBloc = apostillesBloc ?? ApostillesBloc() {
    _init();
  }

  final AdjustmentMeasurementBloc _adjustmentBloc;
  final AdjustmentMeasurementStorageBloc _storageBloc;
  final AdditivesBloc _additivesBloc;
  final ApostillesBloc _apostillesBloc;

  final ContractData contract;

  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;
  int? selectedLine;

  List<AdjustmentMeasurementData> adjustments = [];
  double totalApostilles = 0.0;
  double totalAdditives = 0.0;

  AdjustmentMeasurementData? selectedAdjustment;
  String? currentAdjustmentId;

  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  // SideListBox (aceita String ou Attachment)
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;
  bool get canAddFile => isEditable && selectedAdjustment?.id != null;
  String? get currentPdfUrl => selectedAdjustment?.pdfUrl;

  // ===== helpers do selo rico (usuário • data/hora) =====
  String _userName() {
    final u = _currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  void _init() {
    setupValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
  }

  Future<void> postFrameInit(BuildContext context) async {
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

    await loadInitialData();
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;
    final canEdit = perms.userCanModule(user: user, module: 'adjustment_measurement', action: 'edit');
    final canCreate = perms.userCanModule(user: user, module: 'adjustment_measurement', action: 'create');
    return canEdit || canCreate;
  }

  Future<void> loadInitialData() async {
    if (contract.id == null) {
      adjustments = [];
      orderCtrl.clear(); processCtrl.clear(); valueCtrl.clear(); dateCtrl.clear();
      await _refreshSideList();
      notifyListeners();
      return;
    }

    totalApostilles = await _apostillesBloc.getAllApostillesValue(contract.id!);
    totalAdditives  = await _additivesBloc.getAllAdditivesValue(contract.id!);

    adjustments = await _adjustmentBloc.getAllAdjustmentsOfContract(uidContract: contract.id!);

    final last = adjustments.map((e) => e.order ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();

    await _refreshSideList();
    notifyListeners();
  }

  List<String> get labels => adjustments.map((m) => (m.order ?? 0).toString()).toList();
  List<double> get values => adjustments.map((m) => m.value ?? 0.0).toList();
  double get totalAdjustments => values.fold(0.0, (a, b) => a + b);
  double get valorTotalDisponivel => totalApostilles + totalAdditives;
  double get saldo => valorTotalDisponivel - totalAdjustments;

  void _validateForm() {
    final ok = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != ok) {
      formValidated = ok;
      notifyListeners();
    }
  }

  void fillFields(AdjustmentMeasurementData data) {
    selectedAdjustment = data;
    currentAdjustmentId = data.id;

    orderCtrl.text   = (data.order ?? '').toString();
    processCtrl.text = data.numberprocess ?? '';
    valueCtrl.text   = priceToString(data.value);
    dateCtrl.text    = dateTimeToDDMMYYYY(data.date);

    _validateForm();
    _refreshSideList();
    notifyListeners();
  }

  void createNew() {
    selectedLine = null;
    selectedAdjustment = null;
    currentAdjustmentId = null;

    final last = adjustments.map((e) => e.order ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();
    processCtrl.clear(); valueCtrl.clear(); dateCtrl.clear();

    _validateForm();
    _refreshSideList();
    notifyListeners();
  }

  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;
    isSaving = true; notifyListeners();

    try {
      final novo = AdjustmentMeasurementData(
        id: currentAdjustmentId,
        order: int.tryParse(orderCtrl.text),
        numberprocess: processCtrl.text,
        value: parseCurrencyToDouble(valueCtrl.text),
        date: convertDDMMYYYYToDateTime(dateCtrl.text),
        pdfUrl: selectedAdjustment?.pdfUrl,
        attachments: selectedAdjustment?.attachments,
      );

      await _adjustmentBloc.saveOrUpdateAdjustment(
        measurementId: selectedAdjustment?.id ?? '',
        contractId: contract.id!,
        adj: novo,
      );

      adjustments = await _adjustmentBloc.getAllAdjustmentsOfContract(uidContract: contract.id!);
      createNew();

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Reajuste salvo'),
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
      isSaving = false; notifyListeners();
    }
  }

  Future<void> deleteAdjustment(BuildContext context, String id) async {
    if (contract.id == null) return;
    isSaving = true; notifyListeners();

    try {
      await _adjustmentBloc.deleteAdjustment(contractId: contract.id!, adjustmentId: id);
      adjustments = await _adjustmentBloc.getAllAdjustmentsOfContract(uidContract: contract.id!);

      if (currentAdjustmentId == id) {
        createNew();
      } else {
        selectedLine = null;
      }

      // 🔔 sucesso
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Reajuste apagado'),
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
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < adjustments.length) {
      handleSelect(adjustments[index]);
    } else {
      notifyListeners();
    }
  }

  void handleSelect(AdjustmentMeasurementData data) {
    handleGenericSelection<AdjustmentMeasurementData>(
      data: data,
      list: adjustments,
      getOrder: (e) => e.order,
      onSetState: (index) {
        selectedLine = index;
        selectedAdjustment = data;
        currentAdjustmentId = data.id;
        fillFields(data);
      },
    );
  }

  // ===== SideListBox =====
  Future<void> _refreshSideList() async {
    final a = selectedAdjustment;
    if (a == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // Migração do pdfUrl legado -> Attachment
    if ((a.attachments == null || a.attachments!.isEmpty) &&
        (a.pdfUrl ?? '').isNotEmpty &&
        a.id != null &&
        contract.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'PDF do Reajuste',
        url: a.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.id,
      );
      final list = <Attachment>[att];
      await _adjustmentBloc.setAttachments(
        contractId: contract.id!,
        adjustmentId: a.id!,
        attachments: list,
      );
      selectedAdjustment = a..attachments = list;
      selectedAdjustment!.pdfUrl = null;
    }

    final atts = selectedAdjustment?.attachments ?? const <Attachment>[];
    if (atts.isNotEmpty) {
      sideItems = List<dynamic>.from(atts);
      selectedSideIndex =
      (selectedSideIndex != null && selectedSideIndex! < atts.length) ? selectedSideIndex : null;
    } else {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
    }
    notifyListeners();
  }

  void selectSideIndex(int i) {
    selectedSideIndex = i;
    notifyListeners();
  }

  String _defaultLabelFromOriginal(String originalName) {
    final base = originalName.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = selectedAdjustment?.order ?? 0;
    return 'Reajuste $ord - $base';
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

  Future<void> handleAddFile() async {
    if (!canAddFile || contract.id == null || selectedAdjustment?.id == null) return;

    try {
      isSaving = true; notifyListeners();

      final (Uint8List bytes, String originalName) = await _storageBloc.pickFileBytes();

      final suggestion = _defaultLabelFromOriginal(originalName);
      final label = await _askLabel(_currentContext!, suggestion: suggestion);
      if (label == null) { isSaving = false; notifyListeners(); return; }

      final att = await _storageBloc.uploadAttachmentBytes(
        contract: contract,
        adjustment: selectedAdjustment!,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current = List<Attachment>.from(selectedAdjustment?.attachments ?? const []);
      current.add(att);

      selectedAdjustment = selectedAdjustment!..attachments = current;
      await _adjustmentBloc.setAttachments(
        contractId: contract.id!,
        adjustmentId: selectedAdjustment!.id!,
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
      // 🔔 erro
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

  Future<void> handleEditLabelFile(int index) async {
    final a = selectedAdjustment;
    if (a == null || a.attachments == null || index < 0 || index >= a.attachments!.length) return;

    try {
      isSaving = true; notifyListeners();

      final att = a.attachments![index];
      final suggestion = att.label.isNotEmpty ? att.label : _defaultLabelFromOriginal(att.id);
      final newLabel = await _askLabel(_currentContext!, suggestion: suggestion);
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

      await _adjustmentBloc.setAttachments(
        contractId: contract.id!,
        adjustmentId: a.id!,
        attachments: a.attachments!,
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
          title: Text('Erro ao renomear: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleDeleteFile(int index) async {
    final a = selectedAdjustment;
    if (contract.id == null || a?.id == null) return;

    try {
      isSaving = true; notifyListeners();

      final atts = a!.attachments ?? [];
      if (atts.isNotEmpty && index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await _storageBloc.deleteStorageByPath(removed.path);
        }
        await _adjustmentBloc.setAttachments(
          contractId: contract.id!,
          adjustmentId: a.id!,
          attachments: atts,
        );
        selectedAdjustment = a..attachments = atts;
      } else if ((a.pdfUrl ?? '').isNotEmpty) {
        await _adjustmentBloc.salvarUrlPdfDaAdjustmentMeasurement(
          contractId: contract.id!,
          adjustmentId: a.id!,
          url: '',
        );
        selectedAdjustment = a..pdfUrl = null;
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
          title: Text('Erro ao remover: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  /// ⬇️ Abrir PDF internamente em dialog
  Future<void> handleOpenFile(BuildContext context, int index) async {
    final a = selectedAdjustment;
    if (a == null) return;

    String? url;
    if ((a.attachments ?? []).isNotEmpty) {
      final att = a.attachments![index];
      url = att.url;
      selectSideIndex(index);
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

  // legado upload (mantido)
  Future<void> uploadPdf({required void Function(double progress) onProgress}) async {
    if (contract.id == null || selectedAdjustment?.id == null) return;

    final url = await _storageBloc.uploadWithPicker(
      contract: contract,
      adj: selectedAdjustment!,
      adjustmentId: selectedAdjustment!.id!,
      onProgress: onProgress,
    );

    await _adjustmentBloc.salvarUrlPdfDaAdjustmentMeasurement(
      contractId: contract.id!,
      adjustmentId: selectedAdjustment!.id!,
      url: url,
    );

    selectedAdjustment = selectedAdjustment!..pdfUrl = url;
    await _refreshSideList();
  }

  BuildContext? _currentContext;
  void attachBuildContext(BuildContext context) { _currentContext = context; }

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateForm);
    orderCtrl.dispose(); processCtrl.dispose(); valueCtrl.dispose(); dateCtrl.dispose();
    super.dispose();
  }
}
