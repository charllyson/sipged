import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class LayerMiniPreviewPainter extends CustomPainter {
  final int strokeColorValue;
  final double strokeWidth;
  final double rotationDegrees;
  final LayerStrokePattern strokePattern;
  final List<double> dashArray;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  const LayerMiniPreviewPainter({
    required this.strokeColorValue,
    required this.strokeWidth,
    required this.rotationDegrees,
    required this.strokePattern,
    required this.dashArray,
    required this.strokeCap,
    required this.strokeJoin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(strokeColorValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.clamp(1.2, 3.0)
      ..strokeCap = strokeCap
      ..strokeJoin = strokeJoin;

    final start = Offset(2, size.height / 2);
    final end = Offset(size.width - 2, size.height / 2);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationDegrees * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    if (strokePattern == LayerStrokePattern.solid || dashArray.isEmpty) {
      canvas.drawLine(start, end, paint);
    } else {
      _drawDashedLine(canvas, start, end, paint, dashArray);
    }

    canvas.restore();
  }

  void _drawDashedLine(
      Canvas canvas,
      Offset start,
      Offset end,
      Paint paint,
      List<double> dashArray,
      ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final ux = dx / distance;
    final uy = dy / distance;

    double current = 0;
    int index = 0;

    while (current < distance) {
      final segment = dashArray[index % dashArray.length];
      final draw = index.isEven;
      final next = math.min(current + segment, distance);

      if (draw) {
        final p1 = Offset(start.dx + ux * current, start.dy + uy * current);
        final p2 = Offset(start.dx + ux * next, start.dy + uy * next);
        canvas.drawLine(p1, p2, paint);
      }

      current += segment;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant LayerMiniPreviewPainter oldDelegate) {
    return oldDelegate.strokeColorValue != strokeColorValue ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotationDegrees != rotationDegrees ||
        oldDelegate.strokePattern != strokePattern ||
        oldDelegate.strokeCap != strokeCap ||
        oldDelegate.strokeJoin != strokeJoin ||
        !listEquals(oldDelegate.dashArray, dashArray);
  }
}