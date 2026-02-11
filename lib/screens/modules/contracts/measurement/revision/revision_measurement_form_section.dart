import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:siged/_utils/mask/sipged_masks.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class RevisionMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final RevisionMeasurementData? selectedRevisionMeasurement;
  final String? currentRevisionMeasurementId;
  final ProcessData contractData;

  final TextEditingController orderRevisionController;
  final TextEditingController processNumberRevisionController;
  final TextEditingController dateRevisionController;
  final TextEditingController valueRevisionController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  // SideListBox
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  /// ✅ persistência do rename (SideListBox cuida do dialog)
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  /// ✅ notifica a tela pai com a lista já atualizada (rename otimista etc.)
  final void Function(List<dynamic> newItems)? onSideItemsChanged;

  // Dropdown de ordem
  final List<String> orderOptions;
  final Set<String> greyOrderItems;
  final void Function(String?) onChangedOrder;

  const RevisionMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedRevisionMeasurement,
    required this.currentRevisionMeasurementId,
    required this.contractData,
    required this.orderRevisionController,
    required this.processNumberRevisionController,
    required this.dateRevisionController,
    required this.valueRevisionController,
    required this.onSave,
    required this.onClear,
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onRenamePersist,
    this.onSideItemsChanged,
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
        SipGedMasks.dateDDMMYYYY,
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
        DropDownButtonChange(
          width: w,
          controller: orderRevisionController,
          labelText: 'Ordem da medição',
          items: orderOptions,
          greyItems: greyOrderItems,
          enabled: true,
          onChanged: onChangedOrder,
        ),
        _input(
          w,
          processNumberRevisionController,
          'Nº processo da medição',
          enabled: isEditable,
          mask: [SipGedMasks.processo],
        ),
        CustomDateField(
          width: w,
          enabled: isEditable,
          controller: dateRevisionController,
          initialValue: selectedRevisionMeasurement?.date,
          labelText: 'Data da Medição',
          onChanged: (date) => selectedRevisionMeasurement?.date = date,
        ),
        _input(
          w,
          valueRevisionController,
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
          label: Text(currentRevisionMeasurementId != null ? 'Atualizar' : 'Salvar'),
          onPressed: formValidated ? (isEditable ? onSave : null) : null,
        ),
        const SizedBox(width: 12),
        if (currentRevisionMeasurementId != null)
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
      onAddPressed: (selectedRevisionMeasurement != null && isEditable) ? onAddSideItem : null,
      onTap: onTapSideItem,
      onDelete: isEditable ? onDeleteSideItem : null,
      enableRename: isEditable,
      onRenamePersist: onRenamePersist,
      onItemsChanged: onSideItemsChanged,
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
