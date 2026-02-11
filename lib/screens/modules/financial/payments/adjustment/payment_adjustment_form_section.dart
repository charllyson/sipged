import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:siged/_utils/mask/sipged_masks.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
// 🆕 SideListBox (novo: rename interno)
import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
// 🆕 Dropdown de ordem com itens em cinza
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/_blocs/modules/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

class PaymentAdjustmentFormSection extends StatelessWidget {
  const PaymentAdjustmentFormSection({
    super.key,
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
    required this.selected,
    required this.currentPaymentAdjustmentId,
    required this.isEditable,
    required this.isSaving,
    required this.formValidated,
    required this.onSaveOrUpdate,
    required this.onClear,
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,

    // ✅ NOVO (SideListBox v2)
    this.onRenamePersist,
    this.onItemsChanged,

    this.contractData,

    // 🆕 props do dropdown de ordem
    required this.orderNumberOptions,
    required this.greyOrderItems,
    this.onChangedOrderNumber,
  });

  // controllers
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

  final PaymentsAdjustmentsData? selected;
  final String? currentPaymentAdjustmentId;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;

  // SideListBox (dinâmico)
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  // ✅ NOVO: rename/persist (sem dialog no pai)
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  // ✅ NOVO: notifica lista alterada (rename/delete etc.)
  final void Function(List<dynamic> newItems)? onItemsChanged;

  final ProcessData? contractData;

  // 🆕 Dropdown de ordem
  final List<String> orderNumberOptions;
  final Set<String> greyOrderItems;
  final void Function(String? value)? onChangedOrderNumber;

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
      double width, {
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
          leadingSymbol: 'R\$ ',
          useSymbolPadding: true,
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 2,
        ),
      ];
    } else if (date) {
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        SipGedMasks.dateDDMMYYYY,
      ];
    } else if (mask != null) {
      formatters = mask;
    }

    final tf = CustomTextField(
      width: width,
      enabled: enabled,
      labelText: label,
      controller: controller,
      keyboardType: money
          ? TextInputType.number
          : (date ? TextInputType.datetime : TextInputType.text),
      inputFormatters: formatters,
    );

    if (tooltip) {
      return Tooltip(message: 'Este campo é calculado automaticamente.', child: tf);
    }
    return tf;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 900;
          final sideWidth = isSmall ? constraints.maxWidth : 300.0;
          final reserved = isSmall ? 0.0 : (sideWidth + 12.0);
          final w = _inputsWidth(context, reserved: reserved);

          final camposWrap = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Ordem com dropdown inteligente
              DropDownButtonChange(
                width: w,
                labelText: 'Ordem do reajuste',
                items: orderNumberOptions,
                controller: orderCtrl,
                enabled: isEditable,
                greyItems: greyOrderItems,
                onChanged: onChangedOrderNumber,
              ),

              _input(
                w,
                controller: processCtrl,
                label: 'Nº processo de pagamento do reajuste',
                mask: [SipGedMasks.processo],
              ),
              _input(w, controller: valueCtrl, label: 'Valor do pagamento do reajuste', money: true),
              _input(w, controller: stateCtrl, label: 'Estado do pagamento do reajuste'),
              _input(w, controller: observationCtrl, label: 'Observação do pagamento do reajuste'),
              _input(w, controller: bankCtrl, label: 'Nº do banco do pagamento do reajuste'),
              _input(
                w,
                controller: electronicTicketCtrl,
                label: 'Nº do boleto eletrônico do pagamento do reajuste',
              ),
              _input(w, controller: fontCtrl, label: 'Fonte do pagamento do reajuste'),

              CustomDateField(
                width: w,
                enabled: isEditable,
                controller: dateCtrl,
                initialValue: selected?.datePaymentAdjustment,
                labelText: 'Data do pagamento do reajuste',
                onChanged: (date) => (selected)?.datePaymentAdjustment = date,
              ),

              _input(w, controller: taxCtrl, label: 'Imposto do pagamento do reajuste', money: true),
            ],
          );

          final botoes = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (currentPaymentAdjustmentId != null)
                TextButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Limpar'),
                  onPressed: onClear,
                ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: formValidated && !isSaving ? onSaveOrUpdate : null,
                icon: const Icon(Icons.save),
                label: Text(currentPaymentAdjustmentId != null ? 'Atualizar' : 'Salvar'),
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
            title: 'Arquivos do Pagamento de Reajuste',
            items: sideItems,
            selectedIndex: selectedSideIndex,
            onAddPressed: (selected != null && isEditable) ? onAddSideItem : null,
            onTap: onTapSideItem,
            onDelete: isEditable ? onDeleteSideItem : null,
            width: sideWidth,

            // ✅ NOVO
            enableRename: isEditable,
            onRenamePersist: isEditable ? onRenamePersist : null,
            onItemsChanged: onItemsChanged,
          );

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
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
        },
      ),
    );
  }
}
