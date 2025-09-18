import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/date_utils.dart'
    show dateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;

import 'package:siged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

class PaymentsReportController extends ChangeNotifier with FormValidationMixin {
  PaymentsReportController({
    required PaymentReportBloc paymentReportBloc,
    required AdditivesBloc additivesBloc,
    PaymentsReportStorageBloc? storageBloc, // 🆕
  })  : _paymentReportBloc = paymentReportBloc,
        _additivesBloc = additivesBloc,
        _storageBloc = storageBloc ?? PaymentsReportStorageBloc();

  final PaymentReportBloc _paymentReportBloc;
  final AdditivesBloc _additivesBloc;
  final PaymentsReportStorageBloc _storageBloc; // 🆕

  StreamSubscription<UserState>? _userSub;

  UserData? currentUser;
  ContractData? contract;

  List<PaymentsReportData> _reports = <PaymentsReportData>[];
  PaymentsReportData? _selected;
  String? _currentId;

  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // Campos
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

  // 🆕 SideListBox
  List<String> sideItems = const <String>[];
  int? selectedSideIndex;
  bool get canAddFile => isEditable && _selected?.idPaymentReport != null;
  String? get currentPdfUrl => _selected?.pdfUrl;

  List<PaymentsReportData> get reports => _reports;
  PaymentsReportData? get selected => _selected;
  String? get currentPaymentReportId => _currentId;

  List<String> get chartLabels =>
      _reports.map((e) => (e.orderPaymentReport ?? 0).toString()).toList();
  List<double> get chartValues =>
      _reports.map((e) => e.valuePaymentReport ?? 0.0).toList();

  bool get isAdmin =>
      (currentUser?.baseProfile ?? '').trim().toLowerCase() == 'administrador';

  double get totalMedicoes => chartValues.fold<double>(0.0, (a, b) => a + b);
  double get valorTotal => _valorInicial + _valorAditivos;
  double get saldo => valorTotal - totalMedicoes;


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
    removeValidation([
      orderCtrl, processCtrl, valueCtrl, dateCtrl, stateCtrl, observationCtrl,
      bankCtrl, electronicTicketCtrl, fontCtrl, taxCtrl,
    ], _validateFormInternal);
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
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;
    final perms = user.modulePermissions['payments_report'];
    if (perms != null) return (perms['edit'] == true) || (perms['create'] == true);
    return false;
  }

  Future<void> _loadInitial() async {
    if (contract?.id == null) return;

    _valorInicial = contract?.initialValueContract ?? 0.0;
    _valorAditivos = await _additivesBloc.getAllAdditivesValue(contract!.id!);

    _reports = await _paymentReportBloc
        .getAllReportPaymentsOfContract(contractId: contract!.id!);

    final last = _reports.isNotEmpty
        ? _reports.map((e) => e.orderPaymentReport ?? 0).reduce((a, b) => a > b ? a : b)
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

  void selectRow(PaymentsReportData data) {
    final idx = _reports.indexOf(data);
    if (idx == -1) return;

    selectedIndex = idx;
    _selected = data;
    _currentId = data.idPaymentReport;

    orderCtrl.text = (data.orderPaymentReport ?? '').toString();
    processCtrl.text = data.processPaymentReport ?? '';
    valueCtrl.text = priceToString(data.valuePaymentReport);
    dateCtrl.text = data.datePaymentReport != null
        ? dateTimeToDDMMYYYY(data.datePaymentReport!)
        : '';
    stateCtrl.text = data.statePaymentReport ?? '';
    observationCtrl.text = data.observationPaymentReport ?? '';
    bankCtrl.text = data.orderBankPaymentReport ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentReport ?? '';
    fontCtrl.text = data.fontPaymentReport ?? '';
    taxCtrl.text = priceToString(data.taxPaymentReport);

    _refreshSideList();
    notifyListeners();
  }

  void createNew() {
    final last = _reports.map((e) => e.orderPaymentReport ?? 0).fold(0, (a, b) => a > b ? a : b);
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
    VoidCallback? onSuccessSnack,
    VoidCallback? onErrorSnack,
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
        valuePaymentReport: parseCurrencyToDouble(valueCtrl.text),
        datePaymentReport: convertDDMMYYYYToDateTime(dateCtrl.text),
        statePaymentReport: stateCtrl.text,
        observationPaymentReport: observationCtrl.text,
        orderBankPaymentReport: bankCtrl.text,
        electronicTicketPaymentReport: electronicTicketCtrl.text,
        fontPaymentReport: fontCtrl.text,
        taxPaymentReport: parseCurrencyToDouble(taxCtrl.text),
        pdfUrl: _selected?.pdfUrl, // preserva se existir
      );

      await _paymentReportBloc.saveOrUpdatePayment(data);
      _reports = await _paymentReportBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);

      createNew();
      onSuccessSnack?.call();
      return true;
    } catch (_) {
      onErrorSnack?.call();
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
      isSaving = true; notifyListeners();

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
      );

      await _paymentReportBloc.saveOrUpdatePayment(toSave);
      _reports = await _paymentReportBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);

      createNew();
      onSuccess?.call();
    } catch (_) {
      onError?.call();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> deleteById(
      String idPaymentReport, {
        VoidCallback? onSuccessSnack,
        VoidCallback? onErrorSnack,
      }) async {
    if (contract?.id == null) return;
    try {
      await _paymentReportBloc.deletarPayment(contract!.id!, idPaymentReport);
      _reports = await _paymentReportBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);
      selectedIndex = null;
      onSuccessSnack?.call();
    } catch (_) {
      onErrorSnack?.call();
    } finally {
      notifyListeners();
    }
  }

  // ---------- PDF (lista/SideListBox) ----------
  Future<void> _refreshSideList() async {
    if (currentPdfUrl != null && currentPdfUrl!.isNotEmpty) {
      sideItems = const ['PDF do Pagamento'];
      selectedSideIndex = 0;
    } else {
      sideItems = const <String>[];
      selectedSideIndex = null;
    }
    if (hasListeners) notifyListeners();
  }

  Future<void> handleAddFile() async {
    if (!canAddFile || contract?.id == null || _selected?.idPaymentReport == null) return;
    try {
      isSaving = true; notifyListeners();

      final url = await _storageBloc.uploadWithPicker(
        contract: contract!,
        payment: _selected!,
        onProgress: (_) {},
      );

      await _paymentReportBloc.salvarUrlPdfDePayment(
        contractId: contract!.id!,
        paymentId: _selected!.idPaymentReport!,
        url: url,
      );

      _selected = _selected!..pdfUrl = url;
      await _refreshSideList();
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> handleDeleteFile(int index) async {
    if (contract?.id == null || _selected?.idPaymentReport == null) return;
    try {
      isSaving = true; notifyListeners();

      await _storageBloc.delete(contract!, _selected!);
      await _paymentReportBloc.salvarUrlPdfDePayment(
        contractId: contract!.id!,
        paymentId: _selected!.idPaymentReport!,
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

  // compat: usado por WebPdfWidget antigo (se ficar em algum lugar)
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
}
