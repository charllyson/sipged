import 'package:flutter/material.dart';

class CircleButtonChange extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double radius;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool outlined;
  final Color? borderColor;

  const CircleButtonChange({
    super.key,
    this.icon = Icons.arrow_back,
    this.onPressed,
    this.radius = 24,
    this.iconSize,
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

    final bgColor =
        backgroundColor ?? (isDark ? Colors.grey.shade900 : Colors.white);

    final iconClr = iconColor ?? (isDark ? Colors.white : Colors.black87);

    final effectiveBorderColor =
        borderColor ?? theme.dividerColor.withValues(alpha: 0.28);

    final effectiveIconSize = iconSize ?? (radius * 0.78);
    final size = radius * 2;

    Widget child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Center(
            child: Icon(
              icon,
              size: effectiveIconSize,
              color: iconClr,
            ),
          ),
        ),
      ),
    );

    if (outlined) {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: 1,
          ),
        ),
        child: child,
      );
    }

    return Tooltip(
      message: tooltip ?? '',
      child: child,
    );
  }
}