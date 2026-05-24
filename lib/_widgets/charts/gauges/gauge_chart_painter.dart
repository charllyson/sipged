// lib/_widgets/charts/gauges/gauge_chart_painter.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

class GaugeChartPainter extends CustomPainter {
  final Color trackColor;
  final double strokeWidth;
  final Color innerFillColor;

  /// Quantidade de anéis desenhados no shimmer.
  final int ringsCount;

  /// Espaço entre anéis.
  final double ringGap;

  GaugeChartPainter({
    required this.trackColor,
    required this.strokeWidth,
    this.innerFillColor = Colors.white,
    this.ringsCount = 1,
    this.ringGap = 7.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    final int safeRingsCount = ringsCount.clamp(1, 6);

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double outerRadius =
        (size.shortestSide / 2) - (strokeWidth / 2) - 2.0;

    for (int index = 0; index < safeRingsCount; index++) {
      final double radius = outerRadius - (index * (strokeWidth + ringGap));

      if (radius <= 18.0) {
        break;
      }

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
    }

    final double innerRadius = math.max(
      8.0,
      outerRadius - (safeRingsCount * (strokeWidth + ringGap)),
    );

    final Paint innerCirclePaint = Paint()
      ..color = innerFillColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      innerRadius * 0.42,
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant GaugeChartPainter oldDelegate) {
    return oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.innerFillColor != innerFillColor ||
        oldDelegate.ringsCount != ringsCount ||
        oldDelegate.ringGap != ringGap;
  }
}