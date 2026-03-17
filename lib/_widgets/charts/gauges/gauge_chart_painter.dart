import 'package:flutter/material.dart';

class GaugeChartPainter extends CustomPainter {
  final Color trackColor;
  final double strokeWidth;
  final Color innerFillColor;

  GaugeChartPainter({
    required this.trackColor,
    required this.strokeWidth,
    this.innerFillColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2) - 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -3.14 / 2,
      3.14 * 1.7,
      false,
      trackPaint,
    );

    final innerCirclePaint = Paint()
      ..color = innerFillColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.35, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant GaugeChartPainter oldDelegate) {
    return oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.innerFillColor != innerFillColor;
  }
}