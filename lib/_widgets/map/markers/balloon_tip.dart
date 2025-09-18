import 'package:flutter/material.dart';
import 'package:siged/_widgets/map/markers/triangle_painter.dart';

/// “Triângulo” do balão
class BalloonTip extends StatelessWidget {
  const BalloonTip({super.key, this.color = const Color(0xE6000000)}); // ~black 90%
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 6),
      painter: TrianglePainter(color: color),
    );
  }
}
