import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class LayerMiniPreviewPolygon extends CustomPainter {
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final LayerStrokePattern strokePattern;
  final List<double> dashArray;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  const LayerMiniPreviewPolygon({
    required this.fillColorValue,
    required this.strokeColorValue,
    required this.strokeWidth,
    required this.strokePattern,
    required this.dashArray,
    required this.strokeCap,
    required this.strokeJoin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(fillColorValue);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Color(strokeColorValue)
      ..strokeWidth = strokeWidth.clamp(0.8, 2.0)
      ..strokeJoin = strokeJoin
      ..strokeCap = strokeCap;

    canvas.drawPath(path, fillPaint);

    if (strokePattern == LayerStrokePattern.solid || dashArray.isEmpty) {
      canvas.drawPath(path, strokePaint);
      return;
    }

    final dashedPath = Path();
    final metrics = path.computeMetrics().toList(growable: false);

    for (final metric in metrics) {
      double current = 0;
      int index = 0;

      while (current < metric.length) {
        final segment = dashArray[index % dashArray.length];
        final draw = index.isEven;
        final next = math.min(current + segment, metric.length);

        if (draw) {
          dashedPath.addPath(
            metric.extractPath(current, next),
            Offset.zero,
          );
        }

        current += segment;
        index++;
      }
    }

    canvas.drawPath(dashedPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant LayerMiniPreviewPolygon oldDelegate) {
    return oldDelegate.fillColorValue != fillColorValue ||
        oldDelegate.strokeColorValue != strokeColorValue ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.strokePattern != strokePattern ||
        oldDelegate.strokeCap != strokeCap ||
        oldDelegate.strokeJoin != strokeJoin ||
        !listEquals(oldDelegate.dashArray, dashArray);
  }
}