// lib/screens/modules/operation/schedule/common/schedule_layer_order_buttons.dart

import 'package:flutter/material.dart';

class OrderButtons extends StatelessWidget {
  const OrderButtons({
    super.key,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    this.width = 44.0,
    this.height = 52.0,
    this.buttonWidth = 30.0,
    this.buttonHeight = 24.0,
    this.iconSize = 21.0,
    this.enabledColor = Colors.black87,
    this.disabledColor = Colors.black26,
  });

  final bool canMoveUp;
  final bool canMoveDown;

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  final double width;
  final double height;
  final double buttonWidth;
  final double buttonHeight;
  final double iconSize;

  final Color enabledColor;
  final Color disabledColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ScheduleLayerOrderButton(
            tooltip: 'Subir camada',
            icon: Icons.keyboard_arrow_up_rounded,
            enabled: canMoveUp && onMoveUp != null,
            onTap: onMoveUp,
            width: buttonWidth,
            height: buttonHeight,
            iconSize: iconSize,
            enabledColor: enabledColor,
            disabledColor: disabledColor,
          ),
          _ScheduleLayerOrderButton(
            tooltip: 'Descer camada',
            icon: Icons.keyboard_arrow_down_rounded,
            enabled: canMoveDown && onMoveDown != null,
            onTap: onMoveDown,
            width: buttonWidth,
            height: buttonHeight,
            iconSize: iconSize,
            enabledColor: enabledColor,
            disabledColor: disabledColor,
          ),
        ],
      ),
    );
  }
}

class _ScheduleLayerOrderButton extends StatelessWidget {
  const _ScheduleLayerOrderButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.width,
    required this.height,
    required this.iconSize,
    required this.enabledColor,
    required this.disabledColor,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  final double width;
  final double height;
  final double iconSize;

  final Color enabledColor;
  final Color disabledColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: width,
          height: height,
          child: Icon(
            icon,
            size: iconSize,
            color: enabled ? enabledColor : disabledColor,
          ),
        ),
      ),
    );
  }
}