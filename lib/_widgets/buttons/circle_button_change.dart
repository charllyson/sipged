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

  /// Quando true, o botão fica visualmente ativo.
  final bool selected;

  /// Cores opcionais para o estado ativo.
  final Color? selectedBackgroundColor;
  final Color? selectedIconColor;
  final Color? selectedBorderColor;

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
    this.selected = false,
    this.selectedBackgroundColor,
    this.selectedIconColor,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBgColor =
        backgroundColor ?? (isDark ? Colors.grey.shade900 : Colors.white);

    final defaultIconColor =
        iconColor ?? (isDark ? Colors.white : Colors.black87);

    final defaultBorderColor =
        borderColor ?? theme.dividerColor.withValues(alpha: 0.28);

    final bgColor = selected
        ? (selectedBackgroundColor ?? Colors.white)
        : defaultBgColor;

    final iconClr = selected
        ? (selectedIconColor ?? Colors.black87)
        : defaultIconColor;

    final effectiveBorderColor = selected
        ? (selectedBorderColor ?? Colors.white)
        : defaultBorderColor;

    final effectiveIconSize = iconSize ?? (radius * 0.78);
    final size = radius * 2;

    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        boxShadow: selected
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                icon,
                key: ValueKey<IconData>(icon),
                size: effectiveIconSize,
                color: iconClr,
              ),
            ),
          ),
        ),
      ),
    );

    if (outlined) {
      child = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: selected ? 1.4 : 1,
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