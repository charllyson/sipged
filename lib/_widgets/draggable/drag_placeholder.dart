import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/docking/dock_panel_config.dart';

class DragPlaceholder extends StatelessWidget {
  final Color accent;

  const DragPlaceholder({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        borderRadius: DockPanelConfig.panelRadius,
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
        color: accent.withValues(alpha: 0.05),
      ),
    );
  }
}
