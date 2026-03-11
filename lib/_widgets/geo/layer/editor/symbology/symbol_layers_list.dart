import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/icons_catalog.dart';
import 'package:sipged/_widgets/geo/layer/simple_marker_shapes_catalog.dart';
import 'package:sipged/_widgets/geo/layer/simple_shape_painter.dart';

class SymbolLayersList extends StatelessWidget {
  final List<LayerSimpleSymbolData> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SymbolLayersList({
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
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Marcador',
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
                : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: layers.length,
              itemBuilder: (context, index) {
                final layer = layers[index];
                final isSelected = selectedIndex == index;

                return InkWell(
                  onTap: () => onSelect(index),
                  child: Container(
                    height: 40,
                    color: isSelected
                        ? Colors.grey.shade300
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 6),
                        _SymbolLayerPreview(symbol: layer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            layer.type == LayerSimpleSymbolType.svgMarker
                                ? 'Marcador SVG ${index + 1}'
                                : '${SimpleMarkerShapesCatalog.labelFor(layer.shapeType)} ${index + 1}',
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
        width: 22,
        height: 22,
        child: Center(
          child: Transform.rotate(
            angle: symbol.rotationDegrees * 3.141592653589793 / 180,
            child: Icon(
              IconsCatalog.iconFor(symbol.iconKey),
              size: previewWidth > previewHeight ? previewWidth : previewHeight,
              color: Color(symbol.fillColorValue),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Transform.rotate(
          angle: symbol.rotationDegrees * 3.141592653589793 / 180,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CustomPaint(
              painter: SimpleShapePainter(
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
    );
  }
}