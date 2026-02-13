import 'package:flutter/material.dart';

class WindowCircleButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;
  final String? tooltip;
  final Widget? icon;

  const WindowCircleButton({
    super.key,
    required this.color,
    this.onTap,
    this.disabled = false,
    this.tooltip,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const size = 16.0;
    final effectiveColor = disabled ? color.withValues(alpha: 0.5) : color;

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            offset: const Offset(0, 0.5),
            color: Colors.black.withValues(alpha: 0.25),
          ),
        ],
      ),
      child: icon == null
          ? null
          : Center(
        child: IconTheme(
          data: const IconThemeData(size: 9),
          child: icon!,
        ),
      ),
    );

    if (!disabled && onTap != null) {
      circle = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: circle,
        ),
      );
    }

    if (tooltip != null) {
      circle = Tooltip(
        message: tooltip!,
        child: circle,
      );
    }

    return circle;
  }
}
