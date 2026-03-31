import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_draggable.dart';

class AttributeProperty extends StatefulWidget {
  final String label;
  final GeoWorkspaceDataFieldDrag dragData;

  const AttributeProperty({
    super.key,
    required this.label,
    required this.dragData,
  });

  @override
  State<AttributeProperty> createState() => _AttributePropertyState();
}

class _AttributePropertyState extends State<AttributeProperty> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              ? theme.colorScheme.primary.withValues(alpha: 0.04)
              : Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              AttributeDraggable(
                dragData: widget.dragData,
                onDragStateChanged: (dragging) {
                  if (!mounted) return;
                  setState(() => _dragging = dragging);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.link_rounded,
                size: 16,
                color: theme.colorScheme.primary.withValues(alpha: 0.80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
