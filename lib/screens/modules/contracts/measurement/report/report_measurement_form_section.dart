import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';

// ✅ lista lateral de arquivos (novo: rename embutido)
import 'package:sipged/_widgets/list/files/side_list_box.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class ReportMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;

  final ReportMeasurementData? selectedReportMeasurement;
  final String? currentReportMeasurementId;

  final ProcessData contractData;

  final TextEditingController orderController;
  final TextEditingController processNumberController;
  final TextEditingController dateController;
  final TextEditingController valueController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  /// ▶️ Ações (opcionais)
  final VoidCallback? onOpenMemoDeCalculo; // manter nulo => desabilitado
  final VoidCallback? onOpenBoletimDeMedicao; // abre modal readonly

  // ▶️ SideListBox props
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  /// ✅ opcional: notifica pai com a lista atual (já renomeada / deletada etc.)
  final void Function(List<dynamic> newItems)? onSideItemsChanged;

  /// ✅ opcional: persistir rename (Firestore/Storage)
  /// Retorne true/false para o SideListBox decidir commit/revert.
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  /// ✅ NOVO: overlay de upload/carregamento
  final bool sideLoading;
  final double? sideUploadProgress;

  const ReportMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedReportMeasurement,
    required this.currentReportMeasurementId,
    required this.contractData,
    required this.orderController,
    required this.processNumberController,
    required this.dateController,
    required this.valueController,
    required this.onSave,
    required this.onClear,
    this.onOpenMemoDeCalculo,
    this.onOpenBoletimDeMedicao,
    // side list
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onSideItemsChanged,
    this.onRenamePersist,
    this.sideLoading = false,
    this.sideUploadProgress,
  });

  Widget _input(
      double width,
      TextEditingController controller,
      String label, {
        required bool isEditable,
        bool enabled = true,
        bool money = false,
        bool date = false,
        bool tooltip = false,
        TextInputFormatter? mask,
      }) {
    final field = CustomTextField(
      width: width,
      enabled: enabled && isEditable,
      labelText: label,
      controller: controller,
      keyboardType: money
          ? TextInputType.number
          : (date ? TextInputType.datetime : TextInputType.text),
      inputFormatters: [
        if (date) FilteringTextInputFormatter.digitsOnly,
        if (date) SipGedMasks.dateDDMMYYYY,
        if (money)
          CurrencyInputFormatter(
            leadingSymbol: 'R\$ ',
            useSymbolPadding: true,
            thousandSeparator: ThousandSeparator.Period,
            mantissaLength: 2,
          ),
        if (mask != null) mask,
      ],
    );

    if (!tooltip) return field;
    return Tooltip(
      message: 'Este campo é calculado automaticamente.',
      child: field,
    );
  }

  String _numeroBoletim() {
    final sel = selectedReportMeasurement?.order;
    if (sel != null && sel.toString().isNotEmpty) return '$sel';

    final text = orderController.text;
    final m = RegExp(r'\d+').firstMatch(text);
    return m?.group(0) ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 700;
        final double sideWidth = isSmallScreen ? constraints.maxWidth : 300.0;

        final double inputsWidth = responsiveInputWidth(
          context: context,
          itemsPerLine: 4,
          reservedWidth: isSmallScreen ? 0.0 : (sideWidth + 12.0),
          spacing: 12.0,
          margin: 12.0,
          extraPadding: 24.0,
          spaceBetweenReserved: 12.0,
        );

        // -------- Campos
        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(
              inputsWidth,
              orderController,
              'Ordem da medição',
              isEditable: isEditable,
              enabled: false,
              tooltip: true,
            ),
            _input(
              inputsWidth,
              processNumberController,
              'Nº processo da medição',
              isEditable: isEditable,
              mask: SipGedMasks.processo,
            ),
            CustomDateField(
              width: inputsWidth,
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedReportMeasurement?.date,
              labelText: 'Data da Medição',
              onChanged: (date) {
                if (selectedReportMeasurement != null) {
                  selectedReportMeasurement!.date = date;
                }
              },
            ),
            _input(
              inputsWidth,
              valueController,
              'Valor da medição',
              isEditable: isEditable,
              money: true,
            ),
          ],
        );

        final numero = _numeroBoletim();

        final botoesEsquerda = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: inputsWidth,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: Text(
                  'Abrir memória de calculo do $numero° boletim de medição',
                ),
                onPressed: onOpenMemoDeCalculo,
              ),
            ),
            SizedBox(
              width: inputsWidth,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text('Abrir $numero° boletim de medição'),
                onPressed: onOpenBoletimDeMedicao,
              ),
            ),
          ],
        );

        final botoesDireita = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(
                currentReportMeasurementId != null ? 'Atualizar' : 'Salvar',
              ),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (currentReportMeasurementId != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: onClear,
              ),
          ],
        );

        final barraAcoes = Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              botoesEsquerda,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: botoesDireita,
              ),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: botoesEsquerda,
                ),
              ),
              const SizedBox(width: 12),
              botoesDireita,
            ],
          ),
        );

        final corpo = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            camposWrap,
            const SizedBox(height: 12),
            barraAcoes,
          ],
        );

        // -------- SideList
        final side = SideListBox(
          title: 'Arquivos da Medição',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          width: sideWidth,

          // ✅ botão + habilita quando editável (o pai decide se pode anexar)
          onAddPressed: isEditable ? onAddSideItem : null,

          // ✅ só seleciona no pai
          onTap: (i) => onTapSideItem?.call(i),

          // ✅ sem preview interno
          openOnTap: false,
          onDelete: isEditable ? (i) => onDeleteSideItem?.call(i) : null,
          enableRename: isEditable && selectedReportMeasurement != null,
          onRenamePersist: onRenamePersist,
          onItemsChanged: onSideItemsChanged,

          // ✅ overlay
          loading: sideLoading,
          uploadProgress: sideUploadProgress,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: isSmallScreen
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
