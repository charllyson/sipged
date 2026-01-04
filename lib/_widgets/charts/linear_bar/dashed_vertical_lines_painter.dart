import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashedVerticalLinesPainter extends CustomPainter {
  final double x1;
  final double x2;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  DashedVerticalLinesPainter({
    required this.x1,
    required this.x2,
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    void drawDashedVertical(double x) {
      double y = 0;
      while (y < size.height) {
        final y2 = math.min(y + dashWidth, size.height);
        canvas.drawLine(Offset(x, y), Offset(x, y2), p);
        y += dashWidth + dashGap;
      }
    }

    drawDashedVertical(x1);
    drawDashedVertical(x2);
  }

  @override
  bool shouldRepaint(covariant DashedVerticalLinesPainter oldDelegate) {
    return oldDelegate.x1 != x1 ||
        oldDelegate.x2 != x2 ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}
