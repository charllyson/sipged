import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/geo/docking/dock_panel_config.dart';

class LightweightDragFeedback extends StatelessWidget {
  final DockPanelData group;
  final Color accent;

  const LightweightDragFeedback({super.key,
    required this.group,
    required this.accent,
  });

  double _feedbackWidth() {
    switch (group.area) {
      case DockArea.left:
      case DockArea.right:
        return group.dockExtent.clamp(220, 520).toDouble();
      case DockArea.top:
      case DockArea.bottom:
        return math.max(320, group.floatingSize.width);
      case DockArea.floating:
        return group.floatingSize.width;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(280, _feedbackWidth()).toDouble();

    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: Container(
          width: width,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.96),
            borderRadius: DockPanelConfig.panelRadius,
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (group.icon != null) ...[
                const SizedBox(width: 6),
                Icon(group.icon, size: 16, color: accent),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
