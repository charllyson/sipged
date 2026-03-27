import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_field_drag.dart';

class AttributePropertyTitle extends StatefulWidget {

  final String label;
  final GeoWorkspaceDataFieldDrag dragData;

  const AttributePropertyTitle({super.key,
    required this.label,
    required this.dragData,
  });

  @override
  State<AttributePropertyTitle> createState() => _AttributePropertyTitleState();
}

class _AttributePropertyTitleState extends State<AttributePropertyTitle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: _hovered ? 0.60 : 0.35),
        ),
        borderRadius: BorderRadius.circular(10),
        color: _hovered
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: IgnorePointer(
          ignoring: true,
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: theme.colorScheme.primary,
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

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Draggable<GeoWorkspaceDataFieldDrag>(
        data: widget.dragData,
        maxSimultaneousDrags: 1,
        feedback: AttributeFieldDrag(
          sourceLabel: widget.dragData.sourceLabel,
          fieldName: widget.dragData.fieldName,
          fieldValue: widget.dragData.fieldValue,
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: child,
        ),
        child: child,
      ),
    );
  }
}
