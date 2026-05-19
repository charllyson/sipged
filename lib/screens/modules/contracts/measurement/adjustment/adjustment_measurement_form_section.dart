// lib/screens/modules/contracts/measurement/adjustment/adjustment_measurement_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class AdjustmentMeasurementFormSection extends StatelessWidget {
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
    this.onRenamePersist,
    this.onSideItemsChanged,
    this.sideLoading = false,
    this.sideUploadProgress,
    required this.orderOptions,
    required this.greyOrderItems,
    required this.onChangedOrder,
  });

  final bool isEditable;
  final bool formValidated;

  final AdjustmentMeasurementData? selectedAdjustmentMeasurement;
  final String? currentAdjustmentMeasurementId;

  final ContractData contractData;

  final TextEditingController orderAdjustmentController;
  final TextEditingController processNumberAdjustmentController;
  final TextEditingController dateAdjustmentController;
  final TextEditingController valueAdjustmentController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  final void Function(List<dynamic> newItems)? onSideItemsChanged;

  final bool sideLoading;
  final double? sideUploadProgress;

  final List<String> orderOptions;
  final Set<String> greyOrderItems;
  final void Function(String?) onChangedOrder;

  double _inputWidth(
      BuildContext context, {
        required double reserved,
      }) {
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
    final formatters = <TextInputFormatter>[
      if (date) FilteringTextInputFormatter.digitsOnly,
      if (date) SipGedMasks.dateDDMMYYYY,
      if (money) const SipGedMoneyFormatter(),
      if (mask != null) ...mask,
    ];

    final field = CustomTextField(
      width: width,
      enabled: enabled,
      labelText: label,
      controller: controller,
      keyboardType: money
          ? const TextInputType.numberWithOptions(decimal: true)
          : date
          ? TextInputType.datetime
          : TextInputType.text,
      prefixText: money ? 'R\$ ' : null,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
      inputFormatters: formatters,
    );

    if (!tooltip) return field;

    return Tooltip(
      message: 'Este campo é calculado automaticamente.',
      child: field,
    );
  }

  Widget _buildSideBox({
    required double width,
  }) {
    return BoxListFiles(
      title: 'Arquivos do Reajuste',
      items: sideItems,
      selectedIndex: selectedSideIndex,
      onAddPressed: selectedAdjustmentMeasurement != null &&
          isEditable &&
          !sideLoading
          ? onAddSideItem
          : null,
      onTap: onTapSideItem,
      onDelete: isEditable && !sideLoading ? onDeleteSideItem : null,
      enableRename: isEditable && !sideLoading,
      onRenamePersist: onRenamePersist,
      onItemsChanged: isEditable && !sideLoading ? onSideItemsChanged : null,
      loading: sideLoading,
      uploadProgress: sideUploadProgress,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final bool isSmall = mediaWidth < 700;

    final double sideWidth = isSmall ? mediaWidth : 300.0;
    final double reserved = isSmall ? 0.0 : sideWidth + 12.0;
    final double inputWidth = _inputWidth(
      context,
      reserved: reserved,
    );

    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DropDownChange(
          width: inputWidth,
          controller: orderAdjustmentController,
          labelText: 'Ordem da medição',
          items: orderOptions,
          greyItems: greyOrderItems,
          enabled: isEditable && !sideLoading,
          onChanged: onChangedOrder,
        ),
        _input(
          inputWidth,
          processNumberAdjustmentController,
          'Nº processo da medição',
          enabled: isEditable && !sideLoading,
          mask: [SipGedMasks.processo],
        ),
        DateFieldChange(
          width: inputWidth,
          enabled: isEditable && !sideLoading,
          controller: dateAdjustmentController,
          initialValue: selectedAdjustmentMeasurement?.date,
          labelText: 'Data da Medição',
          onChanged: (date) {
            selectedAdjustmentMeasurement?.date = date;
          },
        ),
        _input(
          inputWidth,
          valueAdjustmentController,
          'Valor da medição',
          enabled: isEditable && !sideLoading,
          money: true,
        ),
      ],
    );

    final botoes = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.save),
          label: Text(
            currentAdjustmentMeasurementId != null ? 'Atualizar' : 'Salvar',
          ),
          onPressed: formValidated && isEditable && !sideLoading
              ? onSave
              : null,
        ),
        const SizedBox(width: 12),
        if (currentAdjustmentMeasurementId != null)
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Limpar'),
            onPressed: sideLoading ? null : onClear,
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

    final side = _buildSideBox(
      width: sideWidth,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey,
        ),
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
          Expanded(
            child: corpo,
          ),
        ],
      ),
    );
  }
}