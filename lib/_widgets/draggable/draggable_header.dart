import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_config.dart';
import 'package:sipged/_widgets/docking/dock_panel_header.dart';

class DraggableHeader extends StatelessWidget {
  final DockPanelData group;
  final Color accent;
  final bool isFloating;
  final VoidCallback onToggleFloating;
  final VoidCallback onToggleMinimized;
  final VoidCallback onHide;

  final VoidCallback onDragStarted;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DraggableDetails details) onDragEnd;

  const DraggableHeader({super.key,
    required this.group,
    required this.accent,
    required this.isFloating,
    required this.onToggleFloating,
    required this.onToggleMinimized,
    required this.onHide,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final header = DockPanelHeader(
      group: group,
      accent: accent,
      isFloating: isFloating,
      onToggleFloating: onToggleFloating,
      onToggleMinimized: onToggleMinimized,
      onHide: onHide,
    );

    if (group.floatingAsDialog) {
      return header;
    }

    return Draggable<DockDragPayload>(
      data: DockDragPayload(groupId: group.id),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      rootOverlay: true,
      feedback: _LightweightDragFeedback(group: group, accent: accent),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      child: header,
    );
  }
}

class _LightweightDragFeedback extends StatelessWidget {
  final DockPanelData group;
  final Color accent;

  const _LightweightDragFeedback({
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
