import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_change_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/form/form_symbology_preview.dart';

class FormSymbologyLayers extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerSimpleSymbolData> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const FormSymbologyLayers({
    super.key,
    required this.geometryKind,
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
  });

  String _labelForLayer(LayerSimpleSymbolData layer, int index) {
    switch (geometryKind) {
      case LayerGeometryKind.line:
        return 'Linha ${index + 1}';
      case LayerGeometryKind.polygon:
        return 'Polígono ${index + 1}';
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return layer.type == LayerSimpleSymbolType.svgMarker
            ? 'Marcador SVG ${index + 1}'
            : '${MarkerShapesCatalog.labelFor(layer.shapeType)} ${index + 1}';
    }
  }

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
                    'Símbolos',
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
                : RepaintBoundary(
              child: ListView.separated(
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
                          FormSymbologyPreview(
                            geometryKind: geometryKind,
                            symbol: layer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _labelForLayer(layer, index),
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
          ),
        ],
      ),
    );
  }
}