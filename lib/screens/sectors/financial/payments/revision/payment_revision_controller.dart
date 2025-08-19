import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_widgets/validates/form_validation_mixin.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_utils/date_utils.dart'
    show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;

import '../../../../../_provider/user/user_provider.dart';
import '../../../../../_blocs/system/user_bloc.dart';
import '../../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../../_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';

import '../../../../../_datas/system/user_data.dart';
import '../../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../../_datas/sectors/financial/payments/revisions/payments_revisions_data.dart';

class PaymentsRevisionController extends ChangeNotifier with FormValidationMixin {
  PaymentsRevisionController({
    PaymentRevisionBloc? paymentRevisionBloc,
    AdditivesBloc? additivesBloc,
    UserBloc? userBloc,
  })  : _paymentRevisionBloc = paymentRevisionBloc ?? PaymentRevisionBloc(),
        _additivesBloc = additivesBloc ?? AdditivesBloc(),
        _userBloc = userBloc ?? UserBloc();

  // --- Dependências
  final PaymentRevisionBloc _paymentRevisionBloc;
  final AdditivesBloc _additivesBloc;
  final UserBloc _userBloc;

  // Expor bloc (apenas se um widget legado exigir)
  PaymentRevisionBloc get bloc => _paymentRevisionBloc;

  // --- Contexto
  UserData? currentUser;
  ContractData? contract;

  // --- Dados
  List<PaymentsRevisionsData> _revisions = <PaymentsRevisionsData>[];
  PaymentsRevisionsData? _selected;
  String? _currentId;

  // --- Estado UI
  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  // --- Totais
  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // --- Controllers de formulário
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

  // --- Getters para UI
  List<PaymentsRevisionsData> get revisions => _revisions;
  PaymentsRevisionsData? get selected => _selected;
  String? get currentPaymentRevisionId => _currentId;

  List<String> get chartLabels =>
      _revisions.map((e) => (e.orderPaymentRevision ?? 0).toString()).toList();

  List<double> get chartValues =>
      _revisions.map((e) => e.valuePaymentRevision ?? 0.0).toList();

  double get totalMedicoes =>
      chartValues.fold<double>(0.0, (a, b) => a + b);

  double get valorTotal => _valorInicial + _valorAditivos;
  double get saldo => valorTotal - totalMedicoes;

  // ajudar página/tabela
  double get valorInicialBase => _valorInicial;
  double get valorAditivosTotal => _valorAditivos;

  // --- Init/Dispose
  Future<void> init(BuildContext context, {required ContractData? contractData}) async {
    contract = contractData;
    if (contract?.id == null) return;

    currentUser = Provider.of<UserProvider>(context, listen: false).userData;
    isEditable = _userBloc.getUserCreateEditPermissions(userData: currentUser ?? UserData());

    setupValidation([
      orderCtrl,
      processCtrl,
      valueCtrl,
      dateCtrl,
    ], _validateFormInternal);

    await _loadInitial();
  }

  @override
  void dispose() {
    removeValidation([
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

    notifyListeners();
  }

  void _validateFormInternal() {
    final valid = areFieldsFilled([
      orderCtrl,
      processCtrl,
      valueCtrl,
      dateCtrl,
    ], minLength: 1);

    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
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
        ? convertDateTimeToDDMMYYYY(data.datePaymentRevision!)
        : '';
    stateCtrl.text = data.statePaymentRevision ?? '';
    observationCtrl.text = data.observationPaymentRevision ?? '';
    bankCtrl.text = data.orderBankPaymentRevision ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentRevision ?? '';
    fontCtrl.text = data.fontPaymentRevision ?? '';
    taxCtrl.text = priceToString(data.taxPaymentRevision);

    notifyListeners();
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

  /// ImportExcel: salva exatamente o objeto recebido.
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
        VoidCallback? onSuccessSnack,
        VoidCallback? onErrorSnack,
      }) async {
    if (contract?.id == null) return;
    try {
      await _paymentRevisionBloc.deletarPayment(contract!.id!, idPaymentRevision);
      _revisions = await _paymentRevisionBloc
          .getAllReportPaymentsOfContract(contractId: contract!.id!);
      selectedIndex = null;
      onSuccessSnack?.call();
    } catch (_) {
      onErrorSnack?.call();
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
  }

  // ordenação/substituição externa opcional
  void overwriteList(List<PaymentsRevisionsData> newList) {
    _revisions = newList;
    final last = _revisions.isNotEmpty
        ? _revisions.map((e) => e.orderPaymentRevision ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    if (selectedIndex == null) {
      orderCtrl.text = (last + 1).toString();
    }
    notifyListeners();
  }
}
