import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/simple_shape_painter.dart';

class SimpleMarkerShapeOption {
  final LayerSimpleMarkerShapeType value;
  final String label;

  const SimpleMarkerShapeOption({
    required this.value,
    required this.label,
  });
}

class SimpleMarkerShapesCatalog {
  SimpleMarkerShapesCatalog._();

  static const List<SimpleMarkerShapeOption> options = [
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.square, label: 'Quadrado'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.trapezoid, label: 'Trapézio'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.parallelogram, label: 'Paralelogramo'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.diamond, label: 'Losango'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.pentagon, label: 'Pentágono'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.hexagon, label: 'Hexágono'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.octagon, label: 'Octógono'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.decagon, label: 'Decágono'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.roundedSquare, label: 'Quadrado arredondado'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.triangle, label: 'Triângulo'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.star4, label: 'Estrela 4 pontas'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.star5, label: 'Estrela 5 pontas'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.heart, label: 'Coração'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.arrow, label: 'Seta'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.circle, label: 'Círculo'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.plus, label: 'Mais'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.cross, label: 'X'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.line, label: 'Linha'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.arc, label: 'Arco'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.semicircle, label: 'Semicírculo'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.quarterCircle, label: '1/4 de círculo'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.rectangle, label: 'Retângulo'),
    SimpleMarkerShapeOption(value: LayerSimpleMarkerShapeType.rightTriangle, label: 'Triângulo reto'),
  ];

  static String labelFor(LayerSimpleMarkerShapeType shape) {
    return options.firstWhere((e) => e.value == shape).label;
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
            height: 220,
            child: GridView.builder(
              itemCount: SimpleMarkerShapesCatalog.options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 12,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final option = SimpleMarkerShapesCatalog.options[index];
                final selected = option.value == selectedShape;

                return Tooltip(
                  message: option.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onChanged(option.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: selected ? Colors.blue.withValues(alpha: 0.10) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? Colors.blue : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(24, 24),
                          painter: SimpleShapePainter(
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}