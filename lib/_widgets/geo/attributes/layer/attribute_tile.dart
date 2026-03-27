import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_field_drag.dart';

class AttributeTile extends StatefulWidget {
  final String label;
  final String value;
  final GeoWorkspaceDataFieldDrag? dragData;

  const AttributeTile({super.key,
    required this.label,
    required this.value,
    this.dragData,
  });

  @override
  State<AttributeTile> createState() => _AttributeTileState();
}

class _AttributeTileState extends State<AttributeTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.drag_indicator_rounded,
          size: 18,
          color: theme.colorScheme.primary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
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
      ],
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: _hovered ? 0.60 : 0.35),
        ),
        borderRadius: BorderRadius.circular(10),
        color: _hovered
            ? theme.colorScheme.primary.withValues(alpha: 0.03)
            : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: IgnorePointer(
          ignoring: true,
          child: cardContent,
        ),
      ),
    );

    final dragData = widget.dragData;
    if (dragData == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Draggable<GeoWorkspaceDataFieldDrag>(
        data: dragData,
        maxSimultaneousDrags: 1,
        feedback: AttributeFieldDrag(
          sourceLabel: dragData.sourceLabel,
          fieldName: dragData.fieldName,
          fieldValue: dragData.fieldValue,
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: card,
        ),
        child: card,
      ),
    );
  }
}

