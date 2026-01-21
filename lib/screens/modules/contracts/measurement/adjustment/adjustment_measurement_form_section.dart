import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

class AdjustmentMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final AdjustmentMeasurementData? selectedAdjustmentMeasurement;
  final String? currentAdjustmentMeasurementId;
  final ProcessData contractData;

  final TextEditingController orderAdjustmentController;
  final TextEditingController processNumberAdjustmentController;
  final TextEditingController dateAdjustmentController;
  final TextEditingController valueAdjustmentController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  // SideListBox
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;

  // ▶️ NOVOS: dados do dropdown de ordem
  final List<String> orderOptions;                 // 1..(max+1)
  final Set<String> greyOrderItems;                // existentes (cinza)
  final void Function(String?) onChangedOrder;     // ação ao escolher

  const AdjustmentMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedAdjustmentMeasurement,
    required this.currentAdjustmentMeasurementId,
    required this.contractData,
    required this.orderAdjustmentController,
    required this.processNumberAdjustmentController,
    required this.dateAdjustmentController,
    required this.valueAdjustmentController,
    required this.onSave,
    required this.onClear,
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onEditLabelSideItem,
    // dropdown de ordem
    required this.orderOptions,
    required this.greyOrderItems,
    required this.onChangedOrder,
  });

  double _inputWidth(BuildContext context, {required double reserved}) {
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

    final customTextField = CustomTextField(
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
      return Tooltip(
        message: 'Este campo é calculado automaticamente.',
        child: customTextField,
      );
    }
    return customTextField;
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;
    final double sideWidth = isSmall ? MediaQuery.of(context).size.width : 300.0;
    final double reserved = isSmall ? 0.0 : (sideWidth + 12.0);
    final double w = _inputWidth(context, reserved: reserved);

    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // 🔄 Substituição do input pela combo de ordem
        DropDownButtonChange(
          width: w,
          controller: orderAdjustmentController,
          labelText: 'Ordem da medição',
          items: orderOptions,       // 1..(max+1)
          greyItems: greyOrderItems, // existentes => cinza
          enabled: true,             // permite clicar para selecionar/filtrar mesmo que form não editável
          onChanged: onChangedOrder, // ação do controller
        ),

        _input(
          w,
          processNumberAdjustmentController,
          'Nº processo da medição',
          enabled: isEditable,
          mask: [processoMaskFormatter],
        ),
        CustomDateField(
          width: w,
          enabled: isEditable,
          controller: dateAdjustmentController,
          initialValue: selectedAdjustmentMeasurement?.date,
          labelText: 'Data da Medição',
          onChanged: (date) => selectedAdjustmentMeasurement?.date = date,
        ),
        _input(
          w,
          valueAdjustmentController,
          'Valor da medição',
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
          label: Text(currentAdjustmentMeasurementId != null ? 'Atualizar' : 'Salvar'),
          onPressed: formValidated ? (isEditable ? onSave : null) : null,
        ),
        const SizedBox(width: 12),
        if (currentAdjustmentMeasurementId != null)
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
      title: 'Arquivos do Reajuste',
      items: sideItems,
      selectedIndex: selectedSideIndex,
      onAddPressed: (selectedAdjustmentMeasurement != null && isEditable) ? onAddSideItem : null,
      onTap: onTapSideItem, // <- a tela pai passa ctrl.handleOpenFile(context, i)
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
  }
}
