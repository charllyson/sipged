import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_services/pdf/pdf_preview.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';

import 'package:siged/_utils/formats/date_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

class PaymentsAdjustmentController extends ChangeNotifier with FormValidationMixin {
  PaymentsAdjustmentController({
    required PaymentAdjustmentBloc paymentAdjustmentBloc,
    required AdditivesBloc additivesBloc,
    PaymentAdjustmentStorageBloc? storageBloc,
  })  : _paymentAdjustmentBloc = paymentAdjustmentBloc,
        _additivesBloc = additivesBloc,
        _storageBloc = storageBloc ?? PaymentAdjustmentStorageBloc();

  final PaymentAdjustmentBloc _paymentAdjustmentBloc;
  final AdditivesBloc _additivesBloc;
  final PaymentAdjustmentStorageBloc _storageBloc;

  StreamSubscription<UserState>? _userSub;

  PaymentAdjustmentBloc get bloc => _paymentAdjustmentBloc;

  UserData? currentUser;
  ProcessData? contract;

  List<PaymentsAdjustmentsData> _payments = <PaymentsAdjustmentsData>[];
  // 🆕 snapshot para suporte ao dropdown inteligente
  List<PaymentsAdjustmentsData> _lastSnapshot = <PaymentsAdjustmentsData>[];

  PaymentsAdjustmentsData? _selected;
  String? _currentId;

  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // SideListBox (agora dinâmico: String | Attachment)
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
    return roles.roleForUser(u) == roles.BaseRole.ADMINISTRADOR;
  }

  // ======= ORDENS: dropdown inteligente (espelha o módulo de pagamentos) =======
  Set<int> get _existingOrders =>
      _lastSnapshot.map((v) => v.orderPaymentAdjustment ?? 0).where((n) => n > 0).toSet();

  int _nextAvailableOrder(Set<int> set) {
    if (set.isEmpty) return 1;
    // primeiro buraco entre 1..N
    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }
    // se não houver buraco, segue após o máximo
    final max = set.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  /// Opções mostradas no dropdown (1 .. maxExistente+1)
  List<String> get orderNumberOptions {
    final set = _existingOrders;
    final maxPlusOne =
    set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  /// Itens em cinza (já usados)
  Set<String> get greyOrderItems =>
      _existingOrders.map((e) => e.toString()).toSet();

  /// Clique num item do dropdown
  void onChangeOrderNumber(String? v) {
    final picked = int.tryParse(v ?? '');
    if (picked == null || picked <= 0) return;

    final idx = _lastSnapshot.indexWhere(
            (x) => (x.orderPaymentAdjustment ?? -1) == picked);
    if (idx >= 0) {
      // já existe -> carrega registro
      selectRow(_lastSnapshot[idx]);
    } else {
      // livre -> inicia novo naquela ordem
      createNew(overrideOrder: picked);
      notifyListeners();
    }
  }

  Future<void> init(BuildContext context, {required ProcessData? contractData}) async {
    contract = contractData;
    if (contract?.id == null) return;

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

    setupValidation([orderCtrl, processCtrl, valueCtrl, dateCtrl], _validateFormInternal);
    await _loadInitial();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation(
      [orderCtrl, processCtrl, valueCtrl, dateCtrl, stateCtrl, observationCtrl,
        bankCtrl, electronicTicketCtrl, fontCtrl, taxCtrl],
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
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;

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

    _valorInicial = contract?.initialValueContract ?? 0.0;
    _valorAditivos = await _additivesBloc.getAllAdditivesValue(contract!.id!);
    _payments = await _paymentAdjustmentBloc
        .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);

    // 🆕 mantém snapshot para o dropdown
    _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

    // 🆕 define próxima ordem livre
    final next = _nextAvailableOrder(_existingOrders);
    orderCtrl.text = '$next';

    await _refreshSideList();
    notifyListeners();
  }

  void _validateFormInternal() {
    final valid = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
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
    valueCtrl.text = priceToString(data.valuePaymentAdjustment);
    dateCtrl.text = data.datePaymentAdjustment != null
        ? dateTimeToDDMMYYYY(data.datePaymentAdjustment!)
        : '';
    stateCtrl.text = data.statePaymentAdjustment ?? '';
    observationCtrl.text = data.observationPaymentAdjustment ?? '';
    bankCtrl.text = data.orderBankPaymentAdjustment ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentAdjustment ?? '';
    fontCtrl.text = data.fontPaymentAdjustment ?? '';
    taxCtrl.text = priceToString(data.taxPaymentAdjustment);

    _refreshSideList();
    notifyListeners();
  }

  void createNew({int? overrideOrder}) {
    selectedIndex = null;
    _selected = null;
    _currentId = null;

    // 🆕 mantém o valor escolhido no dropdown; se vazio, usa próxima livre
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
      isSaving = true; notifyListeners();

      final data = PaymentsAdjustmentsData(
        idPaymentAdjustment: _currentId,
        contractId: contract!.id!,
        orderPaymentAdjustment: int.tryParse(orderCtrl.text),
        processPaymentAdjustment: processCtrl.text,
        valuePaymentAdjustment: parseCurrencyToDouble(valueCtrl.text),
        datePaymentAdjustment: convertDDMMYYYYToDateTime(dateCtrl.text),
        statePaymentAdjustment: stateCtrl.text,
        observationPaymentAdjustment: observationCtrl.text,
        orderBankPaymentAdjustment: bankCtrl.text,
        electronicTicketPaymentAdjustment: electronicTicketCtrl.text,
        fontPaymentAdjustment: fontCtrl.text,
        taxPaymentAdjustment: parseCurrencyToDouble(taxCtrl.text),
        pdfUrl: _selected?.pdfUrl,
        attachments: _selected?.attachments,
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(data);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);
      // 🆕 mantém snapshot atualizado
      _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

      createNew();
      onSuccess?.call();
      return true;
    } catch (_) {
      onError?.call();
      return false;
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> saveExact(
      PaymentsAdjustmentsData data, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;

    try {
      isSaving = true; notifyListeners();

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
      // 🆕 mantém snapshot atualizado
      _lastSnapshot = List<PaymentsAdjustmentsData>.from(_payments);

      createNew();
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> deleteById(
      String idPaymentAdjustment, {
        VoidCallback? onSuccess,
        VoidCallback? onError,
      }) async {
    if (contract?.id == null) return;
    try {
      await _paymentAdjustmentBloc.deletarPayment(contract!.id!, idPaymentAdjustment);
      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);
      // 🆕 mantém snapshot atualizado
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
    final base = original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = _selected?.orderPaymentAdjustment ?? 0;
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

  Future<void> _refreshSideList() async {
    final v = _selected;
    if (v == null) {
      sideItems = const <dynamic>[];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 1) já tem attachments
    if ((v.attachments ?? const []).isNotEmpty) {
      sideItems = List<dynamic>.from(v.attachments!);
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 2) migra pdfUrl legado
    if ((v.pdfUrl ?? '').isNotEmpty && v.idPaymentAdjustment != null && contract?.id != null) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento do reajuste',
        url: v.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: currentUser?.id,
      );
      await _paymentAdjustmentBloc.setAttachments(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
        attachments: [att],
      );
      _selected = v..attachments = [att]..pdfUrl = null;
      sideItems = [att];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }

    // 3) materializa arquivos do Storage (se houver)
    if (contract?.id != null && v.idPaymentAdjustment != null) {
      final files = await _storageBloc.listarArquivosDoPagamento(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
      );
      if (files.isNotEmpty) {
        final list = files
            .map((f) => Attachment(
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
          createdBy: currentUser?.id,
        ))
            .toList();

        await _paymentAdjustmentBloc.setAttachments(
          contractId: contract!.id!,
          paymentAdjustmentId: v.idPaymentAdjustment!,
          attachments: list,
        );

        _selected = v..attachments = list;
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

  Future<void> handleAddFile(BuildContext context) async {
    final v = _selected;
    if (!canAddFile || contract?.id == null || v?.idPaymentAdjustment == null || v == null) return;

    try {
      isSaving = true; notifyListeners();

      final (Uint8List bytes, String originalName) = await _storageBloc.pickFileBytes();

      final suggestion = _suggestLabelFromName(originalName);
      final label = await _askLabel(context, suggestion: suggestion);
      if (label == null) { isSaving = false; notifyListeners(); return; }

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
      await _refreshSideList();
    } catch (_) {
      // você pode notificar via NotificationCenter, se desejar
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleEditLabelFile(int index, BuildContext context) async {
    final v = _selected;
    if (v == null || v.attachments == null || index < 0 || index >= v.attachments!.length) return;

    try {
      isSaving = true; notifyListeners();

      final att = v.attachments![index];
      final suggestion = att.label.isNotEmpty ? att.label : _suggestLabelFromName(att.id);
      final newLabel = await _askLabel(context, suggestion: suggestion);
      if (newLabel == null) { isSaving = false; notifyListeners(); return; }

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
        updatedBy: currentUser?.id,
      );

      await _paymentAdjustmentBloc.setAttachments(
        contractId: contract!.id!,
        paymentAdjustmentId: v.idPaymentAdjustment!,
        attachments: v.attachments!,
      );

      await _refreshSideList();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleDeleteFile(int index, BuildContext context) async {
    final v = _selected;
    if (v == null || v.idPaymentAdjustment == null || contract?.id == null) return;

    try {
      isSaving = true; notifyListeners();

      final atts = v.attachments ?? [];
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

      await _refreshSideList();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleOpenFile(BuildContext context, int index) async {
    final v = _selected;
    if (v == null) return;

    String? url;
    if ((v.attachments ?? []).isNotEmpty) {
      if (index < 0 || index >= v.attachments!.length) return;
      url = v.attachments![index].url;
      selectedSideIndex = index; notifyListeners();
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
