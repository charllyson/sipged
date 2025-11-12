import 'package:flutter/material.dart';

class BackCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const BackCircleButton({
    super.key,
    this.icon = Icons.arrow_back,
    this.onPressed,
    this.radius = 24,
    this.backgroundColor,
    this.iconColor,
    this.tooltip = 'Voltar',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? Colors.grey.shade900 : Colors.white);
    final iconClr = iconColor ?? (isDark ? Colors.white : Colors.black87);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: IconButton(
        icon: Icon(icon, size: radius * 0.9),
        color: iconClr,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        tooltip: tooltip,
      ),
    );
  }
}
