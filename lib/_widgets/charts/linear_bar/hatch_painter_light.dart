
import 'package:flutter/material.dart';

class HatchPainterLight extends CustomPainter {
  final Color backgroundColor;
  final Color lineColor;
  final double strokeWidth;
  final double spacing;

  HatchPainterLight({
    required this.backgroundColor,
    required this.lineColor,
    required this.strokeWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bg);

    final p = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final double h = size.height;
    final double w = size.width;

    for (double x = -h; x < w + h; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), p);
    }
  }

  @override
  bool shouldRepaint(covariant HatchPainterLight oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.spacing != spacing;
  }
}
