import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class AdditiveFormSection extends StatefulWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final AdditivesData? selectedAdditive;
  final String? currentAdditiveId;
  final ContractData contractData;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController typeOfAdditiveCtrl;
  final TextEditingController valueController;
  final TextEditingController additionalDaysExecutionController;
  final TextEditingController additionalDaysContractController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  final bool sideLoading;
  final double? uploadProgress;

  final void Function(List<dynamic> newItems)? onSideItemsChanged;

  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersistSideItem;

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
    required this.sideLoading,
    required this.uploadProgress,
    this.onSideItemsChanged,
    this.onRenamePersistSideItem,
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

  bool _exibeValor() {
    return const [
      'VALOR',
      'REEQUÍLIBRIO',
      'RATIFICAÇÃO',
      'RENOVAÇÃO',
    ].contains(_currentType.toUpperCase());
  }

  bool _exibePrazo() {
    return const [
      'PRAZO',
      'RATIFICAÇÃO',
      'RENOVAÇÃO',
    ].contains(_currentType.toUpperCase());
  }

  void _onTypeChanged(String? value) {
    final v = (value ?? '').trim();

    widget.typeOfAdditiveCtrl.text = v;

    if (!_exibeValor()) {
      widget.valueController.clear();
    }

    if (!_exibePrazo()) {
      widget.additionalDaysContractController.clear();
      widget.additionalDaysExecutionController.clear();
    }

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
    final inputFormatters = <TextInputFormatter>[
      if (date) FilteringTextInputFormatter.digitsOnly,
      if (date) SipGedMasks.dateDDMMYYYY,
      if (money) const SipGedMoneyFormatter(),
      ?mask,
    ];

    final field = CustomTextField(
      width: width,
      controller: ctrl,
      enabled: enabled && isEditable,
      labelText: label,
      prefixText: money ? 'R\$ ' : null,
      keyboardType: date
          ? TextInputType.datetime
          : money
          ? TextInputType.number
          : null,
      inputFormatters: inputFormatters,
    );

    if (!tooltip) return field;

    return Tooltip(
      message: 'Este campo é calculado automaticamente e não pode ser editado.',
      child: field,
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
          reservedWidth: isSmallScreen ? 0.0 : sideWidth + 12.0,
          spacing: 12.0,
          margin: 12.0,
          extraPadding: 24.0,
          spaceBetweenReserved: 12.0,
        );

        final double minCardHeight = isSmallScreen ? 260.0 : 170.0;

        final bool canEditSide =
            widget.isEditable && widget.selectedAdditive != null;

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropDownChange(
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
              mask: SipGedMasks.processo,
              isEditable: widget.isEditable,
            ),
            DateFieldChange(
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
            DropDownChange(
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
              onPressed: widget.formValidated
                  ? widget.isEditable
                  ? widget.onSave
                  : null
                  : null,
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

        final side = BoxListFiles(
          title: 'Arquivos do Aditivo',
          items: widget.sideItems,
          selectedIndex: widget.selectedSideIndex,
          onAddPressed: canEditSide ? widget.onAddSideItem : null,
          onTap: widget.onTapSideItem == null
              ? null
              : (i) => widget.onTapSideItem!(i),
          onDelete: canEditSide && widget.onDeleteSideItem != null
              ? (i) => widget.onDeleteSideItem!(i)
              : null,
          width: sideWidth,
          loading: widget.sideLoading,
          uploadProgress: widget.uploadProgress,
          enableRename: canEditSide,
          onItemsChanged: widget.onSideItemsChanged,
          onRenamePersist: widget.onRenamePersistSideItem,
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