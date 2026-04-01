import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/preview/axis_preview_canvas.dart';

class LayerPreview extends StatelessWidget {
  final LayerData layer;
  final bool isSelected;
  final bool isActive;
  final bool hasData;

  const LayerPreview({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.isActive,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSymbols = layer.effectiveSymbolLayers
        .where((e) => e.enabled)
        .toList(growable: false);

    final statusColor = hasData ? const Color(0xFF22C55E) : Colors.grey.shade500;
    final statusBorderColor =
    isSelected ? Colors.white : Colors.black.withValues(alpha: 0.18);

    Widget previewContent;

    if (visibleSymbols.isEmpty) {
      final iconColor = isSelected
          ? Colors.white
          : (isActive ? layer.displayColor : Colors.grey);

      previewContent = SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            IconsCatalog.iconFor(layer.displayIconKey),
            size: 18,
            color: iconColor,
          ),
        ),
      );
    } else {
      final previewSymbols = visibleSymbols.reversed.toList(growable: false);

      final backgroundColor = isSelected
          ? Colors.white.withValues(alpha: 0.16)
          : isActive
          ? Colors.black.withValues(alpha: 0.03)
          : Colors.grey.withValues(alpha: 0.08);

      final borderColor = isSelected
          ? Colors.white.withValues(alpha: 0.35)
          : isActive
          ? layer.displayColor.withValues(alpha: 0.30)
          : Colors.grey.withValues(alpha: 0.22);

      previewContent = SizedBox(
        width: 28,
        height: 28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AxisPreviewCanvas(
              geometryKind: layer.geometryKind,
              layers: previewSymbols,
              showAxes: false,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: previewContent),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusBorderColor,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}