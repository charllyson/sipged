// lib/screens/modules/contracts/measurement/adjustment/adjustment_measurement_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/menu/tab_form/tab_form.dart';
import 'package:sipged/screens/modules/financial/payments/adjustment/adjustment_payment_form_section.dart';

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
    this.paymentsChild,
    this.initialTabIndex = 0,
    this.onTabChanged,
    this.onPaymentsChanged,
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
        bool tooltip = false,
        bool money = false,
        bool date = false,
        TextInputFormatter? mask,
      }) {
    final field = CustomTextField(
      width: width,
      enabled: enabled && isEditable,
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
      enableRename: isEditable &&
          !sideLoading &&
          selectedAdjustmentMeasurement != null,
      onRenamePersist: onRenamePersist,
      onItemsChanged: isEditable && !sideLoading ? onSideItemsChanged : null,
      loading: sideLoading,
      uploadProgress: sideUploadProgress,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 700;
        final double sideWidth =
        isSmallScreen ? constraints.maxWidth : 300.0;

        final double inputsWidth = responsiveInputWidth(
          context: context,
          itemsPerLine: 4,
          reservedWidth: isSmallScreen ? 0.0 : sideWidth + 12.0,
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
              title: 'Reajustes',
              icon: Icons.trending_up_outlined,
              child: _buildAdjustmentTab(
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
                  AdjustmentPaymentFormSection(
                    contractData: contractData,
                    selectedAdjustmentMeasurement:
                    selectedAdjustmentMeasurement,
                    orderController: orderAdjustmentController,
                    isEditable: isEditable,
                    onPaymentsChanged: onPaymentsChanged,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdjustmentTab({
    required BuildContext context,
    required bool isSmallScreen,
    required double sideWidth,
    required double inputsWidth,
  }) {
    final camposWrap = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DropDownChange(
          width: inputsWidth,
          controller: orderAdjustmentController,
          labelText: 'Ordem do reajuste',
          items: orderOptions,
          greyItems: greyOrderItems,
          enabled: isEditable && !sideLoading,
          onChanged: onChangedOrder,
        ),
        _input(
          inputsWidth,
          processNumberAdjustmentController,
          'Nº processo do reajuste',
          isEditable: isEditable,
          enabled: !sideLoading,
          mask: SipGedMasks.processo,
        ),
        DateFieldChange(
          width: inputsWidth,
          enabled: isEditable && !sideLoading,
          controller: dateAdjustmentController,
          initialValue: selectedAdjustmentMeasurement?.date,
          labelText: 'Data do Reajuste',
          onChanged: (date) {
            if (selectedAdjustmentMeasurement != null) {
              selectedAdjustmentMeasurement!.date = date;
            }
          },
        ),
        _input(
          inputsWidth,
          valueAdjustmentController,
          'Valor do reajuste',
          isEditable: isEditable,
          enabled: !sideLoading,
          money: true,
        ),
      ],
    );

    final botoesDireita = Row(
      mainAxisSize: MainAxisSize.min,
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

    final barraAcoes = Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: botoesDireita,
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

    final side = _buildSideBox(width: sideWidth);

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