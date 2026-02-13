import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/modules/financial/payments/adjustment/payment_adjustment_storage_bloc.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/pdf/pdf_preview.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/_blocs/system/permitions/module_permission.dart' as perms;
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

class PaymentsAdjustmentController extends ChangeNotifier
    with SipGedValidation {
  PaymentsAdjustmentController({
    required PaymentAdjustmentBloc paymentAdjustmentBloc,
    required AdditivesRepository additivesRepository,
    PaymentAdjustmentStorageBloc? storageBloc,
  })  : _paymentAdjustmentBloc = paymentAdjustmentBloc,
        _additivesRepository = additivesRepository,
        _storageBloc = storageBloc ?? PaymentAdjustmentStorageBloc();

  final PaymentAdjustmentBloc _paymentAdjustmentBloc;
  final AdditivesRepository _additivesRepository;
  final PaymentAdjustmentStorageBloc _storageBloc;

  StreamSubscription<UserState>? _userSub;

  PaymentAdjustmentBloc get bloc => _paymentAdjustmentBloc;

  UserData? currentUser;
  ProcessData? contract;

  List<PaymentsAdjustmentsData> _payments = <PaymentsAdjustmentsData>[];
  List<PaymentsAdjustmentsData> _lastSnapshot = <PaymentsAdjustmentsData>[];

  PaymentsAdjustmentsData? _selected;
  String? _currentId;

  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  final double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // SideListBox (String | Attachment)
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;
  bool get canAddFile => isEditable && _selected?.idPaymentAdjustment != null;

  // controllers
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

  List<PaymentsAdjustmentsData> get payments => _payments;
  PaymentsAdjustmentsData? get selected => _selected;
  String? get currentPaymentAdjustmentId => _currentId;

  List<String> get chartLabels =>
      _payments.map((e) => (e.orderPaymentAdjustment ?? 0).toString()).toList();
  List<double> get chartValues =>
      _payments.map((e) => e.valuePaymentAdjustment ?? 0.0).toList();

  double get totalMedicoes => chartValues.fold<double>(0.0, (a, b) => a + b);
  double get valorTotal => _valorInicial + _valorAditivos;
  double get saldo => valorTotal - totalMedicoes;
  double get valorInicialBase => _valorInicial;
  double get valorAditivosTotal => _valorAditivos;

  bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    return roles.roleForUser(u) == roles.UserProfile.ADMINISTRADOR;
  }

  // ======= ORDENS (dropdown inteligente) =======
  Set<int> get _existingOrders => _lastSnapshot
      .map((v) => v.orderPaymentAdjustment ?? 0)
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
        .indexWhere((x) => (x.orderPaymentAdjustment ?? -1) == picked);
    if (idx >= 0) {
      selectRow(_lastSnapshot[idx]);
    } else {
      createNew(overrideOrder: picked);
      notifyListeners();
    }
  }

  Future<void> init(
      BuildContext context, {
        required ProcessData? contractData,
      }) async {
    contract = contractData;
    if (contract?.id == null) return;

    final userBloc = context.read<UserBloc>();
    currentUser = userBloc.state.current;
    isEditable = _canEditUser(currentUser);

    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
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
    if (roles.roleForUser(user) == roles.UserProfile.ADMINISTRADOR) return true;

    final canEdit = perms.userCanModule(
      user: user,
      module: 'payments_adjustment',
      action: 'edit',
    );
    final canCreate = perms.userCanModule(
      user: user,
      module: 'payments_adjustment',
      action: 'create',
    );
    return canEdit || canCreate;
  }

  Future<void> _loadInitial() async {
    if (contract?.id == null) return;

    _valorAditivos =
    await _additivesRepository.getAllAdditivesValue(contract!.id!);

    _payments = await _paymentAdjustmentBloc
        .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);

    _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

    final next = _nextAvailableOrder(_existingOrders);
    orderCtrl.text = '$next';

    await _refreshSideList(notify: false);
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

  void selectRow(PaymentsAdjustmentsData data) {
    final idx = _payments.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.idPaymentAdjustment;

    orderCtrl.text = (data.orderPaymentAdjustment ?? '').toString();
    processCtrl.text = data.processPaymentAdjustment ?? '';
    valueCtrl.text =
        SipGedFormatMoney.doubleToText(data.valuePaymentAdjustment);
    dateCtrl.text = data.datePaymentAdjustment != null
        ? SipGedFormatDates.dateToDdMMyyyy(data.datePaymentAdjustment!)
        : '';
    stateCtrl.text = data.statePaymentAdjustment ?? '';
    observationCtrl.text = data.observationPaymentAdjustment ?? '';
    bankCtrl.text = data.orderBankPaymentAdjustment ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentAdjustment ?? '';
    fontCtrl.text = data.fontPaymentAdjustment ?? '';
    taxCtrl.text = SipGedFormatMoney.doubleToText(data.taxPaymentAdjustment);

    _refreshSideList(notify: true);
  }

  void createNew({int? overrideOrder}) {
    selectedIndex = null;
    _selected = null;
    _currentId = null;

    if (overrideOrder != null && overrideOrder > 0) {
      orderCtrl.text = '$overrideOrder';
    } else if (orderCtrl.text.trim().isEmpty) {
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

    _refreshSideList(notify: true);
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

      final data = PaymentsAdjustmentsData(
        idPaymentAdjustment: _currentId,
        contractId: contract!.id!,
        orderPaymentAdjustment: int.tryParse(orderCtrl.text),
        processPaymentAdjustment: processCtrl.text,
        valuePaymentAdjustment: SipGedFormatMoney.parseBrl(valueCtrl.text),
        datePaymentAdjustment: SipGedFormatDates.ddMMyyyyToDate(dateCtrl.text),
        statePaymentAdjustment: stateCtrl.text,
        observationPaymentAdjustment: observationCtrl.text,
        orderBankPaymentAdjustment: bankCtrl.text,
        electronicTicketPaymentAdjustment: electronicTicketCtrl.text,
        fontPaymentAdjustment: fontCtrl.text,
        taxPaymentAdjustment: SipGedFormatMoney.parseBrl(taxCtrl.text),
        pdfUrl: _selected?.pdfUrl,
        attachments: _selected?.attachments,
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(data);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);
      _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

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
      PaymentsAdjustmentsData data, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final toSave = PaymentsAdjustmentsData(
        idPaymentAdjustment: data.idPaymentAdjustment,
        contractId: contract!.id!,
        orderPaymentAdjustment: data.orderPaymentAdjustment,
        processPaymentAdjustment: data.processPaymentAdjustment,
        valuePaymentAdjustment: data.valuePaymentAdjustment,
        datePaymentAdjustment: data.datePaymentAdjustment,
        statePaymentAdjustment: data.statePaymentAdjustment,
        observationPaymentAdjustment: data.observationPaymentAdjustment,
        orderBankPaymentAdjustment: data.orderBankPaymentAdjustment,
        electronicTicketPaymentAdjustment: data.electronicTicketPaymentAdjustment,
        fontPaymentAdjustment: data.fontPaymentAdjustment,
        taxPaymentAdjustment: data.taxPaymentAdjustment,
        pdfUrl: data.pdfUrl,
        attachments: data.attachments,
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(toSave);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);
      _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

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
      String idPaymentAdjustment, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;
    try {
      await _paymentAdjustmentBloc.deletarPayment(
        contract!.id!,
        idPaymentAdjustment,
      );
      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);
      _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

      selectedIndex = null;
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      notifyListeners();
    }
  }

  // ====== SideList (anexos) ======

  String _suggestLabelFromName(String original) {
    final base =
    original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = _selected?.orderPaymentAdjustment ?? 0;
    return 'Reajuste $ord - $base';
  }

  /// ✅ ÚNICO ponto que "materializa" a sideItems do selected
  Future<void> _refreshSideList({required bool notify}) async {
    final v = _selected;

    if (v == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      if (notify) notifyListeners();
      return;
    }

    // 1) attachments já existem no doc
    final existing = v.attachments ?? const <Attachment>[];
    if (existing.isNotEmpty) {
      sideItems = List<dynamic>.from(existing);
      selectedSideIndex = null;
      if (notify) notifyListeners();
      return;
    }

    // 2) migra pdfUrl legado -> vira attachment e zera pdfUrl
    if ((v.pdfUrl ?? '').isNotEmpty &&
        v.idPaymentAdjustment != null &&
        contract?.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento do reajuste',
        url: v.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: currentUser?.uid,
      );

      await _paymentAdjustmentBloc.setAttachments(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
        attachments: [att],
      );

      _selected = v
        ..attachments = [att]
        ..pdfUrl = null;

      sideItems = [att];
      selectedSideIndex = null;
      if (notify) notifyListeners();
      return;
    }

    // 3) materializa arquivos do Storage (se houver) e salva como attachments
    if (contract?.id != null && v.idPaymentAdjustment != null) {
      final files = await _storageBloc.listarArquivosDoPagamento(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
      );

      if (files.isNotEmpty) {
        final list = files
            .map(
              (f) => Attachment(
            id: f.name,
            label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
            url: f.url,
            path:
            'contracts/${contract!.id}/adjustmentPayments/${v.idPaymentAdjustment}/${f.name}',
            ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
                .firstMatch(f.name)
                ?.group(0) ??
                '',
            createdAt: DateTime.now(),
            createdBy: currentUser?.uid,
          ),
        )
            .toList();

        await _paymentAdjustmentBloc.setAttachments(
          contractId: contract!.id!,
          paymentAdjustmentId: v.idPaymentAdjustment!,
          attachments: list,
        );

        _selected = v..attachments = list;
        sideItems = List<dynamic>.from(list);
        selectedSideIndex = null;
        if (notify) notifyListeners();
        return;
      }
    }

    sideItems = const <dynamic>[];
    selectedSideIndex = null;
    if (notify) notifyListeners();
  }

  Future<void> handleAddFile(BuildContext context) async {
    final v = _selected;
    if (!canAddFile ||
        contract?.id == null ||
        v?.idPaymentAdjustment == null ||
        v == null) {
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
        payment: v,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current = List<Attachment>.from(v.attachments ?? const []);
      current.add(att);

      await _paymentAdjustmentBloc.setAttachments(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
        attachments: current,
      );

      _selected = v..attachments = current;
      await _refreshSideList(notify: false);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// ✅ NOVO: persistência do rename vindo do SideListBox
  /// Retorna true/false para o widget manter/reverter
  Future<bool> handleRenamePersist({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final v = _selected;
    if (v == null ||
        contract?.id == null ||
        v.idPaymentAdjustment == null) {
      return false;
    }

    final atts = List<Attachment>.from(v.attachments ?? const []);
    if (index < 0 || index >= atts.length) return false;

    try {
      // Só atualiza metadados (label); NÃO mexe no storage
      atts[index] = Attachment(
        id: oldItem.id,
        label: newItem.label,
        url: oldItem.url,
        path: oldItem.path,
        ext: oldItem.ext,
        size: oldItem.size,
        createdAt: oldItem.createdAt,
        createdBy: oldItem.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: currentUser?.uid,
      );

      await _paymentAdjustmentBloc.setAttachments(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
        attachments: atts,
      );

      _selected = v..attachments = atts;
      await _refreshSideList(notify: false);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ✅ NOVO: mantém controller sincronizado quando SideListBox altera a lista
  /// (por exemplo, rename otimista já aplicado)
  void syncSideItemsFromWidget(List<dynamic> newItems) {
    sideItems = List<dynamic>.from(newItems);

    final v = _selected;
    if (v != null) {
      final onlyAtt = newItems.whereType<Attachment>().toList();
      v.attachments = onlyAtt;
      _selected = v;
    }

    notifyListeners();
  }

  Future<void> handleDeleteFile(int index, BuildContext context) async {
    final v = _selected;
    if (v == null ||
        v.idPaymentAdjustment == null ||
        contract?.id == null) {
      return;
    }

    try {
      isSaving = true;
      notifyListeners();

      final atts = List<Attachment>.from(v.attachments ?? const []);
      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await _storageBloc.deleteStorageByPath(removed.path);
        }
        await _paymentAdjustmentBloc.setAttachments(
          contractId: contract!.id!,
          paymentAdjustmentId: v.idPaymentAdjustment!,
          attachments: atts,
        );
        _selected = v..attachments = atts;
      } else if ((v.pdfUrl ?? '').isNotEmpty) {
        await _paymentAdjustmentBloc.salvarUrlPdfDePayment(
          contractId: contract!.id!,
          paymentId: v.idPaymentAdjustment!,
          url: '',
        );
        _selected = v..pdfUrl = null;
      }

      await _refreshSideList(notify: false);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleOpenFile(BuildContext context, int index) async {
    final v = _selected;
    if (v == null) return;

    String? url;
    final atts = v.attachments ?? const <Attachment>[];

    if (atts.isNotEmpty) {
      if (index < 0 || index >= atts.length) return;
      url = atts[index].url;
      selectedSideIndex = index;
      notifyListeners();
    } else {
      url = v.pdfUrl; // legado
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
}
