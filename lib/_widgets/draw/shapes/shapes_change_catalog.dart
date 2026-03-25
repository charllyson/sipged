import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

@immutable
class ShapeChangeCatalog {
  final LayerSimpleMarkerShapeType value;
  final String label;

  const ShapeChangeCatalog({
    required this.value,
    required this.label,
  });
}

class MarkerShapesCatalog {
  MarkerShapesCatalog._();

  static const List<ShapeChangeCatalog> options = [
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.square,
      label: 'Quadrado',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.trapezoid,
      label: 'Trapézio',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.parallelogram,
      label: 'Paralelogramo',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.diamond,
      label: 'Losango',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.pentagon,
      label: 'Pentágono',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.hexagon,
      label: 'Hexágono',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.octagon,
      label: 'Octógono',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.decagon,
      label: 'Decágono',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.roundedSquare,
      label: 'Quadrado arredondado',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.triangle,
      label: 'Triângulo',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.star4,
      label: 'Estrela 4 pontas',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.star5,
      label: 'Estrela 5 pontas',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.heart,
      label: 'Coração',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.arrow,
      label: 'Seta',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.circle,
      label: 'Círculo',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.plus,
      label: 'Mais',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.cross,
      label: 'X',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.line,
      label: 'Linha',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.arc,
      label: 'Arco',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.semicircle,
      label: 'Semicírculo',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.quarterCircle,
      label: '1/4 de círculo',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.rectangle,
      label: 'Retângulo',
    ),
    ShapeChangeCatalog(
      value: LayerSimpleMarkerShapeType.rightTriangle,
      label: 'Triângulo reto',
    ),
  ];

  static String labelFor(LayerSimpleMarkerShapeType shape) {
    for (final option in options) {
      if (option.value == shape) return option.label;
    }
    return shape.name;
  }
}

class SimpleMarkerShapePicker extends StatelessWidget {
  final LayerSimpleMarkerShapeType selectedShape;
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final ValueChanged<LayerSimpleMarkerShapeType> onChanged;

  const SimpleMarkerShapePicker({
    super.key,
    required this.selectedShape,
    required this.fillColorValue,
    required this.strokeColorValue,
    required this.strokeWidth,
    required this.onChanged,
  });

  int _resolveColumns(double width) {
    if (width < 320) return 4;
    if (width < 420) return 5;
    if (width < 560) return 6;
    if (width < 760) return 7;
    if (width < 980) return 8;
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = Color(fillColorValue);
    final strokeColor = Color(strokeColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forma geométrica',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SizedBox(
            height: 250,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _resolveColumns(constraints.maxWidth);

                return GridView.builder(
                  itemCount: MarkerShapesCatalog.options.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final option = MarkerShapesCatalog.options[index];
                    final selected = option.value == selectedShape;

                    return Tooltip(
                      message: option.label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onChanged(option.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue.withValues(alpha: 0.10)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                              selected ? Colors.blue : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                size: const Size(24, 24),
                                painter: ShapePainter(
                                  shape: option.value,
                                  fillColor: fillColor,
                                  strokeColor: strokeColor,
                                  strokeWidth: strokeWidth,
                                  rotationDegrees: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}