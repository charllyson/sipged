import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_catalog.dart';

class ShapePicker extends StatelessWidget {
  final LayerShapeType selectedShape;
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final ValueChanged<LayerShapeType> onChanged;

  const ShapePicker({
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
                  itemCount: ShapesCatalog.options.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final option = ShapesCatalog.options[index];
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
                              color: selected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
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