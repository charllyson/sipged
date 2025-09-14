import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:siged/screens/sectors/financial/payments/revision/payment_revision_controller.dart';

import 'package:siged/_services/pdf/web_pdf_controller.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_services/pdf/web_pdf_widget.dart';

import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

class PaymentRevisionFormSection extends StatelessWidget {
  const PaymentRevisionFormSection({super.key});

  double _inputWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 1400 ? 260 : w >= 1100 ? 220 : w >= 900 ? 200 : 180;
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
    final c = context.watch<PaymentsRevisionController>();
    final selected = c.selected;

    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _input(
          context,
          controller: c.orderCtrl,
          label: 'Ordem do pagamento da revisão',
          enabled: false,
          tooltip: true,
        ),
        _input(
          context,
          controller: c.processCtrl,
          label: 'Nº processo de pagamento da revisão',
          mask: [processoMaskFormatter],
        ),
        _input(
          context,
          controller: c.valueCtrl,
          label: 'Valor do pagamento da revisão',
          money: true,
        ),
        _input(
          context,
          controller: c.stateCtrl,
          label: 'Estado do pagamento da revisão',
        ),
        _input(
          context,
          controller: c.observationCtrl,
          label: 'Observação do pagamento da revisão',
        ),
        _input(
          context,
          controller: c.bankCtrl,
          label: 'Nº do banco do pagamento da revisão',
        ),
        _input(
          context,
          controller: c.electronicTicketCtrl,
          label: 'Nº do boleto eletrônico do pagamento da revisão',
        ),
        _input(
          context,
          controller: c.fontCtrl,
          label: 'Fonte do pagamento da revisão',
        ),
        CustomDateField(
          width: _inputWidth(context),
          enabled: c.isEditable,
          controller: c.dateCtrl,
          initialValue: selected?.datePaymentRevision,
          labelText: 'Data do pagamento da revisão do reajuste',
          onChanged: (date) {
            if (c.selected != null) {
              c.selected!.datePaymentRevision = date;
            }
          },
        ),
        _input(
          context,
          controller: c.taxCtrl,
          label: 'Imposto do pagamento da revisão',
          money: true,
        ),
      ],
    );

    final pdfWidget = (selected?.idRevisionPayment != null && c.contract != null)
        ? SizedBox(
      width: 100,
      child: WebPdfWidgetGeneric<PaymentsRevisionsData>(
        key: Key(selected!.idRevisionPayment!),
        type: PDFType.paymentsRevision,
        contractData: c.contract!,
        specificData: selected,
      ),
    )
        : const SizedBox.shrink();

    final botoes = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (selected?.idRevisionPayment != null)
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
                    content: const Text('Deseja salvar este pagamento da revisão?'),
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
          label: Text(selected?.idRevisionPayment != null ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected?.idRevisionPayment != null) pdfWidget,
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
