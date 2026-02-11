import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:siged/_utils/mask/sipged_masks.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class PaymentReportFormSection extends StatelessWidget {
  // --- Controllers
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

  // --- Estado
  final PaymentsReportData? selectedPaymentReportData;
  final String? currentPaymentReportId;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;
  final ProcessData? contractData;

  // --- SideListBox (dinâmico)
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  /// ✅ NOVO: persistência do rename (recomendado)
  /// Retorne true/false pra widget reverter se falhar
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  /// ✅ NOVO: feedback pro pai quando itens mudarem (rename/delete local)
  final void Function(List<dynamic> newItems)? onSideItemsChanged;

  // --- Dropdown de ordem
  final List<String> orderNumberOptions;
  final Set<String> greyOrderItems;
  final void Function(String? value)? onChangedOrderNumber;

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
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onRenamePersist,
    this.onSideItemsChanged,
    required this.orderNumberOptions,
    required this.greyOrderItems,
    this.onChangedOrderNumber,
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
      keyboardType:
      money ? TextInputType.number : (date ? TextInputType.datetime : TextInputType.text),
      inputFormatters: formatters,
    );

    if (tooltip) {
      return Tooltip(
        message: 'Este campo é calculado automaticamente.',
        child: tf,
      );
    }
    return tf;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;
        final sideWidth = isSmall ? constraints.maxWidth : 300.0;
        final reserved = isSmall ? 0.0 : (sideWidth + 12.0);
        final w = _inputsWidth(context, reserved: reserved);

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // ✅ Dropdown de ordem fica habilitado sempre (navegação)
            DropDownButtonChange(
              width: w,
              labelText: 'Ordem da medição',
              items: orderNumberOptions,
              controller: orderPaymentReportController,
              enabled: true,
              greyItems: greyOrderItems,
              onChanged: onChangedOrderNumber,
            ),

            _input(
              w,
              controller: processNumberPaymentReportController,
              label: 'Nº processo do pagamento da medição',
              enabled: isEditable,
              mask: [SipGedMasks.processo],
            ),
            _input(
              w,
              controller: valuePaymentReportController,
              label: 'Valor do pagamento da medição',
              enabled: isEditable,
              money: true,
            ),
            _input(
              w,
              controller: statePaymentReportController,
              label: 'Estado do pagamento da medição',
              enabled: isEditable,
            ),
            _input(
              w,
              controller: observationPaymentReportController,
              label: 'Observação do pagamento da medição',
              enabled: isEditable,
            ),
            _input(
              w,
              controller: bankPaymentReportController,
              label: 'Nº do banco do pagamento da medição',
              enabled: isEditable,
            ),
            _input(
              w,
              controller: electronicTicketPaymentReportController,
              label: 'Nº do boleto eletrônico do pagamento da medição',
              enabled: isEditable,
            ),
            _input(
              w,
              controller: fontPaymentReportController,
              label: 'Fonte do pagamento da medição',
              enabled: isEditable,
            ),
            CustomDateField(
              width: w,
              enabled: isEditable,
              controller: datePaymentReportController,
              initialValue: selectedPaymentReportData?.datePaymentReport,
              labelText: 'Data do pagamento da Medição',
              onChanged: (date) => selectedPaymentReportData?.datePaymentReport = date,
            ),
            _input(
              w,
              controller: taxPaymentReportController,
              label: 'Imposto do pagamento da medição',
              enabled: isEditable,
              money: true,
            ),
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

        final side = SideListBox(
          title: 'Arquivos do Pagamento',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          onAddPressed: (selectedPaymentReportData != null && isEditable) ? onAddSideItem : null,
          onTap: onTapSideItem,
          onDelete: isEditable ? onDeleteSideItem : null,
          width: sideWidth,

          // ✅ NOVO SideListBox
          enableRename: isEditable,
          onRenamePersist: onRenamePersist,
          onItemsChanged: onSideItemsChanged,
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
      },
    );
  }
}
