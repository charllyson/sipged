import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_shapes_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/geometry/shape_painter.dart';

class SymbologyMarkerLayersList extends StatelessWidget {
  final List<LayerSimpleSymbolData> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SymbologyMarkerLayersList({
    super.key,
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Marcadores',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: layers.isEmpty
                ? const Center(
              child: Text('Nenhum símbolo cadastrado.'),
            )
                : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: layers.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final layer = layers[index];
                final isSelected = selectedIndex == index;

                return InkWell(
                  onTap: () => onSelect(index),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 46),
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.10)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _SymbolLayerPreview(symbol: layer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            layer.type == LayerSimpleSymbolType.svgMarker
                                ? 'Marcador SVG ${index + 1}'
                                : '${MarkerShapesCatalog.labelFor(layer.shapeType)} ${index + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SymbolLayerPreview extends StatelessWidget {
  final LayerSimpleSymbolData symbol;

  const _SymbolLayerPreview({
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final previewWidth = symbol.width.clamp(10.0, 20.0);
    final previewHeight = symbol.height.clamp(10.0, 20.0);

    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Transform.rotate(
            angle: symbol.rotationDegrees * math.pi / 180,
            child: Icon(
              IconsCatalog.iconFor(symbol.iconKey),
              size: math.max(previewWidth, previewHeight),
              color: Color(symbol.fillColorValue),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Transform.rotate(
          angle: symbol.rotationDegrees * math.pi / 180,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ShapePainter(
                  shape: symbol.shapeType,
                  fillColor: Color(symbol.fillColorValue),
                  strokeColor: Color(symbol.strokeColorValue),
                  strokeWidth: symbol.strokeWidth.clamp(0.6, 1.5),
                  rotationDegrees: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}