import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';

import 'package:sisged/_widgets/archives/pdf/web_pdf_controller.dart';
import 'payment_adjustment_controller.dart';

import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_utils/mask_class.dart';
import 'package:sisged/_utils/formats/input_formatters.dart';
import 'package:sisged/_widgets/archives/pdf/web_pdf_widget.dart';

import 'package:sisged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';

class PaymentAdjustmentFormSection extends StatelessWidget {
  const PaymentAdjustmentFormSection({super.key});

  double _inputWidth(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    return size >= 1400 ? 260 : size >= 1100 ? 220 : size >= 900 ? 200 : 180;
  }

  Widget _input(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
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
      width: _inputWidth(context),
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
    final c = context.watch<PaymentsAdjustmentController>();
    final selected = c.selected;

    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _input(
          context,
          controller: c.orderCtrl,
          label: 'Ordem do reajuste',
          enabled: false,
          tooltip: true,
        ),
        _input(
          context,
          controller: c.processCtrl,
          label: 'Nº processo de pagamento do reajuste',
          mask: [processoMaskFormatter],
        ),
        _input(
          context,
          controller: c.valueCtrl,
          label: 'Valor do pagamento do reajuste',
          money: true,
        ),
        _input(
          context,
          controller: c.stateCtrl,
          label: 'Estado do pagamento do reajuste',
        ),
        _input(
          context,
          controller: c.observationCtrl,
          label: 'Observação do pagamento do reajuste',
        ),
        _input(
          context,
          controller: c.bankCtrl,
          label: 'Nº do banco do pagamento do reajuste',
        ),
        _input(
          context,
          controller: c.electronicTicketCtrl,
          label: 'Nº do boleto eletrônico do pagamento do reajuste',
        ),
        _input(
          context,
          controller: c.fontCtrl,
          label: 'Fonte do pagamento do reajuste',
        ),
        CustomDateField(
          width: _inputWidth(context),
          enabled: c.isEditable,
          controller: c.dateCtrl,
          initialValue: selected?.datePaymentAdjustment,
          labelText: 'Data do pagamento do reajustamento da Medição',
          onChanged: (date) {
            if (c.selected != null) {
              c.selected!.datePaymentAdjustment = date;
            }
          },
        ),
        _input(
          context,
          controller: c.taxCtrl,
          label: 'Imposto do pagamento do reajuste',
          money: true,
        ),
      ],
    );

    final pdfWidget = (selected?.idPaymentAdjustment != null && c.contract != null)
        ? SizedBox(
      width: 100,
      child: WebPdfWidgetGeneric<PaymentsAdjustmentsData>(
        key: Key(selected!.idPaymentAdjustment!),
        type: PDFType.paymentsAdjustment,
        contractData: c.contract!,
        specificData: selected,
        // se seu componente exigir o bloc, descomente:
        // paymentsAdjustmentBloc: c.bloc,
      ),
    )
        : const SizedBox.shrink();

    final botoes = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (selected?.idPaymentAdjustment != null)
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Limpar'),
            onPressed: c.createNew,
          ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: c.formValidated && !c.isSaving
              ? () async {
            await c.saveOrUpdate(
              onConfirm: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmação'),
                    content: const Text('Deseja salvar este pagamento de reajuste?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                );
                return ok == true;
              },
              onSuccessSnack: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pagamento salvo com sucesso!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              onErrorSnack: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Falha ao salvar pagamento.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            );
          }
              : null,
          icon: const Icon(Icons.save),
          label: Text(selected?.idPaymentAdjustment != null ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected?.idPaymentAdjustment != null) pdfWidget,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              camposWrap,
              const SizedBox(height: 12),
              botoes,
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 700;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(12),
            child: isSmall
                ? body
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: body)],
            ),
          );
        },
      ),
    );
  }
}
