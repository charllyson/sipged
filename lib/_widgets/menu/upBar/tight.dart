import 'package:flutter/material.dart';

/// Remove padding/constraints 48x48 padrão dos IconButtons.
class Tight extends StatelessWidget {
  final Widget child;

  const Tight({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (child is IconButton) {
      final b = child as IconButton;

      return IconButton(
        onPressed: b.onPressed,
        icon: b.icon,
        color: b.color,
        iconSize: b.iconSize,
        tooltip: b.tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
        splashRadius: b.iconSize != null ? b.iconSize! * 0.75 : 18,
      );
    }

    return child;
  }
}