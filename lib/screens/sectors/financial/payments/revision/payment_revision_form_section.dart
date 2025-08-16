import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_utils/responsive_utils.dart';

import '../../../../../_blocs/sectors/financial/payments/payments_revision_bloc.dart';
import '../../../../../_widgets/archives/pdf/pdf_icon_action.dart';
import '../../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../../_datas/sectors/financial/payments/payments_revisions_data.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../../_widgets/formats/input_formatters.dart';
import '../../../../../_widgets/mask_class.dart';
import '../../../../../_widgets/validates/form_validation_mixin.dart';

class PaymentRevisionFormSection extends StatefulWidget {

  final TextEditingController orderPaymentRevisionController;
  final TextEditingController processPaymentRevisionController;
  final TextEditingController valuePaymentRevisionController;
  final TextEditingController statePaymentRevisionController;
  final TextEditingController observationPaymentRevisionController;
  final TextEditingController bankPaymentRevisionController;
  final TextEditingController electronicTicketPaymentRevisionController;
  final TextEditingController fontPaymentRevisionController;
  final TextEditingController datePaymentRevisionController;
  final TextEditingController taxPaymentRevisionController;

  final PaymentsRevisionsData? selectedPaymentsRevisionData;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;
  final ContractData? contractData;
  final PaymentsRevisionBloc paymentRevisionBloc;

  const PaymentRevisionFormSection({
    super.key,
    required this.orderPaymentRevisionController,
    required this.processPaymentRevisionController,
    required this.valuePaymentRevisionController,
    required this.statePaymentRevisionController,
    required this.observationPaymentRevisionController,
    required this.bankPaymentRevisionController,
    required this.electronicTicketPaymentRevisionController,
    required this.fontPaymentRevisionController,
    required this.datePaymentRevisionController,
    required this.taxPaymentRevisionController,

    required this.selectedPaymentsRevisionData,
    required this.isEditable,
    required this.isSaving,
    required this.formValidated,
    required this.onSaveOrUpdate,
    required this.onClear,
    required this.contractData,
    required this.paymentRevisionBloc,
  });

  @override
  State<PaymentRevisionFormSection> createState() => _PaymentRevisionFormSectionState();
}

class _PaymentRevisionFormSectionState extends State<PaymentRevisionFormSection> with FormValidationMixin {

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
            _input(widget.orderPaymentRevisionController, 'Ordem do pagamento da revião', enabled: false, tooltip: true),
            _input(widget.processPaymentRevisionController, 'Nº processo de pagamento da revisão', mask: [processoMaskFormatter]),
            _input(widget.valuePaymentRevisionController, 'Valor do pagamento da revião', money: true),
            _input(widget.statePaymentRevisionController, 'Estado do pagamento da revião'),
            _input(widget.observationPaymentRevisionController, 'Observação do pagamento da revião'),
            _input(widget.bankPaymentRevisionController, 'Nº do banco do pagamento da revião'),
            _input(widget.electronicTicketPaymentRevisionController, 'Nº do boleto eletrônico do pagamento da revião'),
            _input(widget.fontPaymentRevisionController, 'Fonte do pagamento da revião'),
            CustomDateField(
              width: getInputWidth(context),
              enabled: widget.isEditable,
              controller: widget.datePaymentRevisionController,
              initialValue: widget.selectedPaymentsRevisionData?.datePaymentRevision,
              labelText: 'Data do pagamento da revião do reajuste',
              validator: (_) => validateDate(stringToDate(widget.datePaymentRevisionController.text)),
              onChanged: (date) {
                widget.selectedPaymentsRevisionData?.datePaymentRevision = date;
                setState(() {});
              },
            ),
            _input(widget.taxPaymentRevisionController, 'Imposto do pagamento da revisão do reajuste', money: true),
          ],
        );

        final pdfWidget = widget.selectedPaymentsRevisionData?.idRevisionPayment != null
            ? SizedBox(
          width: 100,
          child: PdfFileIconActionGeneric<PaymentsRevisionsData>(
            key: Key(widget.selectedPaymentsRevisionData!.idRevisionPayment!),
            type: PDFType.paymentsRevision,
            contractData: widget.contractData!,
            specificData: widget.selectedPaymentsRevisionData,
            paymentsRevisionBloc: widget.paymentRevisionBloc,
          ),
        )
            : const SizedBox.shrink();


        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.selectedPaymentsRevisionData?.idRevisionPayment != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: widget.onClear,
              ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: widget.formValidated && !widget.isSaving ? widget.onSaveOrUpdate : null,
              icon: const Icon(Icons.save),
              label: Text(widget.selectedPaymentsRevisionData?.idRevisionPayment != null ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );

        final body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedPaymentsRevisionData?.idRevisionPayment != null) pdfWidget,
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