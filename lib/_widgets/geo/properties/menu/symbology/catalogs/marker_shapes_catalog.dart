import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/geometry/shape_painter.dart';

@immutable
class MarkerShapeOption {
  final LayerSimpleMarkerShapeType value;
  final String label;

  const MarkerShapeOption({
    required this.value,
    required this.label,
  });
}

class MarkerShapesCatalog {
  MarkerShapesCatalog._();

  static const List<MarkerShapeOption> options = [
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.square,
      label: 'Quadrado',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.trapezoid,
      label: 'Trapézio',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.parallelogram,
      label: 'Paralelogramo',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.diamond,
      label: 'Losango',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.pentagon,
      label: 'Pentágono',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.hexagon,
      label: 'Hexágono',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.octagon,
      label: 'Octógono',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.decagon,
      label: 'Decágono',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.roundedSquare,
      label: 'Quadrado arredondado',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.triangle,
      label: 'Triângulo',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.star4,
      label: 'Estrela 4 pontas',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.star5,
      label: 'Estrela 5 pontas',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.heart,
      label: 'Coração',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.arrow,
      label: 'Seta',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.circle,
      label: 'Círculo',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.plus,
      label: 'Mais',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.cross,
      label: 'X',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.line,
      label: 'Linha',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.arc,
      label: 'Arco',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.semicircle,
      label: 'Semicírculo',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.quarterCircle,
      label: '1/4 de círculo',
    ),
    MarkerShapeOption(
      value: LayerSimpleMarkerShapeType.rectangle,
      label: 'Retângulo',
    ),
    MarkerShapeOption(
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