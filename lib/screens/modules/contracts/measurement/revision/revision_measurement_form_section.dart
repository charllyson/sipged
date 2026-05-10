// lib/screens/modules/contracts/measurement/revision/revision_measurement_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';

import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class RevisionMeasurementFormSection extends StatelessWidget {
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
    this.sideLoading = false,
    this.sideUploadProgress,
    required this.orderOptions,
    required this.greyOrderItems,
    required this.onChangedOrder,
  });

  final bool isEditable;
  final bool formValidated;
  final RevisionMeasurementData? selectedRevisionMeasurement;
  final String? currentRevisionMeasurementId;
  final ContractData contractData;

  final TextEditingController orderRevisionController;
  final TextEditingController processNumberRevisionController;
  final TextEditingController dateRevisionController;
  final TextEditingController valueRevisionController;

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
    final formatters = <TextInputFormatter>[
      if (date) FilteringTextInputFormatter.digitsOnly,
      if (date) SipGedMasks.dateDDMMYYYY,
      if (money) const SipGedMoneyFormatter(),
      if (mask != null) ...mask,
    ];

    final customTextField = CustomTextField(
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

    if (!tooltip) return customTextField;

    return Tooltip(
      message: 'Este campo é calculado automaticamente.',
      child: customTextField,
    );
  }

  Widget _buildSideBox({
    required double width,
  }) {
    final progress = sideUploadProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BoxListFiles(
          title: 'Arquivos da Revisão',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          onAddPressed:
          selectedRevisionMeasurement != null && isEditable && !sideLoading
              ? onAddSideItem
              : null,
          onTap: onTapSideItem,
          onDelete: isEditable && !sideLoading ? onDeleteSideItem : null,
          enableRename: isEditable && !sideLoading,
          onRenamePersist: onRenamePersist,
          onItemsChanged: isEditable && !sideLoading ? onSideItemsChanged : null,
          width: width,
        ),
        if (sideLoading) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: width,
            child: LinearProgressIndicator(
              value: progress?.clamp(0.0, 1.0),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: width,
            child: Text(
              progress == null
                  ? 'Processando arquivo...'
                  : 'Enviando arquivo ${(progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isSmall = mediaWidth < 700;

    final double sideWidth = isSmall ? mediaWidth : 300.0;
    final double reserved = isSmall ? 0.0 : sideWidth + 12.0;
    final double inputWidth = _inputWidth(context, reserved: reserved);

    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DropDownChange(
          width: inputWidth,
          controller: orderRevisionController,
          labelText: 'Ordem da revisão',
          items: orderOptions,
          greyItems: greyOrderItems,
          enabled: isEditable && !sideLoading,
          onChanged: onChangedOrder,
        ),
        _input(
          inputWidth,
          processNumberRevisionController,
          'Nº processo da revisão',
          enabled: isEditable && !sideLoading,
          mask: [SipGedMasks.processo],
        ),
        DateFieldChange(
          width: inputWidth,
          enabled: isEditable && !sideLoading,
          controller: dateRevisionController,
          initialValue: selectedRevisionMeasurement?.date,
          labelText: 'Data da revisão',
          onChanged: (date) {
            selectedRevisionMeasurement?.date = date;
          },
        ),
        _input(
          inputWidth,
          valueRevisionController,
          'Valor da revisão',
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
            currentRevisionMeasurementId != null ? 'Atualizar' : 'Salvar',
          ),
          onPressed: formValidated && isEditable && !sideLoading ? onSave : null,
        ),
        const SizedBox(width: 12),
        if (currentRevisionMeasurementId != null)
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

    final side = _buildSideBox(width: sideWidth);

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