import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';
import 'package:sipged/_widgets/resize/resize_data.dart';

class TabPropertyBinding extends StatefulWidget {
  const TabPropertyBinding({
    super.key,
    required this.item,
    required this.property,
    required this.featuresByLayer,
    required this.onBindingDropped,
  });

  final ResizeData item;
  final GeoWorkspaceDataProperty property;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final ValueChanged<GeoWorkspaceDataFieldDrag> onBindingDropped;

  @override
  State<TabPropertyBinding> createState() => _TabPropertyBindingState();
}

class _TabPropertyBindingState extends State<TabPropertyBinding> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final binding = widget.property.bindingValue;
    final hasBinding = binding != null &&
        ((binding.sourceId ?? '').trim().isNotEmpty ||
            (binding.fieldName ?? '').trim().isNotEmpty);

    final display = hasBinding
        ? binding.displayValue
        : (widget.property.hint ?? 'Arraste um campo aqui');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<GeoWorkspaceDataFieldDrag>(
          onWillAcceptWithDetails: (_) {
            final accepts = widget.property.acceptsDrop;
            if (accepts) {
              setState(() => _dragging = true);
            }
            return accepts;
          },
          onLeave: (_) {
            if (mounted) {
              setState(() => _dragging = false);
            }
          },
          onAcceptWithDetails: (details) {
            setState(() => _dragging = false);
            widget.onBindingDropped(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final active = _dragging || candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.06)
                    : hasBinding
                    ? theme.colorScheme.primary.withValues(alpha: 0.025)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active
                      ? theme.colorScheme.primary.withValues(alpha: 0.55)
                      : hasBinding
                      ? theme.colorScheme.primary.withValues(alpha: 0.24)
                      : Colors.black.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasBinding ? Icons.link_rounded : Icons.input_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasBinding ? FontWeight.w600 : FontWeight.w500,
                        color: hasBinding
                            ? Colors.black.withValues(alpha: 0.84)
                            : Colors.black.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
