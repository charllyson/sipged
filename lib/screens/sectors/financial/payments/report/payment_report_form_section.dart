import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sisged/_utils/responsive_utils.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_widgets/mask_class.dart';

import '../../../../../_widgets/archives/pdf/web_pdf_controller.dart';
import '../../../../../_widgets/archives/pdf/web_pdf_widget.dart';
import '../../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../../_datas/sectors/financial/payments/reports/payments_reports_data.dart';
import '../../../../../_widgets/formats/input_formatters.dart';

class PaymentReportFormSection extends StatelessWidget {
  final TextEditingController orderPaymentReportController;
  final TextEditingController processNumberPaymentReportController;
  final TextEditingController valuePaymentReportController;
  final TextEditingController statePaymentReportController;
  final TextEditingController observationPaymentReportController;
  final TextEditingController bankPaymentReportController;
  final TextEditingController electronicTicketPaymentReportController;
  final TextEditingController fontPaymentReportController;
  final TextEditingController datePaymentReportController;
  final TextEditingController taxPaymentReportController;

  final PaymentsReportData? selectedPaymentReportData;
  final String? currentPaymentReportId;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;
  final ContractData? contractData;
  final Future<void> Function(String url) onUploadSaveToFirestore;

  const PaymentReportFormSection({
    super.key,
    required this.orderPaymentReportController,
    required this.processNumberPaymentReportController,
    required this.valuePaymentReportController,
    required this.statePaymentReportController,
    required this.observationPaymentReportController,
    required this.bankPaymentReportController,
    required this.electronicTicketPaymentReportController,
    required this.fontPaymentReportController,
    required this.datePaymentReportController,
    required this.taxPaymentReportController,
    required this.selectedPaymentReportData,
    required this.currentPaymentReportId,
    required this.isEditable,
    required this.isSaving,
    required this.formValidated,
    required this.onSaveOrUpdate,
    required this.onClear,
    required this.contractData,
    required this.onUploadSaveToFirestore,
  });

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: 100.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _input(BuildContext context, TextEditingController controller, String label,
      {bool enabled = true,
        bool tooltip = false,
        bool money = false,
        bool date = false,
        List<TextInputFormatter>? mask}) {
    List<TextInputFormatter> formatters = [];

    if (money) {
      formatters = [
        CurrencyInputFormatter(
          leadingSymbol: 'R\$ ',
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
    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _input(context, orderPaymentReportController, 'Ordem da medição', enabled: false, tooltip: true),
        _input(context, processNumberPaymentReportController, 'Nº processo do pagamento da medição', mask: [processoMaskFormatter]),
        _input(context, valuePaymentReportController, 'Valor do pagamento da medição', money: true),
        _input(context, statePaymentReportController, 'Estado do pagamento da medição'),
        _input(context, observationPaymentReportController, 'Observação do pagamento da medição'),
        _input(context, bankPaymentReportController, 'Nº do banco do pagamento da medição'),
        _input(context, electronicTicketPaymentReportController, 'Nº do boleto eletrônico do pagamento da medição'),
        _input(context, fontPaymentReportController, 'Fonte do pagamento da medição'),
        CustomDateField(
          width: getInputWidth(context),
          enabled: isEditable,
          controller: datePaymentReportController,
          initialValue: selectedPaymentReportData?.datePaymentReport,
          labelText: 'Data do pagamento da Medição',
          onChanged: (date) {
            selectedPaymentReportData?.datePaymentReport = date;
          },
        ),
        _input(context, taxPaymentReportController, 'Imposto do pagamento da medição', money: true),
      ],
    );

    final botoes = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.save),
          label: Text(currentPaymentReportId != null ? 'Atualizar' : 'Salvar'),
          onPressed: formValidated && isEditable && !isSaving ? onSaveOrUpdate : null,
        ),
        const SizedBox(width: 12),
        if (currentPaymentReportId != null)
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Limpar'),
            onPressed: onClear,
          ),
      ],
    );

    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        camposWrap,
        const SizedBox(height: 12),
        botoes,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentPaymentReportId != null && selectedPaymentReportData != null)
                _buildPdfWidget(),
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentPaymentReportId != null && selectedPaymentReportData != null)
                _buildPdfWidget(),
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfWidget() {
    return WebPdfWidgetGeneric(
      key: Key(currentPaymentReportId!),
      type: PDFType.paymentReport,
      contractData: contractData!,
      specificData: selectedPaymentReportData!,
      onUploadSaveToFirestore: onUploadSaveToFirestore,

    );
  }
}
