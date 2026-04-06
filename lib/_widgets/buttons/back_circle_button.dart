import 'package:flutter/material.dart';

class BackCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool outlined;
  final Color? borderColor;

  const BackCircleButton({
    super.key,
    this.icon = Icons.arrow_back,
    this.onPressed,
    this.radius = 24,
    this.backgroundColor,
    this.iconColor,
    this.tooltip = 'Voltar',
    this.outlined = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark ? Colors.grey.shade900 : Colors.white);

    final iconClr = iconColor ?? (isDark ? Colors.white : Colors.black87);

    final effectiveBorderColor = borderColor ??
        theme.dividerColor.withValues(alpha: 0.28);

    Widget button = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: IconButton(
        icon: Icon(icon, size: radius * 0.78),
        color: iconClr,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        tooltip: tooltip,
      ),
    );

    if (outlined) {
      button = Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: 1,
          ),
        ),
        child: button,
      );
    }

    return Tooltip(
      message: tooltip ?? '',
      child: button,
    );
  }
}