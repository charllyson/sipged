import 'package:flutter/material.dart';

/// Remove padding/constraints 48x48 padrão dos IconButtons
class Tight extends StatelessWidget {
  final Widget child;
  const Tight({super.key, required this.child});

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
        constraints: const BoxConstraints(), // remove 48x48 padrão
      );
    }
    return child;
  }
}
