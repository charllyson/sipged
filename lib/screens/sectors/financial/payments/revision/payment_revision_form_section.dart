import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

class PaymentRevisionFormSection extends StatelessWidget {
  // --- Controllers de formulário
  final TextEditingController orderCtrl;
  final TextEditingController processCtrl;
  final TextEditingController valueCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController observationCtrl;
  final TextEditingController bankCtrl;
  final TextEditingController electronicTicketCtrl;
  final TextEditingController fontCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController taxCtrl;

  // --- Estado
  final PaymentsRevisionsData? selectedPaymentRevisionData;
  final String? currentPaymentRevisionId;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;

  // --- Dropdown ordem
  final List<String> orderNumberOptions;
  final Set<String> greyOrderItems;
  final void Function(String? value)? onChangedOrderNumber;

  // --- SideListBox (agora dinâmico)
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;

  const PaymentRevisionFormSection({
    super.key,
    // controllers
    required this.orderCtrl,
    required this.processCtrl,
    required this.valueCtrl,
    required this.stateCtrl,
    required this.observationCtrl,
    required this.bankCtrl,
    required this.electronicTicketCtrl,
    required this.fontCtrl,
    required this.dateCtrl,
    required this.taxCtrl,
    // estado
    required this.selectedPaymentRevisionData,
    required this.currentPaymentRevisionId,
    required this.isEditable,
    required this.isSaving,
    required this.formValidated,
    required this.onSaveOrUpdate,
    required this.onClear,
    // dropdown
    required this.orderNumberOptions,
    required this.greyOrderItems,
    this.onChangedOrderNumber,
    // side list
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onEditLabelSideItem,
  });

  double _inputsWidth(BuildContext context, {required double reserved}) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: reserved,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _input(
      double width,
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
      width: width,
      enabled: enabled,
      labelText: label,
      controller: controller,
      keyboardType:
      money ? TextInputType.number : (date ? TextInputType.datetime : TextInputType.text),
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
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      final sideWidth = isSmall ? constraints.maxWidth : 300.0;
      final reserved = isSmall ? 0.0 : (sideWidth + 12.0);
      final w = _inputsWidth(context, reserved: reserved);

      final camposWrap = Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // 🔽 Ordem com dropdown inteligente
          DropDownButtonChange(
            width: w,
            labelText: 'Ordem da revisão',
            items: orderNumberOptions,
            controller: orderCtrl,
            enabled: isEditable,
            greyItems: greyOrderItems,
            onChanged: onChangedOrderNumber,
          ),
          _input(w, processCtrl, 'Nº processo de pagamento da revisão',
              enabled: isEditable, mask: [processoMaskFormatter]),
          _input(w, valueCtrl, 'Valor do pagamento da revisão',
              enabled: isEditable, money: true),
          _input(w, stateCtrl, 'Estado do pagamento da revisão',
              enabled: isEditable),
          _input(w, observationCtrl, 'Observação do pagamento da revisão',
              enabled: isEditable),
          _input(w, bankCtrl, 'Nº do banco do pagamento da revisão',
              enabled: isEditable),
          _input(w, electronicTicketCtrl,
              'Nº do boleto eletrônico do pagamento da revisão',
              enabled: isEditable),
          _input(w, fontCtrl, 'Fonte do pagamento da revisão',
              enabled: isEditable),
          CustomDateField(
            width: w,
            enabled: isEditable,
            controller: dateCtrl,
            initialValue: selectedPaymentRevisionData?.datePaymentRevision,
            labelText: 'Data do pagamento da revisão do reajuste',
            onChanged: (date) => selectedPaymentRevisionData?.datePaymentRevision = date,
          ),
          _input(w, taxCtrl, 'Imposto do pagamento da revisão',
              enabled: isEditable, money: true),
        ],
      );

      final botoes = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: Text(currentPaymentRevisionId != null ? 'Atualizar' : 'Salvar'),
            onPressed: formValidated && isEditable && !isSaving ? onSaveOrUpdate : null,
          ),
          const SizedBox(width: 12),
          if (currentPaymentRevisionId != null)
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

      final side = SideListBox(
        title: 'Arquivos da Revisão',
        items: sideItems,
        selectedIndex: selectedSideIndex,
        onAddPressed: (selectedPaymentRevisionData != null && isEditable) ? onAddSideItem : null,
        onTap: onTapSideItem,
        onDelete: isEditable ? onDeleteSideItem : null,
        onEditLabel: isEditable ? onEditLabelSideItem : null,
        width: sideWidth,
      );

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: isSmall
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            side,
            const SizedBox(height: 12),
            corpo,
          ],
        )
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            side,
            const SizedBox(width: 12),
            Expanded(child: corpo),
          ],
        ),
      );
    });
  }
}
