import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_header.dart';
import 'package:sipged/_widgets/draggable/light_weight_drag_feedback.dart';

class DraggableHeader extends StatelessWidget {
  final DockPanelData group;
  final Color accent;
  final bool isFloating;
  final VoidCallback onToggleFloating;
  final VoidCallback onHide;

  final VoidCallback onDragStarted;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DraggableDetails details) onDragEnd;

  const DraggableHeader({super.key,
    required this.group,
    required this.accent,
    required this.isFloating,
    required this.onToggleFloating,
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
      onHide: onHide,
    );

    if (group.floatingAsDialog) {
      return header;
    }

    return Draggable<DockDragPayload>(
      data: DockDragPayload(groupId: group.id),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      rootOverlay: true,
      feedback: LightweightDragFeedback(group: group, accent: accent),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      child: header,
    );
  }
}
