import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/payment_reports_bloc.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/payments_reports_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/payments_report_storage_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/_blocs/system/permitions/module_permission.dart' as perms;

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_services/pdf/pdf_preview.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class PaymentsReportController extends ChangeNotifier with SipGedValidation {
  PaymentsReportController({
    required PaymentReportBloc paymentReportBloc,
    required AdditivesRepository additivesRepository,
    PaymentsReportStorageBloc? storageBloc,
  })  : _paymentReportBloc = paymentReportBloc,
        _additivesRepository = additivesRepository,
        _storageBloc = storageBloc ?? PaymentsReportStorageBloc();

  final PaymentReportBloc _paymentReportBloc;
  final AdditivesRepository _additivesRepository;
  final PaymentsReportStorageBloc _storageBloc;

  StreamSubscription<UserState>? _userSub;

  UserData? currentUser;
  ProcessData? contract;

  final double _valorDemanda = 0.0;

  List<PaymentsReportData> _reports = <PaymentsReportData>[];
  List<PaymentsReportData> _lastSnapshot = <PaymentsReportData>[];
  PaymentsReportData? _selected;
  String? _currentId;

  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final observationCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final electronicTicketCtrl = TextEditingController();
  final fontCtrl = TextEditingController();
  final taxCtrl = TextEditingController();

  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;

  bool get canAddFile => isEditable && _selected?.idPaymentReport != null;

  List<PaymentsReportData> get reports => _reports;
  PaymentsReportData? get selected => _selected;
  String? get currentPaymentReportId => _currentId;

  List<String> get chartLabels =>
      _reports.map((e) => (e.orderPaymentReport ?? 0).toString()).toList();

  List<double> get chartValues =>
      _reports.map((e) => e.valuePaymentReport ?? 0.0).toList();

  double get totalMedicoes => chartValues.fold<double>(0.0, (a, b) => a + b);
  double get valorTotal => _valorInicial + _valorAditivos;
  double get saldo => valorTotal - totalMedicoes;

  bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    return roles.roleForUser(u) == roles.UserProfile.administrador;
  }

  Set<int> get _existingOrders => _lastSnapshot
      .map((v) => v.orderPaymentReport ?? 0)
      .where((n) => n > 0)
      .toSet();

  int _nextAvailableOrder(Set<int> set) {
    if (set.isEmpty) return 1;
    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }
    final max = set.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  List<String> get orderNumberOptions {
    final set = _existingOrders;
    final maxPlusOne =
    set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  Set<String> get greyOrderItems =>
      _existingOrders.map((e) => e.toString()).toSet();

  void onChangeOrderNumber(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    final idx = _lastSnapshot
        .indexWhere((x) => (x.orderPaymentReport ?? -1) == picked);
    if (idx >= 0) {
      selectRow(_lastSnapshot[idx]);
    } else {
      createNew();
      orderCtrl.text = '$picked';
      notifyListeners();
    }
  }

  Future<void> init(
      BuildContext context, {
        required ProcessData? contractData,
      }) async {
    contract = contractData;
    if (contract?.id == null) return;

    final userCubit = context.read<UserCubit>();
    currentUser = userCubit.state.current;
    isEditable = _canEditUser(currentUser);

    _userSub?.cancel();
    _userSub = userCubit.stream.listen((st) {
      final prevId = currentUser?.uid;
      currentUser = st.current;
      final nowId = currentUser?.uid;

      final newEditable = _canEditUser(currentUser);
      if (newEditable != isEditable || prevId != nowId) {
        isEditable = newEditable;
        notifyListeners();
      }
    });

    setupValidation(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl],
      _validateFormInternal,
    );
    await _loadInitial();
  }

  @override
  void dispose() {
    _userSub?.cancel();

    removeValidation(
      [
        orderCtrl,
        processCtrl,
        valueCtrl,
        dateCtrl,
        stateCtrl,
        observationCtrl,
        bankCtrl,
        electronicTicketCtrl,
        fontCtrl,
        taxCtrl,
      ],
      _validateFormInternal,
    );

    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    stateCtrl.dispose();
    observationCtrl.dispose();
    bankCtrl.dispose();
    electronicTicketCtrl.dispose();
    fontCtrl.dispose();
    taxCtrl.dispose();
    super.dispose();
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;

    if (roles.roleForUser(user) == roles.UserProfile.administrador) return true;

    final canEdit = perms.userCanModule(
      user: user,
      module: 'payments_report',
      action: 'edit',
    );
    final canCreate = perms.userCanModule(
      user: user,
      module: 'payments_report',
      action: 'create',
    );
    return canEdit || canCreate;
  }

  Future<void> _loadInitial() async {
    if (contract?.id == null) return;

    _valorInicial = _valorDemanda;
    _valorAditivos =
    await _additivesRepository.getAllAdditivesValue(contract!.id!);

    _reports = await _paymentReportBloc
        .getAllReportPaymentsOfContract(contractId: contract!.id!);

    _lastSnapshot = List<PaymentsReportData>.from(_reports);

    final next = _nextAvailableOrder(_existingOrders);
    orderCtrl.text = '$next';

    await _refreshSideList();
    notifyListeners();
  }

  void _validateFormInternal() {
    final valid = areFieldsFilled(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl],
      minLength: 1,
    );
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  void selectRow(PaymentsReportData data) {
    final idx = _reports.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.idPaymentReport;

    orderCtrl.text = (data.orderPaymentReport ?? '').toString();
    processCtrl.text = data.processPaymentReport ?? '';
    valueCtrl.text = SipGedFormatMoney.doubleToText(data.valuePaymentReport);
    dateCtrl.text = data.datePaymentReport != null
        ? SipGedFormatDates.dateToDdMMyyyy(data.datePaymentReport!)
        : '';
    stateCtrl.text = data.statePaymentReport ?? '';
    observationCtrl.text = data.observationPaymentReport ?? '';
    bankCtrl.text = data.orderBankPaymentReport ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentReport ?? '';
    fontCtrl.text = data.fontPaymentReport ?? '';
    taxCtrl.text = SipGedFormatMoney.doubleToText(data.taxPaymentReport);

    _refreshSideList();
    notifyListeners();
  }

  void createNew() {
    selectedIndex = null;
    _selected = null;
    _currentId = null;

    if (orderCtrl.text.trim().isEmpty) {
      final next = _nextAvailableOrder(_existingOrders);
      orderCtrl.text = '$next';
    }

    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();
    stateCtrl.clear();
    observationCtrl.clear();
    bankCtrl.clear();
    electronicTicketCtrl.clear();
    fontCtrl.clear();
    taxCtrl.clear();

    _refreshSideList();
    notifyListeners();
  }

  Future<bool> saveOrUpdate({
    required Future<bool> Function() onConfirm,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    if (contract?.id == null) return false;

    final confirmed = await onConfirm();
    if (!confirmed) return false;

    try {
      isSaving = true;
      notifyListeners();

      final data = PaymentsReportData(
        idPaymentReport: _currentId,
        contractId: contract!.id!,
        orderPaymentReport: int.tryParse(orderCtrl.text),
        processPaymentReport: processCtrl.text,
        valuePaymentReport: SipGedFormatMoney.parseBrl(valueCtrl.text),
        datePaymentReport: SipGedFormatDates.ddMMyyyyToDate(dateCtrl.text),
        statePaymentReport: stateCtrl.text,
        observationPaymentReport: observationCtrl.text,
        orderBankPaymentReport: bankCtrl.text,
        electronicTicketPaymentReport: electronicTicketCtrl.text,
        fontPaymentReport: fontCtrl.text,
        taxPaymentReport: SipGedFormatMoney.parseBrl(taxCtrl.text),
        pdfUrl: _selected?.pdfUrl,
        attachments: _selected?.attachments,
      );

      await _paymentReportBloc.saveOrUpdatePayment(data);
      _reports = await _paymentReportBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);

      _lastSnapshot = List<PaymentsReportData>.from(_reports);

      createNew();
      onSuccess?.call();
      return true;
    } catch (_) {
      onError?.call();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveExact(
      PaymentsReportData data, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;
    try {
      isSaving = true;
      notifyListeners();

      final toSave = PaymentsReportData(
        idPaymentReport: data.idPaymentReport,
        contractId: contract!.id!,
        orderPaymentReport: data.orderPaymentReport,
        processPaymentReport: data.processPaymentReport,
        valuePaymentReport: data.valuePaymentReport,
        datePaymentReport: data.datePaymentReport,
        statePaymentReport: data.statePaymentReport,
        observationPaymentReport: data.observationPaymentReport,
        orderBankPaymentReport: data.orderBankPaymentReport,
        electronicTicketPaymentReport: data.electronicTicketPaymentReport,
        fontPaymentReport: data.fontPaymentReport,
        taxPaymentReport: data.taxPaymentReport,
        pdfUrl: data.pdfUrl,
        attachments: data.attachments,
      );

      await _paymentReportBloc.saveOrUpdatePayment(toSave);
      _reports = await _paymentReportBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);

      _lastSnapshot = List<PaymentsReportData>.from(_reports);

      createNew();
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteById(
      String idPaymentReport, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;
    try {
      await _paymentReportBloc.deletarPayment(
        contract!.id!,
        idPaymentReport,
      );
      _reports = await _paymentReportBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);
      _lastSnapshot = List<PaymentsReportData>.from(_reports);
      selectedIndex = null;
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _refreshSideList() async {
    final p = _selected;
    if (p == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      if (hasListeners) notifyListeners();
      return;
    }

    if ((p.attachments ?? const []).isNotEmpty) {
      sideItems = List<dynamic>.from(p.attachments!);
      selectedSideIndex = null;
      if (hasListeners) notifyListeners();
      return;
    }

    if ((p.pdfUrl ?? '').isNotEmpty &&
        p.idPaymentReport != null &&
        contract?.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento do pagamento',
        url: p.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: currentUser?.uid,
      );
      await _paymentReportBloc.setAttachments(
        contractId: contract!.id!,
        paymentId: p.idPaymentReport!,
        attachments: [att],
      );
      _selected = p
        ..attachments = [att]
        ..pdfUrl = null;
      sideItems = [att];
      selectedSideIndex = null;
      if (hasListeners) notifyListeners();
      return;
    }

    if (contract?.id != null && p.idPaymentReport != null) {
      final files = await _storageBloc.listarArquivosDoPagamento(
        contractId: contract!.id!,
        paymentId: p.idPaymentReport!,
      );
      if (files.isNotEmpty) {
        final list = files
            .map(
              (f) => Attachment(
            id: f.name,
            label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
            url: f.url,
            path: 'contracts/${contract!.id}/payments/${p.idPaymentReport}/${f.name}',
            ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
                .firstMatch(f.name)
                ?.group(0) ??
                '',
            createdAt: DateTime.now(),
            createdBy: currentUser?.uid,
          ),
        )
            .toList();
        await _paymentReportBloc.setAttachments(
          contractId: contract!.id!,
          paymentId: p.idPaymentReport!,
          attachments: list,
        );
        _selected = p..attachments = list;
        sideItems = List<dynamic>.from(list);
        selectedSideIndex = null;
        if (hasListeners) notifyListeners();
        return;
      }
    }

    sideItems = const <dynamic>[];
    selectedSideIndex = null;
    if (hasListeners) notifyListeners();
  }

  String _suggestLabelFromName(String original) {
    final base =
    original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = _selected?.orderPaymentReport ?? 0;
    return 'Pagamento $ord - $base';
  }

  Future<void> handleAddFile(BuildContext context) async {
    if (!canAddFile ||
        contract?.id == null ||
        _selected?.idPaymentReport == null) {
      return;
    }

    try {
      isSaving = true;
      notifyListeners();

      final (Uint8List bytes, String originalName) =
      await _storageBloc.pickFileBytes();

      final suggestion = _suggestLabelFromName(originalName);
      final label = await askLabelDialog(context, suggestion);
      if (label == null) {
        isSaving = false;
        notifyListeners();
        return;
      }

      final att = await _storageBloc.uploadAttachmentBytes(
        contract: contract!,
        payment: _selected!,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current =
      List<Attachment>.from(_selected?.attachments ?? const []);
      current.add(att);

      await _paymentReportBloc.setAttachments(
        contractId: contract!.id!,
        paymentId: _selected!.idPaymentReport!,
        attachments: current,
      );

      _selected = _selected!..attachments = current;
      await _refreshSideList();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleEditLabelFile(
      int index,
      BuildContext context,
      ) async {
    final p = _selected;
    if (p == null ||
        p.attachments == null ||
        index < 0 ||
        index >= p.attachments!.length) {
      return;
    }

    try {
      isSaving = true;
      notifyListeners();

      final att = p.attachments![index];
      final suggestion =
      att.label.isNotEmpty ? att.label : _suggestLabelFromName(att.id);
      final newLabel = await askLabelDialog(context, suggestion);
      if (newLabel == null) {
        isSaving = false;
        notifyListeners();
        return;
      }

      p.attachments![index] = Attachment(
        id: att.id,
        label: newLabel.isEmpty ? suggestion : newLabel,
        url: att.url,
        path: att.path,
        ext: att.ext,
        size: att.size,
        createdAt: att.createdAt,
        createdBy: att.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: currentUser?.uid,
      );

      await _paymentReportBloc.setAttachments(
        contractId: contract!.id!,
        paymentId: p.idPaymentReport!,
        attachments: p.attachments!,
      );

      await _refreshSideList();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleDeleteFile(
      int index,
      BuildContext context,
      ) async {
    final p = _selected;
    if (p == null || p.idPaymentReport == null || contract?.id == null) {
      return;
    }

    try {
      isSaving = true;
      notifyListeners();

      final atts = List<Attachment>.from(p.attachments ?? const []);
      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if (removed.path.isNotEmpty) {
          await _storageBloc.deleteStorageByPath(removed.path);
        }
        await _paymentReportBloc.setAttachments(
          contractId: contract!.id!,
          paymentId: p.idPaymentReport!,
          attachments: atts,
        );
        _selected = p..attachments = atts;
      } else if ((p.pdfUrl ?? '').isNotEmpty) {
        await _paymentReportBloc.salvarUrlPdfDePayment(
          contractId: contract!.id!,
          paymentId: p.idPaymentReport!,
          url: '',
        );
        _selected = p..pdfUrl = null;
      }

      await _refreshSideList();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleOpenFile(BuildContext context, int index) async {
    final p = _selected;
    if (p == null) return;

    String? url;
    if ((p.attachments ?? []).isNotEmpty) {
      if (index < 0 || index >= p.attachments!.length) return;
      final att = p.attachments![index];
      url = att.url;
      selectedSideIndex = index;
      notifyListeners();
    } else {
      url = p.pdfUrl;
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

  Future<void> savePdfUrl(String url) async {
    if (_selected?.idPaymentReport == null || contract?.id == null) return;
    await _paymentReportBloc.salvarUrlPdfDePayment(
      contractId: contract!.id!,
      paymentId: _selected!.idPaymentReport!,
      url: url,
    );
    _selected = _selected!..pdfUrl = url;
    await _refreshSideList();
  }

  void setSideItems(List<dynamic> newItems) {
    sideItems = List<dynamic>.from(newItems);

    final p = _selected;
    if (p != null) {
      final atts = _extractAttachments(newItems);
      if (atts != null) {
        p.attachments = atts;
      }
    }

    notifyListeners();
  }

  Future<bool> persistRenameAttachment({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final p = _selected;
    final cId = contract?.id;

    if (p == null) return false;
    if (cId == null || cId.isEmpty) return false;
    if (p.idPaymentReport == null || p.idPaymentReport!.isEmpty) return false;

    final current = List<Attachment>.from(p.attachments ?? const []);

    int resolvedIndex = (index >= 0 && index < current.length) ? index : -1;
    if (resolvedIndex == -1) {
      resolvedIndex = current.indexWhere(
            (a) => a.id == oldItem.id || (a.url.isNotEmpty && a.url == oldItem.url),
      );
    }
    if (resolvedIndex == -1) return false;

    final updated = Attachment(
      id: current[resolvedIndex].id,
      label: newItem.label,
      url: current[resolvedIndex].url,
      path: current[resolvedIndex].path,
      ext: current[resolvedIndex].ext,
      size: current[resolvedIndex].size,
      createdAt: current[resolvedIndex].createdAt,
      createdBy: current[resolvedIndex].createdBy,
      updatedAt: DateTime.now(),
      updatedBy: currentUser?.uid,
    );

    current[resolvedIndex] = updated;

    try {
      await _paymentReportBloc.setAttachments(
        contractId: cId,
        paymentId: p.idPaymentReport!,
        attachments: current,
      );

      p.attachments = current;
      sideItems = List<dynamic>.from(current);

      if (selectedSideIndex != null && selectedSideIndex == index) {
        selectedSideIndex = resolvedIndex;
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Attachment>? _extractAttachments(List<dynamic> items) {
    if (items.isEmpty) return <Attachment>[];
    for (final it in items) {
      if (it is! Attachment) return null;
    }
    return items.cast<Attachment>().toList();
  }
}