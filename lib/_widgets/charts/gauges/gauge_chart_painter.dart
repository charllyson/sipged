import 'dart:math' as math;

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
    final Offset center = size.center(Offset.zero);

    final double radius = (size.shortestSide / 2) - (strokeWidth / 2) - 2.0;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.7,
      false,
      trackPaint,
    );

    final Paint innerCirclePaint = Paint()
      ..color = innerFillColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius * 0.35,
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant GaugeChartPainter oldDelegate) {
    return oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.innerFillColor != innerFillColor;
  }
}