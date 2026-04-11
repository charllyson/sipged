import 'package:flutter/material.dart';

class DraggablePlaceholder extends StatelessWidget {
  const DraggablePlaceholder({
    super.key,
    required this.accent,
  });

  final Color accent;

  static const BorderRadius _panelRadius = BorderRadius.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        borderRadius: _panelRadius,
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
        color: accent.withValues(alpha: 0.05),
      ),
    );
  }
}