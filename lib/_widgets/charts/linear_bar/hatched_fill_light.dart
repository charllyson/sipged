import 'package:flutter/material.dart';
import 'package:siged/_widgets/charts/linear_bar/hatch_painter_light.dart';

/// ✅ Hachura inclinada LEVE
class HatchedFillLight extends StatelessWidget {
  final Color backgroundColor;
  final Color lineColor;
  final double strokeWidth;
  final double spacing;

  const HatchedFillLight({super.key,
    required this.backgroundColor,
    required this.lineColor,
    required this.strokeWidth,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HatchPainterLight(
        backgroundColor: backgroundColor,
        lineColor: lineColor,
        strokeWidth: strokeWidth,
        spacing: spacing,
      ),
      child: const SizedBox.expand(),
    );
  }
}