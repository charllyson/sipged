import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_types.dart';

class GeoWorkspaceGuidePainter extends CustomPainter {
  const GeoWorkspaceGuidePainter({
    required this.guides,
  });

  final GeoWorkspaceGuideLines? guides;

  @override
  void paint(Canvas canvas, Size size) {
    final current = guides;
    if (current == null) return;

    final linePaint = Paint()
      ..color = const Color(0xFF2E7DFF).withValues(alpha: 0.9)
      ..strokeWidth = 1.0;

    final dashPaint = Paint()
      ..color = const Color(0xFF2E7DFF).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    if (current.vertical != null) {
      final x = current.vertical!;
      _drawDashedLine(
        canvas: canvas,
        p1: Offset(x, 0),
        p2: Offset(x, size.height),
        paint: dashPaint,
      );
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    if (current.horizontal != null) {
      final y = current.horizontal!;
      _drawDashedLine(
        canvas: canvas,
        p1: Offset(0, y),
        p2: Offset(size.width, y),
        paint: dashPaint,
      );
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _drawDashedLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required Paint paint,
  }) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final delta = p2 - p1;
    final distance = delta.distance;
    if (distance <= 0) return;

    final direction = delta / distance;
    double start = 0;

    while (start < distance) {
      final end = math.min(start + dashWidth, distance);
      final from = p1 + direction * start;
      final to = p1 + direction * end;
      canvas.drawLine(from, to, paint);
      start += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant GeoWorkspaceGuidePainter oldDelegate) {
    return oldDelegate.guides != guides;
  }
}