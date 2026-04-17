import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data_binding.dart';

class AttributeTile extends StatefulWidget {
  final String label;
  final String value;
  final FeatureDataBinding? dragData;

  const AttributeTile({
    super.key,
    required this.label,
    required this.value,
    this.dragData,
  });

  @override
  State<AttributeTile> createState() => _AttributeTileState();
}

class _AttributeTileState extends State<AttributeTile> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dragData = widget.dragData;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor.withValues(
              alpha: (_hovered || _dragging) ? 0.60 : 0.35,
            ),
          ),
          borderRadius: BorderRadius.circular(10),
          color: (_hovered || _dragging)
              ? theme.colorScheme.primary.withValues(alpha: 0.03)
              : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dragData != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: _TileDragHandle(
                    dragData: dragData,
                    onDragStateChanged: (dragging) {
                      if (!mounted) return;
                      setState(() => _dragging = dragging);
                    },
                  ),
                ),
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.value.isEmpty ? '-' : widget.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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

class _TileDragHandle extends StatelessWidget {
  final FeatureDataBinding dragData;
  final ValueChanged<bool> onDragStateChanged;

  const _TileDragHandle({
    required this.dragData,
    required this.onDragStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final handle = Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.drag_indicator_rounded,
        size: 18,
        color: theme.colorScheme.primary.withValues(alpha: 0.85),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: LongPressDraggable<FeatureDataBinding>(
        data: dragData,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => onDragStateChanged(true),
        onDragEnd: (_) => onDragStateChanged(false),
        onDraggableCanceled: (_, _) => onDragStateChanged(false),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  color: Color(0x22000000),
                ),
              ],
            ),
            child: Text(
              dragData.displayValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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