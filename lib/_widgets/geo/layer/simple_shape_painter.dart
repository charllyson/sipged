import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class SimpleShapePainter extends CustomPainter {
  final LayerSimpleMarkerShapeType shape;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final double rotationDegrees;

  const SimpleShapePainter({
    required this.shape,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.rotationDegrees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDegrees * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _buildPath(rect, shape);

    if (shape == LayerSimpleMarkerShapeType.line ||
        shape == LayerSimpleMarkerShapeType.arc) {
      canvas.drawPath(path, stroke);
    } else {
      canvas.drawPath(path, fill);
      if (strokeWidth > 0) {
        canvas.drawPath(path, stroke);
      }
    }

    canvas.restore();
  }

  ui.Path _buildPath(Rect rect, LayerSimpleMarkerShapeType shape) {
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    switch (shape) {
      case LayerSimpleMarkerShapeType.square:
        return ui.Path()..addRect(rect);

      case LayerSimpleMarkerShapeType.rectangle:
        return ui.Path()
          ..addRect(
            Rect.fromCenter(
              center: rect.center,
              width: w * 0.55,
              height: h * 0.92,
            ),
          );

      case LayerSimpleMarkerShapeType.roundedSquare:
        return ui.Path()
          ..addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          );

      case LayerSimpleMarkerShapeType.trapezoid:
        return ui.Path()
          ..moveTo(l + w * 0.18, t + h * 0.28)
          ..lineTo(r - w * 0.18, t + h * 0.28)
          ..lineTo(r - w * 0.06, b - h * 0.08)
          ..lineTo(l + w * 0.06, b - h * 0.08)
          ..close();

      case LayerSimpleMarkerShapeType.parallelogram:
        return ui.Path()
          ..moveTo(l + w * 0.22, t + h * 0.18)
          ..lineTo(r - w * 0.02, t + h * 0.18)
          ..lineTo(r - w * 0.20, b - h * 0.12)
          ..lineTo(l, b - h * 0.12)
          ..close();

      case LayerSimpleMarkerShapeType.diamond:
        return ui.Path()
          ..moveTo(cx, t)
          ..lineTo(r, cy)
          ..lineTo(cx, b)
          ..lineTo(l, cy)
          ..close();

      case LayerSimpleMarkerShapeType.pentagon:
        return _regularPolygon(rect, 5);

      case LayerSimpleMarkerShapeType.hexagon:
        return _regularPolygon(rect, 6);

      case LayerSimpleMarkerShapeType.octagon:
        return _regularPolygon(rect, 8);

      case LayerSimpleMarkerShapeType.decagon:
        return _regularPolygon(rect, 10);

      case LayerSimpleMarkerShapeType.triangle:
        return ui.Path()
          ..moveTo(cx, t)
          ..lineTo(r, b)
          ..lineTo(l, b)
          ..close();

      case LayerSimpleMarkerShapeType.rightTriangle:
        return ui.Path()
          ..moveTo(l, b)
          ..lineTo(r, b)
          ..lineTo(l, t)
          ..close();

      case LayerSimpleMarkerShapeType.star4:
        return _star(rect, 4, innerFactor: 0.42);

      case LayerSimpleMarkerShapeType.star5:
        return _star(rect, 5, innerFactor: 0.45);

      case LayerSimpleMarkerShapeType.heart:
        return ui.Path()
          ..moveTo(cx, b)
          ..cubicTo(l - w * 0.10, h * 0.55, l + w * 0.02, t + h * 0.06, cx, h * 0.32)
          ..cubicTo(r - w * 0.02, t + h * 0.06, r + w * 0.10, h * 0.55, cx, b)
          ..close();

      case LayerSimpleMarkerShapeType.arrow:
        return ui.Path()
          ..moveTo(cx, t)
          ..lineTo(r, h * 0.34)
          ..lineTo(cx + w * 0.16, h * 0.34)
          ..lineTo(cx + w * 0.16, b)
          ..lineTo(cx - w * 0.16, b)
          ..lineTo(cx - w * 0.16, h * 0.34)
          ..lineTo(l, h * 0.34)
          ..close();

      case LayerSimpleMarkerShapeType.circle:
        return ui.Path()..addOval(rect);

      case LayerSimpleMarkerShapeType.plus:
        return ui.Path()
          ..addRect(Rect.fromCenter(center: rect.center, width: w * 0.26, height: h * 0.92))
          ..addRect(Rect.fromCenter(center: rect.center, width: w * 0.92, height: h * 0.26));

      case LayerSimpleMarkerShapeType.cross:
        return ui.Path()
          ..moveTo(l, t)
          ..lineTo(r, b)
          ..moveTo(r, t)
          ..lineTo(l, b);

      case LayerSimpleMarkerShapeType.line:
        return ui.Path()
          ..moveTo(cx, t)
          ..lineTo(cx, b);

      case LayerSimpleMarkerShapeType.arc:
        return ui.Path()
          ..addArc(
            Rect.fromCenter(center: rect.center, width: w * 0.9, height: h * 0.9),
            math.pi,
            math.pi * 0.78,
          );

      case LayerSimpleMarkerShapeType.semicircle:
        return ui.Path()
          ..moveTo(l, cy)
          ..arcTo(
            Rect.fromCenter(center: rect.center, width: w, height: h),
            math.pi,
            math.pi,
            false,
          )
          ..lineTo(r, cy)
          ..close();

      case LayerSimpleMarkerShapeType.quarterCircle:
        return ui.Path()
          ..moveTo(l, b)
          ..lineTo(l, t)
          ..arcTo(
            Rect.fromLTWH(l, t, w, h),
            math.pi,
            math.pi / 2,
            false,
          )
          ..lineTo(l, b)
          ..close();
    }
  }

  ui.Path _regularPolygon(Rect rect, int sides) {
    final path = ui.Path();
    final center = rect.center;
    final radius = math.min(rect.width, rect.height) / 2;
    final step = (math.pi * 2) / sides;

    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (i * step);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  ui.Path _star(Rect rect, int points, {double innerFactor = 0.5}) {
    final path = ui.Path();
    final center = rect.center;
    final outer = math.min(rect.width, rect.height) / 2;
    final inner = outer * innerFactor;
    final count = points * 2;
    final step = (math.pi * 2) / count;

    for (int i = 0; i < count; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + (i * step);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant SimpleShapePainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotationDegrees != rotationDegrees;
  }
}