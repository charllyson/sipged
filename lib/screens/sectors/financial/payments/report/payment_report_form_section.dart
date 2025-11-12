import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/formats/input_formatters.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

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
  final ProcessData? contractData;

  // 🆕 SideListBox (agora suporta anexos com rótulo)
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;

  // 🆕 Dropdown de ordem
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
    this.onEditLabelSideItem,
    // dropdown
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
      keyboardType: money
          ? TextInputType.number
          : (date ? TextInputType.datetime : TextInputType.text),
      inputFormatters: formatters,
    );

    if (tooltip) {
      return Tooltip(message: 'Este campo é calculado automaticamente.', child: textField);
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
            labelText: 'Ordem da medição',
            items: orderNumberOptions,
            controller: orderPaymentReportController,
            enabled: isEditable,
            greyItems: greyOrderItems,           // itens existentes em cinza
            onChanged: onChangedOrderNumber,     // carrega existente ou cria novo
          ),
          _input(w, processNumberPaymentReportController, 'Nº processo do pagamento da medição', mask: [processoMaskFormatter]),
          _input(w, valuePaymentReportController, 'Valor do pagamento da medição', money: true),
          _input(w, statePaymentReportController, 'Estado do pagamento da medição'),
          _input(w, observationPaymentReportController, 'Observação do pagamento da medição'),
          _input(w, bankPaymentReportController, 'Nº do banco do pagamento da medição'),
          _input(w, electronicTicketPaymentReportController, 'Nº do boleto eletrônico do pagamento da medição'),
          _input(w, fontPaymentReportController, 'Fonte do pagamento da medição'),
          CustomDateField(
            width: w,
            enabled: isEditable,
            controller: datePaymentReportController,
            initialValue: selectedPaymentReportData?.datePaymentReport,
            labelText: 'Data do pagamento da Medição',
            onChanged: (date) => selectedPaymentReportData?.datePaymentReport = date,
          ),
          _input(w, taxPaymentReportController, 'Imposto do pagamento da medição', money: true),
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

      // ✅ SideListBox — multi-anexos com rótulo/renomear
      final side = SideListBox(
        title: 'Arquivos do Pagamento',
        items: sideItems,
        selectedIndex: selectedSideIndex,
        onAddPressed: (selectedPaymentReportData != null && isEditable) ? onAddSideItem : null,
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
