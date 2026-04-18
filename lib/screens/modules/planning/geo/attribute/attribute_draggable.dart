import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_binding.dart';
import 'package:sipged/_widgets/draggable/draggable_field.dart';

class AttributeDraggable extends StatelessWidget {
  final FeatureDataBinding dragData;
  final ValueChanged<bool> onDragStateChanged;

  const AttributeDraggable({
    super.key,
    required this.dragData,
    required this.onDragStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final handle = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.drag_indicator_rounded,
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<FeatureDataBinding>(
        data: dragData,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => onDragStateChanged(true),
        onDragEnd: (_) => onDragStateChanged(false),
        onDraggableCanceled: (_, _) => onDragStateChanged(false),
        feedback: DraggableField(
          sourceLabel: dragData.sourceLabel ?? '',
          fieldName: dragData.fieldName ?? '',
          fieldValue: dragData.fieldValue,
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: handle,
        ),
        child: handle,
      ),
    );
  }
}