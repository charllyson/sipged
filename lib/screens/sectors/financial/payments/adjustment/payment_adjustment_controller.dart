import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_widgets/validates/form_validation_mixin.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_utils/date_utils.dart'
    show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;

import '../../../../../_provider/user/user_provider.dart';
import '../../../../../_blocs/system/user_bloc.dart';
import '../../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../../_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';

import '../../../../../_datas/system/user_data.dart';
import '../../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../../_datas/sectors/financial/payments/adjustments/payments_adjustments_data.dart';

/// Controller da PaymentsAdjustmentPage:
/// - Orquestra blocos
/// - Mantém TextEditingControllers e validação
/// - Expõe getters para gráficos/tabela e ações (salvar, excluir, selecionar etc.)
class PaymentsAdjustmentController extends ChangeNotifier with FormValidationMixin {
  PaymentsAdjustmentController({
    PaymentAdjustmentBloc? paymentAdjustmentBloc,
    AdditivesBloc? additivesBloc,
    UserBloc? userBloc,
  })  : _paymentAdjustmentBloc = paymentAdjustmentBloc ?? PaymentAdjustmentBloc(),
        _additivesBloc = additivesBloc ?? AdditivesBloc(),
        _userBloc = userBloc ?? UserBloc();

  // ---- dependências ----
  final PaymentAdjustmentBloc _paymentAdjustmentBloc;
  final AdditivesBloc _additivesBloc;
  final UserBloc _userBloc;

  /// Expor bloc para widgets legados (ex.: PdfFileIconActionGeneric)
  PaymentAdjustmentBloc get bloc => _paymentAdjustmentBloc;

  // ---- contexto/entidades ----
  UserData? currentUser;
  ContractData? contract;

  // ---- dados e estado ----
  List<PaymentsAdjustmentsData> _payments = <PaymentsAdjustmentsData>[];
  PaymentsAdjustmentsData? _selected;
  String? _currentId;

  int? selectedIndex;
  bool isEditable = false;
  bool isSaving = false;
  bool formValidated = false;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  // ---- controllers do formulário ----
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

  // ---- getters para UI ----
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

  // ---- ciclo de vida ----
  Future<void> init(BuildContext context, {required ContractData? contractData}) async {
    contract = contractData;
    if (contract?.id == null) return;

    currentUser = Provider.of<UserProvider>(context, listen: false).userData;
    isEditable = _userBloc.getUserCreateEditPermissions(userData: currentUser!);

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

  // ---- core ----
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

  // ---- ações de UI ----
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
        ? convertDateTimeToDDMMYYYY(data.datePaymentAdjustment!)
        : '';
    stateCtrl.text = data.statePaymentAdjustment ?? '';
    observationCtrl.text = data.observationPaymentAdjustment ?? '';
    bankCtrl.text = data.orderBankPaymentAdjustment ?? '';
    electronicTicketCtrl.text = data.electronicTicketPaymentAdjustment ?? '';
    fontCtrl.text = data.fontPaymentAdjustment ?? '';
    taxCtrl.text = priceToString(data.taxPaymentAdjustment);

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

    notifyListeners();
  }

  /// Salva/atualiza usando os dados dos controllers (fluxo do formulário).
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
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(data);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);

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

  /// Salva exatamente o objeto recebido (útil no Import Excel).
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
      );

      await _paymentAdjustmentBloc.saveOrUpdatePayment(toSave);

      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);

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
        VoidCallback? onSuccessSnack,
        VoidCallback? onErrorSnack,
      }) async {
    if (contract?.id == null) return;
    try {
      await _paymentAdjustmentBloc.deletarPayment(contract!.id!, idPaymentAdjustment);
      _payments = await _paymentAdjustmentBloc
          .getAllAdjustmentPaymentsOfContract(contractId: contract!.id!);
      selectedIndex = null;
      onSuccessSnack?.call();
    } catch (_) {
      onErrorSnack?.call();
    } finally {
      notifyListeners();
    }
  }

  // ---- utilitário opcional para ordenação/substituição externa ----
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
