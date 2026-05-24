// lib/screens/modules/financial/payments/adjustment/adjustment_payment_form_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_cubit.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_payments.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/modules/financial/payments/report/report_paid_summary.dart';

class AdjustmentPaymentFormView extends StatefulWidget {
  const AdjustmentPaymentFormView({
    super.key,
    required this.contractData,
    required this.selectedAdjustmentMeasurement,
    required this.orderController,
    required this.isEditable,
    this.onPaymentsChanged,
  });

  final ContractData contractData;
  final AdjustmentMeasurementData selectedAdjustmentMeasurement;
  final TextEditingController orderController;
  final bool isEditable;

  final Future<void> Function()? onPaymentsChanged;

  @override
  State<AdjustmentPaymentFormView> createState() {
    return _AdjustmentPaymentFormViewState();
  }
}

class _AdjustmentPaymentFormViewState extends State<AdjustmentPaymentFormView> {
  late final TextEditingController _orderCtrl;
  late final TextEditingController _fonteCtrl;

  late final TextEditingController _dateCtrl;
  late final TextEditingController _valueCtrl;

  late final TextEditingController _inssDateCtrl;
  late final TextEditingController _inssValueCtrl;

  late final TextEditingController _irpfDateCtrl;
  late final TextEditingController _irpfValueCtrl;

  late final TextEditingController _issDateCtrl;
  late final TextEditingController _issValueCtrl;

  late final TextEditingController _noteCtrl;

  DfdData? _dfdData;

  int _formNonce = 0;
  int _fundingNonce = 0;

  bool _startupLoaded = false;
  bool _loadingDfdSummary = false;
  bool _formOk = false;

  String get _contractId {
    return _s(widget.contractData.id);
  }

  String get _adjustmentId {
    return _s(widget.selectedAdjustmentMeasurement.id);
  }

  double get _adjustmentValue {
    final value = widget.selectedAdjustmentMeasurement.value ?? 0.0;

    if (!value.isFinite || value < 0) return 0.0;

    return _roundMoney(value);
  }

  int? get _adjustmentOrder {
    final fromModel = widget.selectedAdjustmentMeasurement.order;

    if (fromModel != null) return fromModel;

    final text = widget.orderController.text.trim();

    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  String get _contractSummary {
    final descricaoObjeto = _s(_dfdData?.descricaoObjeto);

    if (descricaoObjeto.isNotEmpty && !_looksLikeIdOnly(descricaoObjeto)) {
      return descricaoObjeto;
    }

    final summary = _s(widget.contractData.displaySummary);

    if (summary.isNotEmpty && !_looksLikeIdOnly(summary)) {
      return summary;
    }

    return 'Obra vinculada';
  }

  bool _looksLikeIdOnly(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;

    final withoutSeparators = clean.replaceAll(RegExp(r'[-_/.\s]'), '');

    if (withoutSeparators.length < 16) return false;

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(withoutSeparators);
    final hasNumber = RegExp(r'[0-9]').hasMatch(withoutSeparators);

    return hasLetter && hasNumber;
  }

  @override
  void initState() {
    super.initState();

    _orderCtrl = TextEditingController(
      text: _adjustmentOrder?.toString() ?? widget.orderController.text.trim(),
    );

    _fonteCtrl = TextEditingController();

    _dateCtrl = TextEditingController();
    _valueCtrl = TextEditingController();

    _inssDateCtrl = TextEditingController();
    _inssValueCtrl = TextEditingController();

    _irpfDateCtrl = TextEditingController();
    _irpfValueCtrl = TextEditingController();

    _issDateCtrl = TextEditingController();
    _issValueCtrl = TextEditingController();

    _noteCtrl = TextEditingController();

    _fonteCtrl.addListener(_validate);
    _dateCtrl.addListener(_validate);
    _valueCtrl.addListener(_validate);

    _inssDateCtrl.addListener(_validate);
    _inssValueCtrl.addListener(_validate);

    _irpfDateCtrl.addListener(_validate);
    _irpfValueCtrl.addListener(_validate);

    _issDateCtrl.addListener(_validate);
    _issValueCtrl.addListener(_validate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startupLoaded) return;

      _startupLoaded = true;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();

      _loadDfdSummary();
    });
  }

  @override
  void didUpdateWidget(covariant AdjustmentPaymentFormView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextOrder =
        _adjustmentOrder?.toString() ?? widget.orderController.text.trim();

    if (_orderCtrl.text != nextOrder) {
      _orderCtrl.text = nextOrder;
    }

    final oldAdjustmentId = _s(oldWidget.selectedAdjustmentMeasurement.id);
    final nextAdjustmentId = _s(widget.selectedAdjustmentMeasurement.id);

    if (oldAdjustmentId != nextAdjustmentId) {
      _fillFromPayment(null);
    }

    final oldContractId = _s(oldWidget.contractData.id);
    final nextContractId = _s(widget.contractData.id);

    if (oldContractId != nextContractId) {
      _dfdData = null;
      _loadDfdSummary();
    }
  }

  @override
  void dispose() {
    _orderCtrl.dispose();

    _fonteCtrl
      ..removeListener(_validate)
      ..dispose();

    _dateCtrl
      ..removeListener(_validate)
      ..dispose();

    _valueCtrl
      ..removeListener(_validate)
      ..dispose();

    _inssDateCtrl
      ..removeListener(_validate)
      ..dispose();

    _inssValueCtrl
      ..removeListener(_validate)
      ..dispose();

    _irpfDateCtrl
      ..removeListener(_validate)
      ..dispose();

    _irpfValueCtrl
      ..removeListener(_validate)
      ..dispose();

    _issDateCtrl
      ..removeListener(_validate)
      ..dispose();

    _issValueCtrl
      ..removeListener(_validate)
      ..dispose();

    _noteCtrl.dispose();

    super.dispose();
  }

  String _s(Object? value) {
    final text = value?.toString().trim() ?? '';

    if (text.toLowerCase() == 'null') return '';

    return text;
  }

  String? _activeTenantId() {
    try {
      final tenantId = context.read<PermissionCubit>().state.activeTenantId;
      final clean = _s(tenantId);

      if (clean.isEmpty) return null;

      return clean;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDfdSummary() async {
    if (_loadingDfdSummary) return;

    final tenantId = _activeTenantId();
    final contractId = _contractId;

    if (tenantId == null || tenantId.trim().isEmpty) return;
    if (contractId.trim().isEmpty) return;

    _loadingDfdSummary = true;

    try {
      final repository = DfdRepository(
        tenantId: tenantId.trim(),
      );

      final dfd = await repository.readDataForContract(contractId.trim());

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD para resumo do pagamento de reajuste: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      _loadingDfdSummary = false;
    }
  }

  String? _findByLabel(List<String> list, String label) {
    final target = label.trim().toLowerCase();

    if (target.isEmpty) return null;

    for (final item in list) {
      if (item.trim().toLowerCase() == target) {
        return item.trim();
      }
    }

    return null;
  }

  double _roundMoney(double value) {
    if (!value.isFinite) return 0.0;

    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded == 0.0) return 0.0;

    return rounded;
  }

  bool _moneyIsZero(double value) {
    return _roundMoney(value) == 0.0;
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return _roundMoney(v);
  }

  double _paymentTotalValue(AdjustmentPaidData payment) {
    return _roundMoney(
      _positive(payment.paymentValue) +
          _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );
  }

  double _sumPaymentTotalValues(List<AdjustmentPaidData> payments) {
    return payments.fold<double>(
      0.0,
          (totalValue, payment) {
        return _roundMoney(totalValue + _paymentTotalValue(payment));
      },
    );
  }

  Future<void> _notifyParentPaymentsChanged() async {
    await widget.onPaymentsChanged?.call();
  }

  Future<void> _showLocalPaymentError(String message) async {
    if (!mounted) return;

    final tenantId = _activeTenantId();

    await NotificationPayments.show(
      context: context,
      contract: widget.contractData,
      title: 'Atenção',
      subtitle: _contractSummary,
      details: message,
      kind: NotificationPaymentKind.adjustment,
      status: NotificationStatus.warning,
      delivery: NotificationDelivery.localBellAndPush,
      saveInBell: false,
      sendPush: false,
      includeCurrentUser: true,
      tenantId: tenantId ?? '',
      companyId: tenantId ?? '',
      contractSummary: _contractSummary,
      contractTitle: _contractSummary,
      descricaoObjeto: _contractSummary,
      nomeDemanda: _contractSummary,
      action: 'adjustment_payment_validation_error',
      extra: <String, dynamic>{
        'action': 'adjustment_payment_validation_error',
        'paymentType': 'adjustment_payment',
        'sourceModule': 'financial_payments_adjustment',
        'tenantId': tenantId,
        'companyId': tenantId,
        'summarySubjectContract': _contractSummary,
        'contractSummary': _contractSummary,
        'contractTitle': _contractSummary,
        'descricaoObjeto': _contractSummary,
        'nomeDemanda': _contractSummary,
        'adjustmentOrder': _adjustmentOrder?.toString(),
        'adjustmentValue': _adjustmentValue,
      },
    );
  }

  Future<String?> _askNewLabel(
      BuildContext context, {
        required String title,
        required String initialValue,
        String labelText = 'Novo nome',
      }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: labelText,
            ),
            onSubmitted: (value) {
              Navigator.of(dialogCtx).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(controller.text.trim());
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final trimmed = result?.trim();

    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed == initialValue.trim()) return null;

    return trimmed;
  }

  DateTime? _parseDate(String text) {
    final clean = text.trim();

    if (clean.isEmpty) return null;

    final parts = clean.split('/');

    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    final date = DateTime(year, month, day);

    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }

    return date;
  }

  DateTime? _parseOptionalDate(String text) {
    final clean = text.trim();

    if (clean.isEmpty) return null;

    return _parseDate(clean);
  }

  double _parseCurrency(String text) {
    return _roundMoney(SipGedFormatMoney.parseBrl(text) ?? 0.0);
  }

  double? _parseOptionalCurrency(String text) {
    final clean = text.trim();

    if (clean.isEmpty) return null;

    final value = SipGedFormatMoney.parseBrl(clean);

    if (value == null || value <= 0) return null;

    return _roundMoney(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool _optionalDateAndValuePairIsValid({
    required TextEditingController dateCtrl,
    required TextEditingController valueCtrl,
  }) {
    final dateText = dateCtrl.text.trim();
    final valueText = valueCtrl.text.trim();

    if (dateText.isEmpty && valueText.isEmpty) return true;

    if (dateText.isEmpty || valueText.isEmpty) return false;

    final date = _parseDate(dateText);
    final value = _parseCurrency(valueText);

    return date != null && value > 0;
  }

  bool _computeFormOk() {
    final mainOk = _fonteCtrl.text.trim().isNotEmpty &&
        _dateCtrl.text.trim().isNotEmpty &&
        _valueCtrl.text.trim().isNotEmpty &&
        _parseDate(_dateCtrl.text) != null &&
        _parseCurrency(_valueCtrl.text) > 0;

    final inssOk = _optionalDateAndValuePairIsValid(
      dateCtrl: _inssDateCtrl,
      valueCtrl: _inssValueCtrl,
    );

    final irpfOk = _optionalDateAndValuePairIsValid(
      dateCtrl: _irpfDateCtrl,
      valueCtrl: _irpfValueCtrl,
    );

    final issOk = _optionalDateAndValuePairIsValid(
      dateCtrl: _issDateCtrl,
      valueCtrl: _issValueCtrl,
    );

    return mainOk && inssOk && irpfOk && issOk;
  }

  void _validate() {
    final ok = _computeFormOk();

    if (_formOk != ok && mounted) {
      setState(() {
        _formOk = ok;
      });
    }
  }

  void _fillFromPayment(AdjustmentPaidData? payment) {
    if (!mounted) return;

    setState(() {
      if (payment == null) {
        _fonteCtrl.clear();

        _dateCtrl.clear();
        _valueCtrl.clear();

        _inssDateCtrl.clear();
        _inssValueCtrl.clear();

        _irpfDateCtrl.clear();
        _irpfValueCtrl.clear();

        _issDateCtrl.clear();
        _issValueCtrl.clear();

        _noteCtrl.clear();
      } else {
        _fonteCtrl.text = payment.fundingSourceLabel ?? '';

        _dateCtrl.text = _formatDate(payment.paymentDate);
        _valueCtrl.text = SipGedFormatMoney.brlNoSymbol(payment.paymentValue);

        _inssDateCtrl.text = _formatDate(payment.inssPaymentDate);
        _inssValueCtrl.text = SipGedFormatMoney.brlNoSymbol(
          payment.inssPaymentValue,
        );

        _irpfDateCtrl.text = _formatDate(payment.irpfPaymentDate);
        _irpfValueCtrl.text = SipGedFormatMoney.brlNoSymbol(
          payment.irpfPaymentValue,
        );

        _issDateCtrl.text = _formatDate(payment.issPaymentDate);
        _issValueCtrl.text = SipGedFormatMoney.brlNoSymbol(
          payment.issPaymentValue,
        );

        _noteCtrl.text = payment.note ?? '';
      }

      _formOk = _computeFormOk();

      _formNonce++;
      _fundingNonce++;
    });
  }

  Widget _input(
      double width,
      TextEditingController controller,
      String label, {
        bool enabled = true,
        bool money = false,
        bool date = false,
        TextInputFormatter? mask,
        int? maxLines,
      }) {
    return CustomTextField(
      width: width,
      enabled: enabled && widget.isEditable,
      labelText: label,
      controller: controller,
      maxLines: maxLines,
      keyboardType: money
          ? const TextInputType.numberWithOptions(decimal: true)
          : date
          ? TextInputType.datetime
          : TextInputType.text,
      prefixText: money ? 'R\$ ' : null,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SipGedTheme.textDark,
      ),
      inputFormatters: [
        if (date) FilteringTextInputFormatter.digitsOnly,
        if (date) SipGedMasks.dateDDMMYYYY,
        if (money) const SipGedMoneyFormatter(),
        ?mask,
      ],
    );
  }

  Widget _dateInput({
    required String keyId,
    required double width,
    required TextEditingController controller,
    required String label,
    DateTime? initialValue,
  }) {
    return DateFieldChange(
      key: ValueKey<String>(
        'adjustment-payment-date-$keyId-$_formNonce-${controller.text}',
      ),
      width: width,
      enabled: widget.isEditable,
      controller: controller,
      initialValue: initialValue,
      labelText: label,
      onChanged: (date) {
        if (date != null) {
          controller.text = _formatDate(date);
        }

        _validate();
      },
    );
  }

  Widget _sectionLabel(String text) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: SipGedTheme.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  double _totalRetencoesFormulario() {
    return _roundMoney(
      (_parseOptionalCurrency(_inssValueCtrl.text) ?? 0.0) +
          (_parseOptionalCurrency(_irpfValueCtrl.text) ?? 0.0) +
          (_parseOptionalCurrency(_issValueCtrl.text) ?? 0.0),
    );
  }

  Future<void> _notifyPaymentSaved({
    required AdjustmentPaidData payment,
    required bool wasEditing,
  }) async {
    if (!mounted) return;

    final tenantId = _activeTenantId();

    if (tenantId == null || tenantId.isEmpty) return;

    final adjustmentOrderText = _adjustmentOrder?.toString().trim() ?? '';

    final paymentValue = _roundMoney(payment.paymentValue ?? 0.0);
    final retentionsValue = _totalRetencoesFormulario();
    final totalValue = _roundMoney(paymentValue + retentionsValue);

    final actionLabel = wasEditing ? 'atualizado' : 'registrado';

    final title = adjustmentOrderText.isNotEmpty
        ? 'Pagamento do reajuste $adjustmentOrderText $actionLabel'
        : 'Pagamento de reajuste $actionLabel';

    await NotificationPayments.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: _contractSummary,
      details: wasEditing
          ? 'O pagamento do reajuste foi atualizado.'
          : 'O pagamento do reajuste foi registrado.',
      kind: NotificationPaymentKind.adjustment,
      status: NotificationStatus.success,
      delivery: NotificationDelivery.localBellAndPush,
      saveInBell: true,
      sendPush: true,
      includeCurrentUser: true,
      tenantId: tenantId,
      companyId: tenantId,
      contractSummary: _contractSummary,
      contractTitle: _contractSummary,
      descricaoObjeto: _contractSummary,
      nomeDemanda: _contractSummary,
      action: wasEditing ? 'adjustment_payment_updated' : 'adjustment_payment_created',
      paymentDate: payment.paymentDate,
      paymentValue: payment.paymentValue,
      paymentMainValue: payment.paymentValue,
      paymentRetentionsValue: retentionsValue,
      paymentTotalValue: totalValue,
      paymentMeasurementNumber: adjustmentOrderText,
      paymentMeasurementOrder: adjustmentOrderText,
      paymentMeasurementDate: widget.selectedAdjustmentMeasurement.date,
      paymentMeasurementValue: _adjustmentValue,
      measurementNumber: adjustmentOrderText,
      measurementOrder: adjustmentOrderText,
      measurementDate: widget.selectedAdjustmentMeasurement.date,
      measurementValue: _adjustmentValue,
      extra: <String, dynamic>{
        'action': wasEditing
            ? 'adjustment_payment_updated'
            : 'adjustment_payment_created',
        'paymentType': 'adjustment_payment',
        'sourceModule': 'financial_payments_adjustment',
        'tenantId': tenantId,
        'companyId': tenantId,
        'summarySubjectContract': _contractSummary,
        'contractSummary': _contractSummary,
        'contractTitle': _contractSummary,
        'descricaoObjeto': _contractSummary,
        'nomeDemanda': _contractSummary,
        'adjustmentId': _adjustmentId,
        'adjustmentOrder': adjustmentOrderText,
        'paymentAdjustmentOrder': adjustmentOrderText,
        'fundingSourceLabel': payment.fundingSourceLabel,
        'paymentValue': payment.paymentValue,
        'paymentMainValue': payment.paymentValue,
        'inssPaymentValue': payment.inssPaymentValue,
        'irpfPaymentValue': payment.irpfPaymentValue,
        'issPaymentValue': payment.issPaymentValue,
        'paymentRetentionsValue': retentionsValue,
        'paymentTotalValue': totalValue,
      },
    );
  }

  Future<void> _notifyPaymentDeleted({
    required AdjustmentPaidData payment,
  }) async {
    if (!mounted) return;

    final tenantId = _activeTenantId();

    if (tenantId == null || tenantId.isEmpty) return;

    final adjustmentOrderText =
    payment.adjustmentOrder?.toString().trim().isNotEmpty == true
        ? payment.adjustmentOrder.toString().trim()
        : _adjustmentOrder?.toString().trim() ?? '';

    final paymentValue = _roundMoney(payment.paymentValue ?? 0.0);

    final retentionsValue = _roundMoney(
      _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );

    final totalValue = _roundMoney(paymentValue + retentionsValue);

    final title = adjustmentOrderText.isNotEmpty
        ? 'Pagamento do reajuste $adjustmentOrderText excluído'
        : 'Pagamento de reajuste excluído';

    await NotificationPayments.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: _contractSummary,
      details: 'O pagamento do reajuste foi excluído.',
      kind: NotificationPaymentKind.adjustment,
      status: NotificationStatus.warning,
      delivery: NotificationDelivery.localBellAndPush,
      saveInBell: true,
      sendPush: true,
      includeCurrentUser: true,
      tenantId: tenantId,
      companyId: tenantId,
      contractSummary: _contractSummary,
      contractTitle: _contractSummary,
      descricaoObjeto: _contractSummary,
      nomeDemanda: _contractSummary,
      action: 'adjustment_payment_deleted',
      paymentDate: payment.paymentDate,
      paymentValue: payment.paymentValue,
      paymentMainValue: payment.paymentValue,
      paymentRetentionsValue: retentionsValue,
      paymentTotalValue: totalValue,
      paymentMeasurementNumber: adjustmentOrderText,
      paymentMeasurementOrder: adjustmentOrderText,
      paymentMeasurementDate: widget.selectedAdjustmentMeasurement.date,
      paymentMeasurementValue: _adjustmentValue,
      measurementNumber: adjustmentOrderText,
      measurementOrder: adjustmentOrderText,
      measurementDate: widget.selectedAdjustmentMeasurement.date,
      measurementValue: _adjustmentValue,
      extra: <String, dynamic>{
        'action': 'adjustment_payment_deleted',
        'paymentType': 'adjustment_payment',
        'sourceModule': 'financial_payments_adjustment',
        'tenantId': tenantId,
        'companyId': tenantId,
        'summarySubjectContract': _contractSummary,
        'contractSummary': _contractSummary,
        'contractTitle': _contractSummary,
        'descricaoObjeto': _contractSummary,
        'nomeDemanda': _contractSummary,
        'adjustmentId': _adjustmentId,
        'adjustmentOrder': adjustmentOrderText,
        'paymentAdjustmentOrder': adjustmentOrderText,
        'fundingSourceLabel': payment.fundingSourceLabel,
        'paymentValue': payment.paymentValue,
        'paymentMainValue': payment.paymentValue,
        'inssPaymentValue': payment.inssPaymentValue,
        'irpfPaymentValue': payment.irpfPaymentValue,
        'issPaymentValue': payment.issPaymentValue,
        'paymentRetentionsValue': retentionsValue,
        'paymentTotalValue': totalValue,
      },
    );
  }

  Future<void> _savePayment({
    required AdjustmentPaidCubit cubit,
    required AdjustmentPaidData? selected,
    required List<Attachment> attachments,
  }) async {
    final date = _parseDate(_dateCtrl.text);
    final value = _parseCurrency(_valueCtrl.text);

    final inssDate = _parseOptionalDate(_inssDateCtrl.text);
    final inssValue = _parseOptionalCurrency(_inssValueCtrl.text);

    final irpfDate = _parseOptionalDate(_irpfDateCtrl.text);
    final irpfValue = _parseOptionalCurrency(_irpfValueCtrl.text);

    final issDate = _parseOptionalDate(_issDateCtrl.text);
    final issValue = _parseOptionalCurrency(_issValueCtrl.text);

    if (date == null) {
      await _showLocalPaymentError(
        'Informe uma data de pagamento válida.',
      );
      return;
    }

    final wasEditing = selected?.id?.trim().isNotEmpty == true;

    final data = AdjustmentPaidData(
      id: selected?.id,
      contractId: _contractId,
      adjustmentId: _adjustmentId,
      adjustmentOrder: _adjustmentOrder,
      fundingSourceId: _fonteCtrl.text.trim(),
      fundingSourceLabel: _fonteCtrl.text.trim(),
      paymentDate: date,
      paymentValue: value,
      inssPaymentDate: inssDate,
      inssPaymentValue: inssValue,
      irpfPaymentDate: irpfDate,
      irpfPaymentValue: irpfValue,
      issPaymentDate: issDate,
      issPaymentValue: issValue,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      attachments: attachments.isEmpty ? null : List<Attachment>.from(attachments),
    );

    try {
      await cubit.saveOrUpdatePayment(
        contract: widget.contractData,
        adjustment: widget.selectedAdjustmentMeasurement,
        payment: data,
      );

      await _notifyPaymentSaved(
        payment: data,
        wasEditing: wasEditing,
      );

      await _notifyParentPaymentsChanged();

      if (!mounted) return;

      cubit.select(null);
      _fillFromPayment(null);
    } catch (e) {
      if (!mounted) return;

      await _showLocalPaymentError(e.toString());
    }
  }

  Future<void> _deletePayment({
    required AdjustmentPaidCubit cubit,
    required AdjustmentPaidData payment,
  }) async {
    final id = payment.id?.trim();

    if (id == null || id.isEmpty) return;

    try {
      await cubit.deletePayment(
        contract: widget.contractData,
        adjustment: widget.selectedAdjustmentMeasurement,
        payment: payment,
      );

      await _notifyPaymentDeleted(payment: payment);

      await _notifyParentPaymentsChanged();

      if (!mounted) return;

      cubit.select(null);
      _fillFromPayment(null);
    } catch (e) {
      if (!mounted) return;

      await _showLocalPaymentError(e.toString());
    }
  }

  Future<void> _uploadAttachment({
    required AdjustmentPaidCubit cubit,
    required AdjustmentPaidData? selected,
  }) async {
    final selectedPayment = selected;

    if (selectedPayment == null) return;

    final paymentId = selectedPayment.id?.trim() ?? '';

    if (paymentId.isEmpty) return;

    try {
      await cubit.pickAndUploadAttachment(
        contract: widget.contractData,
        adjustment: widget.selectedAdjustmentMeasurement,
        payment: selectedPayment,
      );

      await _notifyParentPaymentsChanged();
    } catch (e) {
      if (!mounted) return;

      await _showLocalPaymentError(e.toString());
    }
  }

  Future<void> _deleteAttachment({
    required AdjustmentPaidCubit cubit,
    required AdjustmentPaidData? selected,
    required List<Attachment> attachments,
    required int index,
  }) async {
    final selectedPayment = selected;

    if (selectedPayment == null) return;

    if (index < 0 || index >= attachments.length) return;

    final paymentId = selectedPayment.id?.trim() ?? '';

    if (paymentId.isEmpty) return;

    try {
      await cubit.deleteAttachment(
        contract: widget.contractData,
        adjustment: widget.selectedAdjustmentMeasurement,
        payment: selectedPayment,
        attachment: attachments[index],
      );

      await _notifyParentPaymentsChanged();
    } catch (e) {
      if (!mounted) return;

      await _showLocalPaymentError(e.toString());
    }
  }

  Future<bool> _renameAttachment({
    required AdjustmentPaidCubit cubit,
    required AdjustmentPaidData? selected,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final selectedPayment = selected;

    if (selectedPayment == null) return false;

    final paymentId = selectedPayment.id?.trim() ?? '';

    if (paymentId.isEmpty) return false;

    try {
      await cubit.renameAttachmentLabel(
        contract: widget.contractData,
        adjustment: widget.selectedAdjustmentMeasurement,
        payment: selectedPayment,
        oldItem: oldItem,
        newItem: newItem,
      );

      await _notifyParentPaymentsChanged();

      return true;
    } catch (e) {
      await _showLocalPaymentError(e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdjustmentPaidCubit, AdjustmentPaidState>(
      listenWhen: (previous, current) {
        final previousId = previous.selected?.id?.trim() ?? '';
        final currentId = current.selected?.id?.trim() ?? '';

        return previousId != currentId ||
            previous.selectedSideIndex != current.selectedSideIndex;
      },
      listener: (context, paymentState) {
        _fillFromPayment(paymentState.selected);
      },
      child: BlocBuilder<AdjustmentPaidCubit, AdjustmentPaidState>(
        builder: (context, paymentState) {
          return BlocBuilder<TenantCubit, TenantState>(
            builder: (context, tenantState) {
              final tenant = tenantState.tenantProfile;
              final fundingSources = tenantState.fundingSources;

              final bool companyConfigured = tenant != null;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cubit = context.read<AdjustmentPaidCubit>();
                  final tenantCubit = context.read<TenantCubit>();

                  final bool isSmallScreen = constraints.maxWidth < 700;
                  final double sideWidth =
                  isSmallScreen ? constraints.maxWidth : 300.0;

                  final double inputsWidth = responsiveInputWidth(
                    context: context,
                    itemsPerLine: 4,
                    reservedWidth: isSmallScreen ? 0.0 : sideWidth + 12.0,
                    spacing: 12.0,
                    margin: 12.0,
                    extraPadding: 24.0,
                    spaceBetweenReserved: 12.0,
                  );

                  if (paymentState.status == AdjustmentPaidStatus.loading &&
                      paymentState.payments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingTreeDots(size: 90),
                      ),
                    );
                  }

                  if (paymentState.status == AdjustmentPaidStatus.failure &&
                      paymentState.payments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          paymentState.error ?? 'Erro ao carregar pagamentos.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SipGedTheme.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }

                  final selected = paymentState.selected;
                  final attachments =
                      selected?.attachments ?? const <Attachment>[];

                  final totalPago = _sumPaymentTotalValues(
                    paymentState.payments,
                  );

                  final saldo = _roundMoney(_adjustmentValue - totalPago);
                  final retencoesFormulario = _totalRetencoesFormulario();

                  final camposWrap = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _sectionLabel('Dados principais do pagamento'),
                      _input(
                        inputsWidth,
                        _orderCtrl,
                        'Ordem do reajuste',
                        enabled: false,
                      ),
                      DropDownChange(
                        showSpecialAlways: true,
                        key: ValueKey<String>(
                          'adjustment-payment-funding-$_fundingNonce-${_fonteCtrl.text}',
                        ),
                        width: inputsWidth,
                        labelText: 'Fonte de recurso',
                        controller: _fonteCtrl,
                        enabled: widget.isEditable && companyConfigured,
                        tooltipMessage: !companyConfigured
                            ? 'Configure o contratante no setup do sistema'
                            : null,
                        items: fundingSources,
                        specialItemLabel: 'Adicionar fonte',
                        menuMaxHeight: 260,
                        onChanged: (label) {
                          final selectedLabel = _s(label);

                          if (selectedLabel.isEmpty) {
                            _fonteCtrl.clear();
                            _validate();
                            return;
                          }

                          final selectedFunding = _findByLabel(
                            fundingSources,
                            selectedLabel,
                          );

                          if (selectedFunding == null) return;

                          _fonteCtrl.text = selectedFunding;
                          _validate();
                        },
                        onCreateNewItem: companyConfigured
                            ? (label) async {
                          final newLabel = _s(label);

                          if (newLabel.isEmpty) return;

                          final created = await tenantCubit
                              .createFundingSource(newLabel);

                          if (!mounted || created == null) return;

                          setState(() {
                            _fonteCtrl.text = created;
                            _fundingNonce++;
                          });

                          _validate();
                        }
                            : null,
                        onEditItem: companyConfigured
                            ? (ctx, oldLabel) async {
                          final oldValue = _s(oldLabel);

                          if (oldValue.isEmpty) return;

                          final target = _findByLabel(
                            fundingSources,
                            oldValue,
                          );

                          if (target == null) return;

                          final newLabel = await _askNewLabel(
                            ctx,
                            title: 'Editar fonte de recurso',
                            initialValue: oldValue,
                            labelText: 'Nome da fonte',
                          );

                          if (!mounted || newLabel == null) return;

                          final updated =
                          await tenantCubit.updateFundingSourceName(
                            target,
                            newLabel,
                          );

                          if (!mounted || updated == null) return;

                          setState(() {
                            if (_fonteCtrl.text.trim().toLowerCase() ==
                                oldValue.toLowerCase()) {
                              _fonteCtrl.text = updated;
                            }

                            _fundingNonce++;
                          });

                          _validate();
                        }
                            : null,
                        onDeleteItem: companyConfigured
                            ? (ctx, label) async {
                          final value = _s(label);

                          if (value.isEmpty) return;

                          final target = _findByLabel(
                            fundingSources,
                            value,
                          );

                          if (target == null) return;

                          await tenantCubit.deleteFundingSource(target);

                          if (!mounted) return;

                          setState(() {
                            if (_fonteCtrl.text.trim().toLowerCase() ==
                                value.toLowerCase()) {
                              _fonteCtrl.clear();
                            }

                            _fundingNonce++;
                          });

                          _validate();
                        }
                            : null,
                      ),
                      _dateInput(
                        keyId: 'payment',
                        width: inputsWidth,
                        controller: _dateCtrl,
                        label: 'Data do pagamento',
                        initialValue: _parseOptionalDate(_dateCtrl.text),
                      ),
                      _input(
                        inputsWidth,
                        _valueCtrl,
                        'Valor do pagamento',
                        money: true,
                      ),
                      _sectionLabel('Retenções / tributos'),
                      _dateInput(
                        keyId: 'inss',
                        width: inputsWidth,
                        controller: _inssDateCtrl,
                        label: 'Data pagamento INSS',
                        initialValue: _parseOptionalDate(_inssDateCtrl.text),
                      ),
                      _input(
                        inputsWidth,
                        _inssValueCtrl,
                        'Valor INSS',
                        money: true,
                      ),
                      _dateInput(
                        keyId: 'irpf',
                        width: inputsWidth,
                        controller: _irpfDateCtrl,
                        label: 'Data pagamento IRPF',
                        initialValue: _parseOptionalDate(_irpfDateCtrl.text),
                      ),
                      _input(
                        inputsWidth,
                        _irpfValueCtrl,
                        'Valor IRPF',
                        money: true,
                      ),
                      _dateInput(
                        keyId: 'iss',
                        width: inputsWidth,
                        controller: _issDateCtrl,
                        label: 'Data pagamento ISS',
                        initialValue: _parseOptionalDate(_issDateCtrl.text),
                      ),
                      _input(
                        inputsWidth,
                        _issValueCtrl,
                        'Valor ISS',
                        money: true,
                      ),
                      _sectionLabel('Observações'),
                      _input(
                        inputsWidth,
                        _noteCtrl,
                        'Observação',
                      ),
                    ],
                  );

                  final resumo = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SipGedTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: SipGedTheme.blackAlpha(0.06),
                      ),
                    ),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        PaymentSummaryText(
                          label: 'Valor do reajuste',
                          value: SipGedFormatMoney.doubleToText(
                            _adjustmentValue,
                          ),
                        ),
                        PaymentSummaryText(
                          label: 'Total pago',
                          value: SipGedFormatMoney.doubleToText(totalPago),
                        ),
                        PaymentSummaryText(
                          label: 'Saldo',
                          value: SipGedFormatMoney.doubleToText(saldo),
                          color: saldo < 0 && !_moneyIsZero(saldo)
                              ? SipGedTheme.danger
                              : _moneyIsZero(saldo)
                              ? SipGedTheme.success
                              : SipGedTheme.textDark,
                        ),
                        PaymentSummaryText(
                          label: 'Retenções informadas',
                          value: SipGedFormatMoney.doubleToText(
                            retencoesFormulario,
                          ),
                          color: retencoesFormulario > 0
                              ? SipGedTheme.secondaryColor
                              : SipGedTheme.textDark,
                        ),
                      ],
                    ),
                  );

                  final botoes = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(
                          selected == null ? 'Salvar' : 'Atualizar',
                        ),
                        onPressed: _formOk && widget.isEditable
                            ? () async {
                          await _savePayment(
                            cubit: cubit,
                            selected: selected,
                            attachments: attachments,
                          );
                        }
                            : null,
                      ),
                      const SizedBox(width: 12),
                      if (selected != null)
                        TextButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Limpar'),
                          onPressed: () {
                            cubit.select(null);
                            _fillFromPayment(null);
                          },
                        ),
                    ],
                  );

                  final corpo = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      camposWrap,
                      const SizedBox(height: 12),
                      botoes,
                      const SizedBox(height: 12),
                      _AdjustmentPaymentsList(
                        payments: paymentState.payments,
                        selected: selected,
                        onSelect: (payment) {
                          cubit.select(payment);
                          _fillFromPayment(payment);
                        },
                        onDelete: widget.isEditable
                            ? (payment) async {
                          await _deletePayment(
                            cubit: cubit,
                            payment: payment,
                          );
                        }
                            : null,
                      ),
                      const SizedBox(height: 10),
                      resumo,
                    ],
                  );

                  final side = BoxListFiles(
                    title: 'Arquivos do Pagamento',
                    items: attachments,
                    selectedIndex: paymentState.selectedSideIndex,
                    width: sideWidth,
                    onAddPressed: widget.isEditable && selected?.id != null
                        ? () async {
                      await _uploadAttachment(
                        cubit: cubit,
                        selected: selected,
                      );
                    }
                        : null,
                    onTap: (index) {
                      cubit.selectSideIndex(index);
                    },
                    onDelete: widget.isEditable && selected?.id != null
                        ? (index) async {
                      await _deleteAttachment(
                        cubit: cubit,
                        selected: selected,
                        attachments: attachments,
                        index: index,
                      );
                    }
                        : null,
                    enableRename: widget.isEditable && selected?.id != null,
                    onItemsChanged: null,
                    loading: paymentState.uploading,
                    uploadProgress: paymentState.uploadProgress,
                    onRenamePersist: selected?.id == null
                        ? null
                        : ({
                      required int index,
                      required Attachment oldItem,
                      required Attachment newItem,
                    }) async {
                      return _renameAttachment(
                        cubit: cubit,
                        selected: selected,
                        oldItem: oldItem,
                        newItem: newItem,
                      );
                    },
                  );

                  if (isSmallScreen) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        side,
                        const SizedBox(height: 12),
                        corpo,
                      ],
                    );
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      side,
                      const SizedBox(width: 12),
                      Expanded(child: corpo),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdjustmentPaymentsList extends StatelessWidget {
  const _AdjustmentPaymentsList({
    required this.payments,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final List<AdjustmentPaidData> payments;
  final AdjustmentPaidData? selected;
  final ValueChanged<AdjustmentPaidData> onSelect;
  final ValueChanged<AdjustmentPaidData>? onDelete;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return v;
  }

  double _totalRetencoes(AdjustmentPaidData payment) {
    return _positive(payment.inssPaymentValue) +
        _positive(payment.irpfPaymentValue) +
        _positive(payment.issPaymentValue);
  }

  double _totalPagamento(AdjustmentPaidData payment) {
    return _positive(payment.paymentValue) + _totalRetencoes(payment);
  }

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SipGedTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SipGedTheme.blackAlpha(0.06),
          ),
        ),
        child: Text(
          'Nenhum pagamento cadastrado para este reajuste.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SipGedTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SipGedTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SipGedTheme.blackAlpha(0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < payments.length; index++) ...[
            _AdjustmentPaymentTile(
              payment: payments[index],
              selected: selected?.id == payments[index].id,
              dateText: _formatDate(payments[index].paymentDate),
              totalRetencoes: _totalRetencoes(payments[index]),
              totalPagamento: _totalPagamento(payments[index]),
              onTap: () => onSelect(payments[index]),
              onDelete: onDelete == null
                  ? null
                  : () => onDelete?.call(payments[index]),
            ),
            if (index < payments.length - 1)
              Divider(
                height: 1,
                color: SipGedTheme.blackAlpha(0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _AdjustmentPaymentTile extends StatelessWidget {
  const _AdjustmentPaymentTile({
    required this.payment,
    required this.selected,
    required this.dateText,
    required this.totalRetencoes,
    required this.totalPagamento,
    required this.onTap,
    required this.onDelete,
  });

  final AdjustmentPaidData payment;
  final bool selected;
  final String dateText;
  final double totalRetencoes;
  final double totalPagamento;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = SipGedTheme.surfaceLight;

    final borderColor = selected
        ? SipGedTheme.secondaryColor.withValues(alpha: 0.55)
        : SipGedTheme.blackAlpha(0.045);

    final iconColor =
    selected ? SipGedTheme.secondaryColor : SipGedTheme.textMuted;

    final iconBackground = selected
        ? SipGedTheme.secondaryColor.withValues(alpha: 0.08)
        : SipGedTheme.blackAlpha(0.035);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(selected ? 8 : 0),
        border: Border.all(
          color: borderColor,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: SipGedTheme.blackAlpha(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 5 : 0,
                  decoration: BoxDecoration(
                    color: SipGedTheme.secondaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 14 : 12,
                      vertical: selected ? 12 : 10,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: selected ? 38 : 34,
                          height: selected ? 38 : 34,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                              color: SipGedTheme.secondaryColor
                                  .withValues(alpha: 0.28),
                            )
                                : null,
                          ),
                          child: Icon(
                            Icons.payments_outlined,
                            size: selected ? 21 : 19,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                payment.fundingSourceLabel ??
                                    'Fonte não informada',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: selected
                                      ? SipGedTheme.secondaryColor
                                      : SipGedTheme.textDark,
                                ),
                              ),
                              Text(
                                dateText,
                                style: const TextStyle(
                                  color: SipGedTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                SipGedFormatMoney.doubleToText(totalPagamento),
                                style: TextStyle(
                                  color: selected
                                      ? SipGedTheme.secondaryColor
                                      : SipGedTheme.textDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (totalRetencoes > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SipGedTheme.secondaryColor
                                        .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: SipGedTheme.secondaryColor
                                          .withValues(alpha: 0.14),
                                    ),
                                  ),
                                  child: Text(
                                    'Retenções: ${SipGedFormatMoney.doubleToText(totalRetencoes)}',
                                    style: const TextStyle(
                                      color: SipGedTheme.secondaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Apagar pagamento',
                            onPressed: onDelete,
                            style: IconButton.styleFrom(
                              backgroundColor: selected
                                  ? SipGedTheme.danger.withValues(alpha: 0.08)
                                  : Colors.transparent,
                            ),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: SipGedTheme.danger,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}