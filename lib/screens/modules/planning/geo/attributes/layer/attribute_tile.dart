import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data_drag.dart';
import 'package:sipged/screens/modules/planning/geo/attributes/layer/drag_handle.dart';

class AttributeTile extends StatefulWidget {
  final String label;
  final String value;
  final AttributeDataDrag? dragData;

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
                DragHandle(
                  dragData: dragData,
                  onDragStateChanged: (dragging) {
                    if (!mounted) return;
                    setState(() => _dragging = dragging);
                  },
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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