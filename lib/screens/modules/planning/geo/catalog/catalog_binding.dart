import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_binding.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';

class CatalogBinding extends StatefulWidget {
  const CatalogBinding({
    super.key,
    required this.property,
    required this.onBindingDropped,
  });

  final CatalogData property;
  final ValueChanged<FeatureDataBinding> onBindingDropped;

  @override
  State<CatalogBinding> createState() => _CatalogBindingState();
}

class _CatalogBindingState extends State<CatalogBinding> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final binding = widget.property.bindingValue;
    final label = widget.property.label ?? '';

    final hasBinding = binding != null &&
        ((binding.sourceId ?? '').trim().isNotEmpty ||
            (binding.fieldName ?? '').trim().isNotEmpty);

    final display = hasBinding
        ? binding.displayValue
        : (widget.property.hint ?? 'Arraste um campo aqui');

    final primary = theme.colorScheme.primary;

    final Color borderColor;
    final Color backgroundColor;

    if (_dragging) {
      borderColor = primary.withValues(alpha: 0.65);
      backgroundColor = primary.withValues(alpha: 0.04);
    } else if (hasBinding) {
      borderColor = Colors.grey.shade500;
      backgroundColor = Colors.white;
    } else {
      borderColor = Colors.grey.shade400;
      backgroundColor = Colors.white;
    }

    return DragTarget<FeatureDataBinding>(
      onWillAcceptWithDetails: (_) {
        final accepts = widget.property.acceptsDrop;
        if (accepts && !_dragging) {
          setState(() => _dragging = true);
        }
        return accepts;
      },
      onLeave: (_) {
        if (mounted && _dragging) {
          setState(() => _dragging = false);
        }
      },
      onAcceptWithDetails: (details) {
        if (_dragging) {
          setState(() => _dragging = false);
        }
        widget.onBindingDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final active = _dragging || candidateData.isNotEmpty;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: active
                    ? primary.withValues(alpha: 0.04)
                    : backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? primary.withValues(alpha: 0.70)
                      : borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasBinding ? Icons.link_rounded : Icons.input_rounded,
                    size: 18,
                    color: hasBinding ? primary : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        hasBinding ? FontWeight.w500 : FontWeight.w400,
                        color: hasBinding
                            ? Colors.black.withValues(alpha: 0.82)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (label.isNotEmpty)
              Positioned(
                left: 12,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: Colors.white,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}