// lib/screens/contracts/additives/additive_form_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_widgets/cards/basic/basic_card.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/additives/additives_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

class AdditiveFormSection extends StatefulWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final AdditivesData? selectedAdditive;
  final String? currentAdditiveId;
  final ProcessData contractData;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController typeOfAdditiveCtrl;
  final TextEditingController valueController;
  final TextEditingController additionalDaysExecutionController;
  final TextEditingController additionalDaysContractController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  // SideListBox
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;

  // Dropdown de ordem
  final List<String> orderOptions;
  final Set<String> greyOrderItems;
  final void Function(String?) onChangedOrder;

  const AdditiveFormSection({
    super.key,
    required this.isEditable,
    required this.editingMode,
    required this.formValidated,
    required this.selectedAdditive,
    required this.currentAdditiveId,
    required this.contractData,
    required this.orderController,
    required this.processController,
    required this.dateController,
    required this.typeOfAdditiveCtrl,
    required this.valueController,
    required this.additionalDaysExecutionController,
    required this.additionalDaysContractController,
    required this.onSave,
    required this.onClear,
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onEditLabelSideItem,
    required this.orderOptions,
    required this.greyOrderItems,
    required this.onChangedOrder,
  });

  @override
  State<AdditiveFormSection> createState() => _AdditiveFormSectionState();
}

class _AdditiveFormSectionState extends State<AdditiveFormSection> {
  String _currentType = '';

  @override
  void initState() {
    super.initState();
    _currentType = widget.typeOfAdditiveCtrl.text;

    widget.typeOfAdditiveCtrl.addListener(_syncTypeFromController);
  }

  @override
  void didUpdateWidget(covariant AdditiveFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.typeOfAdditiveCtrl != widget.typeOfAdditiveCtrl) {
      oldWidget.typeOfAdditiveCtrl.removeListener(_syncTypeFromController);
      widget.typeOfAdditiveCtrl.addListener(_syncTypeFromController);
    }

    // garante sync quando preencher formulário por seleção externa
    final t = widget.typeOfAdditiveCtrl.text;
    if (t != _currentType) {
      _currentType = t;
    }
  }

  @override
  void dispose() {
    widget.typeOfAdditiveCtrl.removeListener(_syncTypeFromController);
    super.dispose();
  }

  void _syncTypeFromController() {
    final t = widget.typeOfAdditiveCtrl.text;
    if (t == _currentType) return;
    setState(() => _currentType = t);
  }

  bool _exibeValor() =>
      ['VALOR', 'REEQUÍLIBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(_currentType.toUpperCase());

  bool _exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(_currentType.toUpperCase());

  void _onTypeChanged(String? value) {
    final v = (value ?? '').trim();
    widget.typeOfAdditiveCtrl.text = v;

    // opcional: limpar campos que não serão usados
    if (!_exibeValor()) {
      widget.valueController.clear();
    }
    if (!_exibePrazo()) {
      widget.additionalDaysContractController.clear();
      widget.additionalDaysExecutionController.clear();
    }

    // atualiza modelo em memória (se tiver selecionado)
    if (widget.selectedAdditive != null) {
      widget.selectedAdditive!.typeOfAdditive = v;
    }

    setState(() => _currentType = v);
  }

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
      message: tooltip
          ? 'Este campo é calculado automaticamente e não pode ser editado.'
          : '',
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
          if (date) TextInputMask(mask: '99/99/9999'),
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

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Ordem com dropdown
            DropDownButtonChange(
              width: inputsWidth,
              enabled: true,
              labelText: 'Ordem do aditivo',
              items: widget.orderOptions,
              greyItems: widget.greyOrderItems,
              controller: widget.orderController,
              onChanged: widget.onChangedOrder,
            ),
            _input(
              inputsWidth,
              widget.processController,
              'Processo do Aditivo',
              mask: processoMaskFormatter,
              isEditable: widget.isEditable,
            ),
            CustomDateField(
              width: inputsWidth,
              enabled: widget.isEditable,
              controller: widget.dateController,
              initialValue: widget.selectedAdditive?.additiveDate,
              labelText: 'Data do Aditivo',
              onChanged: (date) {
                if (widget.selectedAdditive != null) {
                  widget.selectedAdditive!.additiveDate = date;
                }
              },
            ),
            DropDownButtonChange(
              width: inputsWidth,
              enabled: widget.isEditable,
              labelText: 'Tipo de Aditivo',
              items: AdditivesData.allowedTypes,
              controller: widget.typeOfAdditiveCtrl,
              onChanged: _onTypeChanged,
            ),

            if (_exibeValor())
              _input(
                inputsWidth,
                widget.valueController,
                'Valor do aditivo',
                money: true,
                isEditable: widget.isEditable,
              ),

            if (_exibePrazo())
              _input(
                inputsWidth,
                widget.additionalDaysContractController,
                'Dias adicionais ao prazo do contrato',
                isEditable: widget.isEditable,
              ),

            if (_exibePrazo())
              _input(
                inputsWidth,
                widget.additionalDaysExecutionController,
                'Dias adicionais ao prazo de execução',
                isEditable: widget.isEditable,
              ),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(widget.editingMode ? 'Atualizar' : 'Salvar'),
              onPressed:
              widget.formValidated ? (widget.isEditable ? widget.onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (widget.editingMode)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: widget.onClear,
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
          title: 'Arquivos do Aditivo',
          items: widget.sideItems,
          selectedIndex: widget.selectedSideIndex,
          onAddPressed: (widget.selectedAdditive != null && widget.isEditable)
              ? widget.onAddSideItem
              : null,
          onTap: widget.onTapSideItem == null ? null : (i) => widget.onTapSideItem!(i),
          onDelete: widget.isEditable ? widget.onDeleteSideItem : null,
          onEditLabel: widget.isEditable ? widget.onEditLabelSideItem : null,
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
