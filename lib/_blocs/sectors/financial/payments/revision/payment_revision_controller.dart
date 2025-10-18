// lib/_blocs/sectors/financial/payments/revision/payment_revision_controller.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/date_utils.dart'
    show dateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/additives/additives_bloc.dart';

import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_storage_bloc.dart';

// ✅ NOVO: papéis globais + checagens de permissão por módulo
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

// 🔔 Notificações centralizadas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PaymentsRevisionController extends ChangeNotifier with FormValidationMixin {
  PaymentsRevisionController({
    required PaymentRevisionBloc paymentRevisionBloc,
    required AdditivesBloc additivesBloc,
    PaymentRevisionStorageBloc? storageBloc,
  })  : _paymentRevisionBloc = paymentRevisionBloc,
        _additivesBloc = additivesBloc,
        _storageBloc = storageBloc ?? PaymentRevisionStorageBloc();

  // --- Dependências
  final PaymentRevisionBloc _paymentRevisionBloc;
  final AdditivesBloc _additivesBloc;
  final PaymentRevisionStorageBloc _storageBloc;

  // --- User stream
  StreamSubscription<UserState>? _userSub;

  // --- Contexto
  UserData? currentUser;
  ContractData? contract;

  // --- Dados
  List<PaymentsRevisionsData> _revisions = <PaymentsRevisionsData>[];
  PaymentsRevisionsData? _selected;
  String? _currentId;

  // --- SideListBox
  List<String> sideItems = const [];
  int? selectedSideIndex;

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

  // ✅ foi: baseProfile; agora: papel global via user_permission.dart
  bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    return roles.roleForUser(u) == roles.BaseRole.ADMINISTRADOR;
  }

  // --- Init/Dispose
  Future<void> init(BuildContext context, {required ContractData? contractData}) async {
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

  // --- Permissão (módulo: payments_revision)
  bool _canEditUser(UserData? user) {
    if (user == null) return false;

    // Admin sempre pode
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;

    // Senão, checamos permissão de módulo (edit OU create concede edição)
    final canEditModule = perms.userCanModule(
      user: user,
      module: 'payments_revision',
      action: 'edit',
    );

    final canCreateModule = perms.userCanModule(
      user: user,
      module: 'payments_revision',
      action: 'create',
    );

    return canEditModule || canCreateModule;
  }

  // --- Core
  Future<void> _loadInitial() async {
    if (contract?.id == null) return;

    _valorInicial = contract?.initialValueContract ?? 0.0;
    _valorAditivos = await _additivesBloc.getAllAdditivesValue(contract!.id!);

    _revisions = await _paymentRevisionBloc
        .getAllReportPaymentsOfContract(contractId: contract!.id!);

    final last = _revisions.isNotEmpty
        ? _revisions.map((e) => e.orderPaymentRevision ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (last + 1).toString();

    sideItems = const [];
    selectedSideIndex = null;

    notifyListeners();
  }

  void _validateFormInternal() {
    final valid = areFieldsFilled([orderCtrl, processCtrl, valueCtrl, dateCtrl], minLength: 1);
    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // --- Side list helpers
  Future<void> _refreshSideList() async {
    if (contract == null || _selected?.idRevisionPayment == null) {
      sideItems = const [];
      selectedSideIndex = null;
      notifyListeners();
      return;
    }
    final exists = await _storageBloc.exists(contract!, _selected!);
    sideItems = exists ? const ['Pagamento da Revisão (PDF)'] : const [];
    selectedSideIndex = null;
    notifyListeners();
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
    valueCtrl.text = priceToString(data.valuePaymentRevision);
    dateCtrl.text = data.datePaymentRevision != null
        ? dateTimeToDDMMYYYY(data.datePaymentRevision!)
        : '';
    stateCtrl.text = data.statePaymentRevision ?? '';
    observationCtrl.text = data.observationPaymentRevision ?? '';
    bankCtrl.text = data.orderBankPaymentRevision ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentRevision ?? '';
    fontCtrl.text = data.fontPaymentRevision ?? '';
    taxCtrl.text = priceToString(data.taxPaymentRevision);

    notifyListeners();
    _refreshSideList();
  }

  void createNew() {
    final last = _revisions.map((e) => e.orderPaymentRevision ?? 0).fold(0, (a, b) => a > b ? a : b);
    selectedIndex = null;
    _selected = null;
    _currentId = null;

    orderCtrl.text = (last + 1).toString();
    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();
    stateCtrl.clear();
    observationCtrl.clear();
    bankCtrl.clear();
    electronicTicketCtrl.clear();
    fontCtrl.clear();
    taxCtrl.clear();

    sideItems = const [];
    selectedSideIndex = null;

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

      final data = PaymentsRevisionsData(
        contractId: contract!.id!,
        idRevisionPayment: _currentId,
        orderPaymentRevision: int.tryParse(orderCtrl.text),
        processPaymentRevision: processCtrl.text,
        valuePaymentRevision: parseCurrencyToDouble(valueCtrl.text),
        datePaymentRevision: convertDDMMYYYYToDateTime(dateCtrl.text),
        statePaymentRevision: stateCtrl.text,
        observationPaymentRevision: observationCtrl.text,
        orderBankPaymentRevision: bankCtrl.text,
        electronicTicketPaymentRevision: electronicTicketCtrl.text,
        fontPaymentRevision: fontCtrl.text,
        taxPaymentRevision: parseCurrencyToDouble(taxCtrl.text),
      );

      await _paymentRevisionBloc.saveOrUpdatePayment(data);

      _revisions = await _paymentRevisionBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);

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
      );

      await _paymentRevisionBloc.saveOrUpdatePayment(toSave);

      _revisions = await _paymentRevisionBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);

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
      _revisions = await _paymentRevisionBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);
      selectedIndex = null;
      onSuccess?.call();

      sideItems = const [];
      selectedSideIndex = null;
      notifyListeners();
    } catch (_) {
      onError?.call();
    } finally {
      notifyListeners();
    }
  }

  Future<void> savePdfUrl(String url) async {
    if (_selected?.idRevisionPayment == null || contract?.id == null) return;
    await _paymentRevisionBloc.salvarUrlPdfDePayment(
      contractId: contract!.id!,
      paymentId: _selected!.idRevisionPayment!,
      url: url,
    );
    await _refreshSideList();
  }

  // ====== AÇÕES DA SIDE LIST ======

  /// Upload + salva URL no Firestore
  Future<void> addSideItem(BuildContext context) async {
    if (contract == null || _selected?.idRevisionPayment == null) return;
    try {
      final url = await _storageBloc.uploadWithPicker(
        contract: contract!,
        payment: _selected!,
        onProgress: (_) {},
      );
      await _paymentRevisionBloc.salvarUrlPdfDePayment(
        contractId: contract!.id!,
        paymentId: _selected!.idRevisionPayment!,
        url: url,
      );
      await _refreshSideList();

      _notify('PDF enviado com sucesso.', type: AppNotificationType.success);
    } catch (e) {
      _notify('Falha ao enviar PDF', subtitle: '$e', type: AppNotificationType.error);
    }
  }

  /// Obtém a URL e copia para a área de transferência
  Future<void> openSideItem(BuildContext context, int index) async {
    if (contract == null || _selected == null) return;
    final url = await _storageBloc.getUrl(contract!, _selected!);
    if (url == null || url.isEmpty) {
      _notify('Nenhum PDF disponível para esta revisão.', type: AppNotificationType.warning);
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    _notify('URL do PDF copiada', subtitle: 'Cole no navegador para abrir.');
  }

  /// Exclui o PDF do Storage e limpa o campo no doc (opcional)
  Future<void> deleteSideItem(BuildContext context, int index) async {
    if (contract == null || _selected == null) return;
    try {
      final ok = await _storageBloc.delete(contract!, _selected!);
      if (ok) {
        await _paymentRevisionBloc.salvarUrlPdfDePayment(
          contractId: contract!.id!,
          paymentId: _selected!.idRevisionPayment!,
          url: '',
        );
        await _refreshSideList();

        _notify('PDF excluído com sucesso.', type: AppNotificationType.success);
      }
    } catch (e) {
      _notify('Falha ao excluir PDF', subtitle: '$e', type: AppNotificationType.error);
    }
  }

  // util
  void overwriteList(List<PaymentsRevisionsData> newList) {
    _revisions = newList;
    final last = _revisions.isNotEmpty
        ? _revisions.map((e) => e.orderPaymentRevision ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    if (selectedIndex == null) {
      orderCtrl.text = (last + 1).toString();
    }
    sideItems = const [];
    selectedSideIndex = null;
    notifyListeners();
  }

  // ===== Notificação centralizada =====
  void _notify(
      String title, {
        String? subtitle,
        AppNotificationType type = AppNotificationType.info,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        type: type,
        title: Text(title),
        subtitle: (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
      ),
    );
  }
}
