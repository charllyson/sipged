import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ necessário (ctx.read<UserBloc>())
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/pdf/pdf_preview.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/financial/payments/revision/payment_revision_bloc.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/payments_revisions_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/payment_revision_storage_bloc.dart';

// permissões
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/_blocs/system/permitions/module_permission.dart' as perms;

import 'package:sipged/_widgets/windows/show_window_dialog.dart';

class PaymentsRevisionController extends ChangeNotifier with SipGedValidation {
  PaymentsRevisionController({
    required PaymentRevisionBloc paymentRevisionBloc,
    required AdditivesRepository additivesRepository,
    PaymentRevisionStorageBloc? storageBloc,
  })  : _paymentRevisionBloc = paymentRevisionBloc,
        _additivesRepository = additivesRepository,
        _storageBloc = storageBloc ?? PaymentRevisionStorageBloc();

  // --- Dependências
  final PaymentRevisionBloc _paymentRevisionBloc;
  final AdditivesRepository _additivesRepository;
  final PaymentRevisionStorageBloc _storageBloc;

  // --- User stream
  StreamSubscription<UserState>? _userSub;

  // --- Contexto
  UserData? currentUser;
  ProcessData? contract;

  // valor da demanda (DFD) — você ainda não está carregando aqui
  final double _valorDemanda = 0.0;

  // --- Dados
  List<PaymentsRevisionsData> _revisions = <PaymentsRevisionsData>[];
  List<PaymentsRevisionsData> _lastSnapshot = <PaymentsRevisionsData>[];
  PaymentsRevisionsData? _selected;
  String? _currentId;

  // --- SideListBox (dinâmico: Attachment)
  List<dynamic> sideItems = const <dynamic>[];
  int? selectedSideIndex;

  bool get canAddFile => isEditable && _selected?.idRevisionPayment != null;

  // --- Estado UI
  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  // --- Totais
  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // --- Controllers
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

  // --- Getters
  List<PaymentsRevisionsData> get revisions => _revisions;
  PaymentsRevisionsData? get selected => _selected;
  String? get currentPaymentRevisionId => _currentId;

  List<String> get chartLabels =>
      _revisions.map((e) => (e.orderPaymentRevision ?? 0).toString()).toList();

  List<double> get chartValues =>
      _revisions.map((e) => e.valuePaymentRevision ?? 0.0).toList();

  double get totalMedicoes => chartValues.fold<double>(0.0, (a, b) => a + b);
  double get valorTotal => _valorInicial + _valorAditivos;
  double get saldo => valorTotal - totalMedicoes;

  double get valorInicialBase => _valorInicial;
  double get valorAditivosTotal => _valorAditivos;

  // permissões
  bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    return roles.roleForUser(u) == roles.UserProfile.administrador;
  }

  // ======= ORDENS: dropdown inteligente =======
  Set<int> get _existingOrders => _lastSnapshot
      .map((v) => v.orderPaymentRevision ?? 0)
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
    final maxPlusOne = set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  Set<String> get greyOrderItems => _existingOrders.map((e) => e.toString()).toSet();

  void onChangeOrderNumber(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    final idx =
    _lastSnapshot.indexWhere((x) => (x.orderPaymentRevision ?? -1) == picked);
    if (idx >= 0) {
      selectRow(_lastSnapshot[idx]); // existente → carrega
    } else {
      createNew(overrideOrder: picked); // livre → inicia novo
      notifyListeners();
    }
  }

  // ✅ usado pelo page/form para sincronizar mudanças locais do SideListBox (opcional)
  void setSideItemsLocal(List<dynamic> items, {int? selected}) {
    sideItems = items;
    selectedSideIndex = selected;
    notifyListeners();
  }

  // --- Init/Dispose
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

  // --- Permissão (módulo: payments_revision)
  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    if (roles.roleForUser(user) == roles.UserProfile.administrador) return true;

    final canEdit = perms.userCanModule(
      user: user,
      module: 'payments_revision',
      action: 'edit',
    );
    final canCreate = perms.userCanModule(
      user: user,
      module: 'payments_revision',
      action: 'create',
    );
    return canEdit || canCreate;
  }

  // --- Core
  Future<void> _loadInitial() async {
    if (contract?.id == null) return;

    // ✅ usa valorDemanda do DfdData (por enquanto é 0.0, você ainda não carrega aqui)
    _valorInicial = _valorDemanda;

    // ✅ usa repositório de aditivos no padrão novo
    _valorAditivos = await _additivesRepository.getAllAdditivesValue(contract!.id!);

    _revisions = await _paymentRevisionBloc.getAllReportPaymentsOfContract(
      contractId: contract!.id!,
    );

    _lastSnapshot = List<PaymentsRevisionsData>.from(_revisions);

    // define próxima ordem livre
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

  // --- Side list helpers (multi-anexos + migração de pdfUrl)
  Future<void> _refreshSideList() async {
    final p = _selected;

    if (p == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      return;
    }

    // 1) já tem attachments
    if ((p.attachments ?? const []).isNotEmpty) {
      sideItems = List<dynamic>.from(p.attachments!);
      selectedSideIndex = null;
      return;
    }

    // 2) migra pdfUrl legado → Attachment único
    if ((p.pdfUrl ?? '').isNotEmpty && p.idRevisionPayment != null && contract?.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento da revisão',
        url: p.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: currentUser?.uid,
      );

      await _paymentRevisionBloc.setAttachments(
        contractId: contract!.id!,
        revisionPaymentId: p.idRevisionPayment!,
        attachments: [att],
      );

      _selected = p
        ..attachments = [att]
        ..pdfUrl = null;

      sideItems = [att];
      selectedSideIndex = null;
      return;
    }

    // 3) materializa arquivos existentes no Storage
    if (contract?.id != null && p.idRevisionPayment != null) {
      final files = await _storageBloc.listarArquivosDaRevisao(
        contractId: contract!.id!,
        revisionPaymentId: p.idRevisionPayment!,
      );

      if (files.isNotEmpty) {
        final list = files
            .map(
              (f) => Attachment(
            id: f.name,
            label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
            url: f.url,
            path:
            'contracts/${contract!.id}/revisionPayments/${p.idRevisionPayment}/${f.name}',
            ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
                .firstMatch(f.name)
                ?.group(0) ??
                '',
            createdAt: DateTime.now(),
            createdBy: currentUser?.uid,
          ),
        )
            .toList();

        await _paymentRevisionBloc.setAttachments(
          contractId: contract!.id!,
          revisionPaymentId: p.idRevisionPayment!,
          attachments: list,
        );

        _selected = p..attachments = list;
        sideItems = List<dynamic>.from(list);
        selectedSideIndex = null;
        return;
      }
    }

    sideItems = const <dynamic>[];
    selectedSideIndex = null;
  }

  // --- Ações UI
  void selectRow(PaymentsRevisionsData data) {
    final idx = _revisions.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.idRevisionPayment;

    orderCtrl.text = (data.orderPaymentRevision ?? '').toString();
    processCtrl.text = data.processPaymentRevision ?? '';
    valueCtrl.text = SipGedFormatMoney.doubleToText(data.valuePaymentRevision);
    dateCtrl.text = data.datePaymentRevision != null
        ? SipGedFormatDates.dateToDdMMyyyy(data.datePaymentRevision!)
        : '';
    stateCtrl.text = data.statePaymentRevision ?? '';
    observationCtrl.text = data.observationPaymentRevision ?? '';
    bankCtrl.text = data.orderBankPaymentRevision ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentRevision ?? '';
    fontCtrl.text = data.fontPaymentRevision ?? '';
    taxCtrl.text = SipGedFormatMoney.doubleToText(data.taxPaymentRevision);

    _refreshSideList().then((_) => notifyListeners());
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

    _refreshSideList().then((_) => notifyListeners());
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

      final data = PaymentsRevisionsData(
        contractId: contract!.id!,
        idRevisionPayment: _currentId,
        orderPaymentRevision: int.tryParse(orderCtrl.text),
        processPaymentRevision: processCtrl.text,
        valuePaymentRevision: SipGedFormatMoney.parseBrl(valueCtrl.text),
        datePaymentRevision: SipGedFormatDates.ddMMyyyyToDate(dateCtrl.text),
        statePaymentRevision: stateCtrl.text,
        observationPaymentRevision: observationCtrl.text,
        orderBankPaymentRevision: bankCtrl.text,
        electronicTicketPaymentRevision: electronicTicketCtrl.text,
        fontPaymentRevision: fontCtrl.text,
        taxPaymentRevision: SipGedFormatMoney.parseBrl(taxCtrl.text),
        pdfUrl: _selected?.pdfUrl, // legado preservado
        attachments: _selected?.attachments, // mantém anexos numa edição
      );

      await _paymentRevisionBloc.saveOrUpdatePayment(data);

      _revisions = await _paymentRevisionBloc.getAllReportPaymentsOfContract(
        contractId: contract!.id!,
      );
      _lastSnapshot = List<PaymentsRevisionsData>.from(_revisions);

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
      PaymentsRevisionsData data, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final toSave = PaymentsRevisionsData(
        contractId: contract!.id!,
        idRevisionPayment: data.idRevisionPayment,
        orderPaymentRevision: data.orderPaymentRevision,
        processPaymentRevision: data.processPaymentRevision,
        valuePaymentRevision: data.valuePaymentRevision,
        datePaymentRevision: data.datePaymentRevision,
        statePaymentRevision: data.statePaymentRevision,
        observationPaymentRevision: data.observationPaymentRevision,
        orderBankPaymentRevision: data.orderBankPaymentRevision,
        electronicTicketPaymentRevision: data.electronicTicketPaymentRevision,
        fontPaymentRevision: data.fontPaymentRevision,
        taxPaymentRevision: data.taxPaymentRevision,
        pdfUrl: data.pdfUrl,
        attachments: data.attachments,
      );

      await _paymentRevisionBloc.saveOrUpdatePayment(toSave);

      _revisions = await _paymentRevisionBloc.getAllReportPaymentsOfContract(
        contractId: contract!.id!,
      );
      _lastSnapshot = List<PaymentsRevisionsData>.from(_revisions);

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
      String idPaymentRevision, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;

    try {
      await _paymentRevisionBloc.deletarPayment(contract!.id!, idPaymentRevision);

      _revisions = await _paymentRevisionBloc.getAllReportPaymentsOfContract(
        contractId: contract!.id!,
      );
      _lastSnapshot = List<PaymentsRevisionsData>.from(_revisions);

      selectedIndex = null;
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      notifyListeners();
    }
  }

  // ---------- Anexos (SideListBox) ----------
  String _suggestLabelFromName(String original) {
    final base =
    original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = _selected?.orderPaymentRevision ?? 0;
    return 'Revisão $ord - $base';
  }

  Future<void> handleAddFile(BuildContext context) async {
    final p = _selected;

    if (!canAddFile ||
        contract?.id == null ||
        p?.idRevisionPayment == null ||
        p == null) {
      return;
    }

    try {
      isSaving = true;
      notifyListeners();

      final (Uint8List bytes, String originalName) = await _storageBloc.pickFileBytes();

      final suggestion = _suggestLabelFromName(originalName);
      final label = await askLabelDialog(context, suggestion);
      if (label == null) return;

      final att = await _storageBloc.uploadAttachmentBytes(
        contract: contract!,
        payment: p,
        bytes: bytes,
        originalName: originalName,
        label: label.isEmpty ? suggestion : label,
      );

      final current = List<Attachment>.from(p.attachments ?? const []);
      current.add(att);

      await _paymentRevisionBloc.setAttachments(
        contractId: contract!.id!,
        revisionPaymentId: p.idRevisionPayment!,
        attachments: current,
      );

      _selected = p..attachments = current;
      await _refreshSideList();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// ✅ NOVO: persistência de rename (com rollback)
  Future<bool> handleRenamePersist({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final p = _selected;
    if (p == null ||
        contract?.id == null ||
        p.idRevisionPayment == null ||
        p.attachments == null ||
        index < 0 ||
        index >= p.attachments!.length) {
      return false;
    }

    // garante que o item é o mesmo
    if (p.attachments![index].id != oldItem.id) {
      // tenta achar pelo id (caso reordene)
      final realIndex = p.attachments!.indexWhere((a) => a.id == oldItem.id);
      if (realIndex < 0) return false;
      index = realIndex;
    }

    try {
      isSaving = true;
      notifyListeners();

      final updated = Attachment(
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

      final next = List<Attachment>.from(p.attachments!);
      next[index] = updated;

      await _paymentRevisionBloc.setAttachments(
        contractId: contract!.id!,
        revisionPaymentId: p.idRevisionPayment!,
        attachments: next,
      );

      _selected = p..attachments = next;
      sideItems = List<dynamic>.from(next);
      selectedSideIndex = index;

      return true;
    } catch (_) {
      // rollback local
      final next = List<Attachment>.from(p.attachments!);
      next[index] = oldItem;

      _selected = p..attachments = next;
      sideItems = List<dynamic>.from(next);
      selectedSideIndex = index;

      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleDeleteFile(int index, BuildContext context) async {
    final p = _selected;
    if (p == null || p.idRevisionPayment == null || contract?.id == null) return;

    try {
      isSaving = true;
      notifyListeners();

      final atts = List<Attachment>.from(p.attachments ?? const []);
      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if ((removed.path).isNotEmpty) {
          await _storageBloc.deleteStorageByPath(removed.path);
        }
        await _paymentRevisionBloc.setAttachments(
          contractId: contract!.id!,
          revisionPaymentId: p.idRevisionPayment!,
          attachments: atts,
        );
        _selected = p..attachments = atts;
      } else if ((p.pdfUrl ?? '').isNotEmpty) {
        await _paymentRevisionBloc.salvarUrlPdfDePayment(
          contractId: contract!.id!,
          paymentId: p.idRevisionPayment!,
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
      url = p.attachments![index].url;
      selectedSideIndex = index;
      notifyListeners();
    } else {
      url = p.pdfUrl; // legado
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
