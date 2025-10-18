// lib/_blocs/sectors/financial/payments/adjustment/payment_adjustment_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';

import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';

// ✅ novo: papéis globais + permissões por módulo
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
  ContractData? contract;

  List<PaymentsAdjustmentsData> _payments = <PaymentsAdjustmentsData>[];
  PaymentsAdjustmentsData? _selected;
  String? _currentId;

  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // SideListBox
  List<String> sideItems = const <String>[];
  int? selectedSideIndex;
  bool get canAddFile => isEditable && _selected?.idPaymentAdjustment != null;
  String? get currentPdfUrl => _selected?.pdfUrl;

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

  // ✅ admin via papel global
  bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    return roles.roleForUser(u) == roles.BaseRole.ADMINISTRADOR;
  }

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

  // ✅ Permissão (módulo: payments_adjustment)
  bool _canEditUser(UserData? user) {
    if (user == null) return false;

    // Admin sempre pode
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;

    // Senão, checamos permissão de módulo (edit OU create concede edição)
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

    final last = _payments.isNotEmpty
        ? _payments.map((e) => e.orderPaymentAdjustment ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (last + 1).toString();

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

  void createNew() {
    final last = _payments.map((e) => e.orderPaymentAdjustment ?? 0).fold(0, (a, b) => a > b ? a : b);
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
        pdfUrl: _selected?.pdfUrl, // mantém se já existir
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(data);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);

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
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(toSave);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);

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
      selectedIndex = null;
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      notifyListeners();
    }
  }

  // --------- PDF via SideListBox ----------
  Future<void> _refreshSideList() async {
    if (currentPdfUrl != null && currentPdfUrl!.isNotEmpty) {
      sideItems = const ['PDF do Pagamento de Reajuste'];
      selectedSideIndex = 0;
    } else {
      sideItems = const <String>[];
      selectedSideIndex = null;
    }
    if (hasListeners) notifyListeners();
  }

  Future<void> handleAddFile() async {
    if (!canAddFile || contract?.id == null || _selected?.idPaymentAdjustment == null) return;
    try {
      isSaving = true; notifyListeners();

      final url = await _storageBloc.uploadWithPicker(
        contract: contract!,
        payment: _selected!,
        onProgress: (_) {},
      );

      await _paymentAdjustmentBloc.salvarUrlPdfDePayment(
        contractId: contract!.id!,
        paymentId: _selected!.idPaymentAdjustment!,
        url: url,
      );

      _selected = _selected!..pdfUrl = url;
      await _refreshSideList();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleDeleteFile(int index) async {
    if (contract?.id == null || _selected?.idPaymentAdjustment == null) return;
    try {
      isSaving = true; notifyListeners();

      await _storageBloc.delete(contract!, _selected!);
      await _paymentAdjustmentBloc.salvarUrlPdfDePayment(
        contractId: contract!.id!,
        paymentId: _selected!.idPaymentAdjustment!,
        url: '',
      );

      _selected = _selected!..pdfUrl = null;
      await _refreshSideList();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleOpenFile(int index) async {
    final url = currentPdfUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void overwriteList(List<PaymentsAdjustmentsData> newList) {
    _payments = newList;
    final last = _payments.isNotEmpty
        ? _payments.map((e) => e.orderPaymentAdjustment ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    if (selectedIndex == null) {
      orderCtrl.text = (last + 1).toString();
    }
    notifyListeners();
  }
}
