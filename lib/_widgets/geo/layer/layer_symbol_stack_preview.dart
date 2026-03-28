import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/preview/axis_preview_canvas.dart';

class LayerSymbolStackPreview extends StatelessWidget {
  final GeoLayersData layer;
  final bool isSelected;
  final bool isActive;

  const LayerSymbolStackPreview({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSymbols = layer.effectiveSymbolLayers
        .where((e) => e.enabled)
        .toList(growable: false);

    if (visibleSymbols.isEmpty) {
      final iconColor = isSelected
          ? Colors.white
          : (isActive ? layer.displayColor : Colors.grey);

      return SizedBox(
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
    }

    // No painel lateral, a pilha recebida por effectiveSymbolLayers
    // precisa ser invertida para que o item visualmente do topo
    // seja desenhado por último dentro do preview.
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

    return SizedBox(
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
}