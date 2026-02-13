// lib/screens/modules/contracts/apostilles/apostilles_form_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';

class ApostilleFormSection extends StatelessWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final ApostillesData? selectedApostille;
  final String? currentApostilleId;
  final ProcessData contractData;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController valueController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  /// ✅ persistência do rename (retorna true se ok)
  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  /// ✅ notifica pai com lista atual (renomeada/deletada etc.)
  final void Function(List<dynamic> newItems)? onItemsChanged;

  final List<String> orderNumberOptions;
  final Set<String> greyOrderItems;
  final void Function(String?) onChangedOrderNumber;

  const ApostilleFormSection({
    super.key,
    required this.isEditable,
    required this.editingMode,
    required this.formValidated,
    required this.selectedApostille,
    required this.currentApostilleId,
    required this.contractData,
    required this.orderController,
    required this.processController,
    required this.dateController,
    required this.valueController,
    required this.onSave,
    required this.onClear,
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onRenamePersist,
    this.onItemsChanged,
    required this.orderNumberOptions,
    required this.greyOrderItems,
    required this.onChangedOrderNumber,
  });

  Widget _input(
      double width,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        bool date = false,
        bool money = false,
        bool tooltip = false,
        TextInputFormatter? mask,
        required bool isEditable,
      }) {
    return Tooltip(
      message: tooltip ? 'Este campo é gerado automaticamente.' : '',
      child: CustomTextField(
        width: width,
        controller: ctrl,
        enabled: enabled && isEditable,
        labelText: label,
        keyboardType: date
            ? TextInputType.datetime
            : (money ? TextInputType.number : null),
        inputFormatters: [
          if (date) FilteringTextInputFormatter.digitsOnly,
          if (date) SipGedMasks.dateDDMMYYYY,
          if (money)
            CurrencyInputFormatter(
              leadingSymbol: r'R$ ',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 2,
            ),
          if (mask != null) mask,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

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

        final double minCardHeight = isSmallScreen ? 260.0 : 170.0;

        // ✅ regra única (igual AdditiveFormSection)
        final bool canEditSide = isEditable && selectedApostille != null;

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropDownButtonChange(
              width: inputsWidth,
              labelText: 'Ordem do apostilamento',
              items: orderNumberOptions,
              controller: orderController,
              enabled: isEditable,
              greyItems: greyOrderItems,
              onChanged: onChangedOrderNumber,
            ),
            _input(
              inputsWidth,
              processController,
              'Nº do processo',
              mask: SipGedMasks.processo,
              isEditable: isEditable,
            ),
            CustomDateField(
              width: inputsWidth,
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedApostille?.apostilleData,
              labelText: 'Data do apostilamento',
              onChanged: (date) => selectedApostille?.apostilleData = date,
            ),
            _input(
              inputsWidth,
              valueController,
              'Valor do apostilamento',
              money: true,
              isEditable: isEditable,
            ),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(editingMode ? 'Atualizar' : 'Salvar'),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (editingMode)
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
          title: 'Arquivos do Apostilamento',
          items: sideItems,
          selectedIndex: selectedSideIndex,

          // ✅ mesma lógica do AdditiveFormSection
          onAddPressed: canEditSide ? onAddSideItem : null,

          onTap: onTapSideItem == null ? null : (i) => onTapSideItem!(i),

          onDelete: (canEditSide && onDeleteSideItem != null)
              ? (i) => onDeleteSideItem!(i)
              : null,

          // ✅ rename só quando pode editar + callback existe
          enableRename: canEditSide,
          onRenamePersist: (canEditSide && onRenamePersist != null)
              ? onRenamePersist
              : null,

          onItemsChanged: onItemsChanged,

          width: sideWidth,
        );

        return BasicCard(
          isDark: isDark,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minCardHeight),
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
          ),
        );
      },
    );
  }
}
