import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/menu/tab_form/tab_form.dart';
import 'package:sipged/screens/modules/financial/payments/report/report_paid_form.dart';

class ReportExecutedForm extends StatelessWidget {
  const ReportExecutedForm({
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
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onSideItemsChanged,
    this.onRenamePersist,
    this.sideLoading = false,
    this.sideUploadProgress,
    this.paymentsChild,
    this.initialTabIndex = 0,
    this.onTabChanged,
    this.onPaymentsChanged,
  });

  final bool isEditable;
  final bool formValidated;

  final ReportExecutedData? selectedReportMeasurement;
  final String? currentReportMeasurementId;

  final ProcessData contractData;

  final TextEditingController orderController;
  final TextEditingController processNumberController;
  final TextEditingController dateController;
  final TextEditingController valueController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  final VoidCallback? onOpenMemoDeCalculo;
  final VoidCallback? onOpenBoletimDeMedicao;

  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  final void Function(List<dynamic> newItems)? onSideItemsChanged;

  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  final bool sideLoading;
  final double? sideUploadProgress;

  final Widget? paymentsChild;

  final int initialTabIndex;
  final ValueChanged<int>? onTabChanged;

  final Future<void> Function()? onPaymentsChanged;

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
          ? const TextInputType.numberWithOptions(decimal: true)
          : (date ? TextInputType.datetime : TextInputType.text),
      prefixText: money ? 'R\$ ' : null,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SipGedTheme.textDark,
      ),
      inputFormatters: [
        if (date) FilteringTextInputFormatter.digitsOnly,
        if (date) SipGedMasks.dateDDMMYYYY,
        if (money) const SipGedMoneyFormatter(),
        ?mask,
      ],
    );

    if (!tooltip) return field;

    return Tooltip(
      message: 'Este campo é calculado automaticamente.',
      child: field,
    );
  }

  String _numeroBoletim() {
    final selectedOrder = selectedReportMeasurement?.order;

    if (selectedOrder != null && selectedOrder.toString().trim().isNotEmpty) {
      return '$selectedOrder';
    }

    final text = orderController.text.trim();
    final match = RegExp(r'\d+').firstMatch(text);

    return match?.group(0) ?? '-';
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

        return TabForm(
          initialIndex: initialTabIndex,
          onChanged: onTabChanged,
          minHeight: 170,
          items: [
            TabFormItem(
              title: 'Medições',
              icon: Icons.receipt_long_outlined,
              child: _buildMeasurementTab(
                context: context,
                isSmallScreen: isSmallScreen,
                sideWidth: sideWidth,
                inputsWidth: inputsWidth,
              ),
            ),
            TabFormItem(
              title: 'Pagamentos',
              icon: Icons.payments_outlined,
              child: paymentsChild ??
                  ReportMeasurementPaymentFormSection(
                    contractData: contractData,
                    selectedReportMeasurement: selectedReportMeasurement,
                    orderController: orderController,
                    isEditable: isEditable,
                    onPaymentsChanged: onPaymentsChanged,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeasurementTab({
    required BuildContext context,
    required bool isSmallScreen,
    required double sideWidth,
    required double inputsWidth,
  }) {
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
        DateFieldChange(
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
              'Abrir memória de cálculo do $numero° boletim de medição',
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        camposWrap,
        const SizedBox(height: 12),
        barraAcoes,
      ],
    );

    final side = BoxListFiles(
      title: 'Arquivos da Medição',
      items: sideItems,
      selectedIndex: selectedSideIndex,
      width: sideWidth,
      onAddPressed: isEditable ? onAddSideItem : null,
      onTap: (index) => onTapSideItem?.call(index),
      onDelete: isEditable ? (index) => onDeleteSideItem?.call(index) : null,
      enableRename: isEditable && selectedReportMeasurement != null,
      onRenamePersist: onRenamePersist,
      onItemsChanged: onSideItemsChanged,
      loading: sideLoading,
      uploadProgress: sideUploadProgress,
    );

    if (isSmallScreen) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          side,
          const SizedBox(height: 12),
          corpo,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        side,
        const SizedBox(width: 12),
        Expanded(child: corpo),
      ],
    );
  }
}