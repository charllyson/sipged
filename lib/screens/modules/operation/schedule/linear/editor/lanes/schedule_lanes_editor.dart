import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_widgets/buttons/order_buttons.dart';
import 'package:sipged/_widgets/draw/colors/colors_change_catalog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class ScheduleLanesEditor extends StatelessWidget {
  const ScheduleLanesEditor({
    super.key,
    required this.index,
    required this.data,
    required this.canRemove,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onPosChanged,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.compact,
  });

  final int index;
  final ScheduleLinearLaneData data;

  final bool canRemove;
  final bool canMoveUp;
  final bool canMoveDown;

  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  final ValueChanged<String> onPosChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onColorChanged;

  final bool compact;

  static const double _fieldHeight = 56.0;
  static const double _avatarBoxWidth = 34.0;
  static const double _orderBoxWidth = 44.0;
  static const double _removeBoxWidth = 48.0;
  static const double _posFieldWidth = 76.0;
  static const double _nameFieldMinWidth = 220.0;

  Widget _buildColorPicker() {
    return ColorsChangeCatalog(
      selectedColorValue: data.color.toARGB32(),
      title: 'Cor',
      compactPreview: true,
      showHexValue: false,
      showDropdownIcon: false,
      borderColor: Colors.grey.shade500,
      focusedBorderColor: Colors.blue,
      borderWidth: 1.0,
      borderRadius: 10,
      fillCollor: Colors.white,
      fontSize: 10,
      onChanged: onColorChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final indexAvatar = SizedBox(
      width: _avatarBoxWidth,
      height: _fieldHeight,
      child: Center(
        child: Tooltip(
          message: 'Faixa ${index + 1}',
          child: CircleAvatar(
            radius: 15,
            backgroundColor: data.color.withValues(alpha: 0.16),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: data.color,
              ),
            ),
          ),
        ),
      ),
    );

    final colorButton = _buildColorPicker();

    final orderButtons = OrderButtons(
      width: _orderBoxWidth,
      height: _fieldHeight,
      canMoveUp: canMoveUp,
      canMoveDown: canMoveDown,
      onMoveUp: onMoveUp,
      onMoveDown: onMoveDown,
    );

    final removeButton = canRemove
        ? SizedBox(
      width: _removeBoxWidth,
      height: _fieldHeight,
      child: Center(
        child: IconButton(
          tooltip: 'Remover faixa',
          onPressed: onRemove,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
        ),
      ),
    )
        : const SizedBox(
      width: _removeBoxWidth,
      height: _fieldHeight,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.30),
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
                  indexAvatar,
                  const SizedBox(width: 10),
                  colorButton,
                  const SizedBox(width: 10),
                  orderButtons,
                  const SizedBox(width: 8),
                  SizedBox(
                    width: _posFieldWidth,
                    child: CustomTextField(
                      controller: data.posCtrl,
                      onChanged: onPosChanged,
                      textInputAction: TextInputAction.next,
                      labelText: 'Posição',
                      hintText: 'LE, CE, LD...',
                      height: _fieldHeight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: constraints.maxWidth > 600
                        ? constraints.maxWidth - 330
                        : _nameFieldMinWidth,
                    child: CustomTextField(
                      controller: data.nameCtrl,
                      onChanged: onNameChanged,
                      textInputAction: TextInputAction.done,
                      labelText: 'Nome da faixa',
                      hintText: 'PISTA ATUAL, CANTEIRO...',
                      height: _fieldHeight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  removeButton,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}