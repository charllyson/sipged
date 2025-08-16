import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_utils/responsive_utils.dart';

import '../../../../../_blocs/sectors/financial/payments/payments_adjustment_bloc.dart';
import '../../../../../_widgets/archives/pdf/pdf_icon_action.dart';
import '../../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../../_datas/sectors/financial/payments/payments_adjustments_data.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../../_widgets/formats/input_formatters.dart';
import '../../../../../_widgets/mask_class.dart';
import '../../../../../_widgets/validates/form_validation_mixin.dart';

class PaymentAdjustmentFormSection extends StatefulWidget {

  final TextEditingController orderPaymentAdjustmentController;
  final TextEditingController processPaymentAdjustmentController;
  final TextEditingController valuePaymentAdjustmentController;
  final TextEditingController statePaymentAdjustmentController;
  final TextEditingController observationPaymentAdjustmentController;
  final TextEditingController bankPaymentAdjustmentController;
  final TextEditingController electronicTicketPaymentAdjustmentController;
  final TextEditingController fontPaymentAdjustmentController;
  final TextEditingController datePaymentAdjustmentController;
  final TextEditingController taxPaymentAdjustmentController;

  final PaymentsAdjustmentsData? selectedPaymentsAdjustmentData;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;
  final ContractData? contractData;
  final PaymentsAdjustmentBloc paymentAdjustmentBloc;

  const PaymentAdjustmentFormSection({
    super.key,
    required this.orderPaymentAdjustmentController,
    required this.processPaymentAdjustmentController,
    required this.valuePaymentAdjustmentController,
    required this.statePaymentAdjustmentController,
    required this.observationPaymentAdjustmentController,
    required this.bankPaymentAdjustmentController,
    required this.electronicTicketPaymentAdjustmentController,
    required this.fontPaymentAdjustmentController,
    required this.datePaymentAdjustmentController,
    required this.taxPaymentAdjustmentController,

    required this.selectedPaymentsAdjustmentData,
    required this.isEditable,
    required this.isSaving,
    required this.formValidated,
    required this.onSaveOrUpdate,
    required this.onClear,
    required this.contractData,
    required this.paymentAdjustmentBloc,
  });

  @override
  State<PaymentAdjustmentFormSection> createState() => _PaymentAdjustmentFormSectionState();
}

class _PaymentAdjustmentFormSectionState extends State<PaymentAdjustmentFormSection> with FormValidationMixin {

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 5,
      reservedWidth: 100.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _input(
      TextEditingController controller,
      String label, {
        bool enabled = true,
        bool tooltip = false,
        bool money = false,
        bool date = false,
        List<TextInputFormatter>? mask,
      }) {
    List<TextInputFormatter> formatters = [];

    if (money) {
      formatters = [
        CurrencyInputFormatter(
          leadingSymbol: 'R\$',
          useSymbolPadding: true,
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 2,
        ),
      ];
    } else if (date) {
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        TextInputMask(mask: '99/99/9999'),
      ];
    } else if (mask != null) {
      formatters = mask;
    }

    final textField = CustomTextField(
      width: getInputWidth(context),
      enabled: enabled,
      labelText: label,
      controller: controller,
      keyboardType: money
          ? TextInputType.number
          : (date ? TextInputType.datetime : TextInputType.text),
      inputFormatters: formatters,
    );

    if (tooltip) {
      return Tooltip(
        message: 'Este campo é calculado automaticamente.',
        child: textField,
      );
    }

    return textField;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;
        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(widget.orderPaymentAdjustmentController, 'Ordem do reajuste', enabled: false, tooltip: true),
            _input(widget.processPaymentAdjustmentController, 'Nº processo de pagamento do reajuste', mask: [processoMaskFormatter]),
            _input(widget.valuePaymentAdjustmentController, 'Valor do pagamento do reajuste', money: true),
            _input(widget.statePaymentAdjustmentController, 'Estado do pagamento do reajuste'),
            _input(widget.observationPaymentAdjustmentController, 'Observação do pagamento do reajuste'),
            _input(widget.bankPaymentAdjustmentController, 'Nº do banco do pagamento do reajuste'),
            _input(widget.electronicTicketPaymentAdjustmentController, 'Nº do boleto eletrônico do pagamento do reajuste'),
            _input(widget.fontPaymentAdjustmentController, 'Fonte do pagamento do reajuste'),
            CustomDateField(
              width: getInputWidth(context),
              enabled: widget.isEditable,
              controller: widget.datePaymentAdjustmentController,
              initialValue: widget.selectedPaymentsAdjustmentData?.datePaymentAdjustment,
              labelText: 'Data do pagamento do reajustamento da Medição',
              validator: (_) => validateDate(stringToDate(widget.datePaymentAdjustmentController.text)),
              onChanged: (date) {
                widget.selectedPaymentsAdjustmentData?.datePaymentAdjustment = date;
                setState(() {});
              },
            ),
            _input(widget.taxPaymentAdjustmentController, 'Imposto do pagamento do reajuste', money: true),
          ],
        );

        final pdfWidget = widget.selectedPaymentsAdjustmentData?.idPaymentAdjustment != null
            ? SizedBox(
          width: 100,
          child: PdfFileIconActionGeneric<PaymentsAdjustmentsData>(
            key: Key(widget.selectedPaymentsAdjustmentData!.idPaymentAdjustment!),
            type: PDFType.paymentsAdjustment,
            contractData: widget.contractData!,
            specificData: widget.selectedPaymentsAdjustmentData,
            paymentsAdjustmentBloc: widget.paymentAdjustmentBloc,
          ),
        )
            : const SizedBox.shrink();


        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.selectedPaymentsAdjustmentData?.idPaymentAdjustment != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: widget.onClear,
              ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: widget.formValidated && !widget.isSaving ? widget.onSaveOrUpdate : null,
              icon: const Icon(Icons.save),
              label: Text(widget.selectedPaymentsAdjustmentData?.idPaymentAdjustment != null ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );

        final body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedPaymentsAdjustmentData?.idPaymentAdjustment != null) pdfWidget,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  camposWrap,
                  botoes,
                ],
              ),
            ),
          ],
        );


        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(12),
            child: isSmallScreen
                ? body
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}