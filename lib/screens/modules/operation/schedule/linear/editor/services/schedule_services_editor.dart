import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';
import 'package:sipged/_widgets/buttons/order_buttons.dart';
import 'package:sipged/_widgets/draw/colors/colors_change_catalog.dart';
import 'package:sipged/_widgets/draw/icons/icon_picker_grid.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class ScheduleServicesEditor extends StatefulWidget {
  const ScheduleServicesEditor({
    super.key,
    required this.service,
    required this.isSelected,
    required this.isGeral,
    required this.onTap,
    required this.onRemove,
    required this.onChanged,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.compact,
  });

  final ScheduleLinearServicesData service;
  final bool isSelected;
  final bool isGeral;

  final VoidCallback onTap;
  final VoidCallback? onRemove;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onIconChanged;
  final ValueChanged<int>? onColorChanged;

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  final bool canMoveUp;
  final bool canMoveDown;
  final bool compact;

  @override
  State<ScheduleServicesEditor> createState() => _ScheduleServicesEditorState();
}

class _ScheduleServicesEditorState extends State<ScheduleServicesEditor> {
  static const double _fieldHeight = 56.0;
  static const double _iconBoxSize = 56.0;
  static const double _orderBoxWidth = 44.0;
  static const double _deleteBoxSize = 44.0;
  static const double _minTextFieldWidth = 220.0;

  late final TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();

    _labelCtrl = TextEditingController(
      text: widget.service.label.trim(),
    );
  }

  @override
  void didUpdateWidget(covariant ScheduleServicesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldText = oldWidget.service.label.trim();
    final newText = widget.service.label.trim();

    if (oldText != newText && _labelCtrl.text != newText) {
      _labelCtrl.text = newText;
      _labelCtrl.selection = TextSelection.collapsed(
        offset: _labelCtrl.text.length,
      );
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _openIconPicker(BuildContext context) async {
    if (widget.onIconChanged == null) return;

    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final isMobile = size.width < 720;

        final dialogWidth = isMobile ? size.width * 0.94 : 620.0;
        final dialogHeight = isMobile ? size.height * 0.82 : size.height * 0.76;
        final gridHeight = (dialogHeight - 96).clamp(260.0, 560.0);

        final selectedIconKey = widget.service.iconKey.trim().isEmpty
            ? ScheduleLinearServicesData.defaultServiceIconKey
            : widget.service.iconKey.trim();

        return SafeArea(
          child: Dialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 24,
              vertical: isMobile ? 10 : 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: widget.service.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            ScheduleLinearServicesData.iconForKey(
                              selectedIconKey,
                            ),
                            color: widget.service.color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Selecionar ícone do serviço',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop();
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SizedBox(
                        height: gridHeight,
                        child: IconPickerGrid(
                          selectedKey: selectedIconKey,
                          previewColor: widget.service.color,
                          maxColumns: isMobile ? 5 : 7,
                          maxGridHeight: gridHeight,
                          onChanged: (key) {
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(key);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final cleanResult = result?.trim();

    if (cleanResult == null || cleanResult.isEmpty) return;

    widget.onIconChanged!(cleanResult);
  }

  Widget _readonlyBox({
    required BuildContext context,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Container(
      height: _fieldHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _orderButtons() {
    if (widget.isGeral) {
      return const SizedBox(
        width: _orderBoxWidth,
        height: _fieldHeight,
      );
    }

    return OrderButtons(
      width: _orderBoxWidth,
      height: _fieldHeight,
      canMoveUp: widget.canMoveUp,
      canMoveDown: widget.canMoveDown,
      onMoveUp: widget.onMoveUp,
      onMoveDown: widget.onMoveDown,
    );
  }

  Widget _buildColorPicker() {
    return ColorsChangeCatalog(
      selectedColorValue: widget.service.color.toARGB32(),
      title: 'Cor',
      compactPreview: true,
      readOnly: widget.isGeral,
      showHexValue: false,
      showDropdownIcon: false,
      borderColor: Colors.grey.shade500,
      focusedBorderColor: Colors.blue,
      borderWidth: 1.0,
      borderRadius: 10,
      fillCollor: Colors.white,
      fontSize: 10,
      onChanged: (value) {
        if (widget.isGeral) return;
        if (widget.onColorChanged == null) return;

        widget.onColorChanged!(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolvedIconKey = widget.service.iconKey.trim().isEmpty
        ? ScheduleLinearServicesData.defaultServiceIconKey
        : widget.service.iconKey.trim();

    final resolvedIcon = widget.isGeral
        ? Icons.clear_all
        : ScheduleLinearServicesData.iconForKey(resolvedIconKey);

    final iconButton = Tooltip(
      message: widget.isGeral ? 'Ícone do serviço geral' : 'Alterar ícone',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isGeral ? null : () => _openIconPicker(context),
        child: Container(
          width: _iconBoxSize,
          height: _iconBoxSize,
          decoration: BoxDecoration(
            color: widget.service.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.service.color
                  : theme.dividerColor.withValues(alpha: 0.30),
            ),
          ),
          child: Icon(
            resolvedIcon,
            color: widget.service.color,
            size: 22,
          ),
        ),
      ),
    );

    final colorPickerField = _buildColorPicker();

    final nameField = widget.isGeral
        ? _readonlyBox(
      context: context,
      text: 'GERAL',
    )
        : CustomTextField(
      controller: _labelCtrl,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.done,
      labelText: 'Serviço',
      hintText: 'Ex: ASFALTO, BASE...',
      height: _fieldHeight,
    );

    final deleteButton = widget.onRemove == null
        ? const SizedBox(
      width: _deleteBoxSize,
      height: _deleteBoxSize,
    )
        : SizedBox(
      width: _deleteBoxSize,
      height: _fieldHeight,
      child: Center(
        child: IconButton(
          tooltip: 'Remover serviço',
          onPressed: widget.onRemove,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
        ),
      ),
    );

    final orderButtons = _orderButtons();

    return Material(
      color: widget.isSelected
          ? widget.service.color.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.service.color
                  : theme.dividerColor.withValues(alpha: 0.30),
              width: widget.isSelected ? 1.4 : 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                clipBehavior: Clip.none,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      iconButton,
                      const SizedBox(width: 10),
                      colorPickerField,
                      const SizedBox(width: 10),
                      orderButtons,
                      const SizedBox(width: 8),
                      SizedBox(
                        width: constraints.maxWidth > 520
                            ? constraints.maxWidth - 254
                            : _minTextFieldWidth,
                        child: nameField,
                      ),
                      const SizedBox(width: 6),
                      deleteButton,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}