import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

class FormSymbologyPreview extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final LayerSimpleSymbolData symbol;

  const FormSymbologyPreview({
    super.key,
    required this.geometryKind,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final previewWidth = symbol.width.clamp(10.0, 20.0);
    final previewHeight = symbol.height.clamp(10.0, 20.0);

    if (geometryKind == LayerGeometryKind.line) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(24, 24),
              painter: _MiniLinePreviewPainter(symbol),
            ),
          ),
        ),
      );
    }

    if (geometryKind == LayerGeometryKind.polygon) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(18, 18),
              painter: _MiniPolygonPreviewPainter(symbol),
            ),
          ),
        ),
      );
    }

    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Transform.rotate(
            angle: symbol.rotationDegrees * math.pi / 180,
            child: Icon(
              IconsCatalog.iconFor(symbol.iconKey),
              size: math.max(previewWidth, previewHeight),
              color: Color(symbol.fillColorValue),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Transform.rotate(
          angle: symbol.rotationDegrees * math.pi / 180,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ShapePainter(
                  shape: symbol.shapeType,
                  fillColor: Color(symbol.fillColorValue),
                  strokeColor: Color(symbol.strokeColorValue),
                  strokeWidth: symbol.strokeWidth.clamp(0.6, 1.5),
                  rotationDegrees: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniLinePreviewPainter extends CustomPainter {
  final LayerSimpleSymbolData symbol;

  const _MiniLinePreviewPainter(this.symbol);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(symbol.strokeColorValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = symbol.strokeWidth.clamp(1.2, 3.0)
      ..strokeCap = symbol.uiStrokeCap
      ..strokeJoin = symbol.uiStrokeJoin;

    final start = Offset(2, size.height / 2);
    final end = Offset(size.width - 2, size.height / 2);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(symbol.rotationDegrees * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    final dash = symbol.effectiveDashArray;
    if (symbol.strokePattern == LayerStrokePattern.solid || dash.isEmpty) {
      canvas.drawLine(start, end, paint);
    } else {
      _drawDashedLine(canvas, start, end, paint, dash);
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
  bool shouldRepaint(covariant _MiniLinePreviewPainter oldDelegate) {
    return oldDelegate.symbol != symbol;
  }
}

class _MiniPolygonPreviewPainter extends CustomPainter {
  final LayerSimpleSymbolData symbol;

  const _MiniPolygonPreviewPainter(this.symbol);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(symbol.fillColorValue);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Color(symbol.strokeColorValue)
      ..strokeWidth = symbol.strokeWidth.clamp(0.8, 2.0)
      ..strokeJoin = symbol.uiStrokeJoin
      ..strokeCap = symbol.uiStrokeCap;

    canvas.drawPath(path, fillPaint);

    final dash = symbol.effectiveDashArray;
    if (symbol.strokePattern == LayerStrokePattern.solid || dash.isEmpty) {
      canvas.drawPath(path, strokePaint);
      return;
    }

    final dashedPath = Path();
    final metrics = path.computeMetrics().toList(growable: false);

    for (final metric in metrics) {
      double current = 0;
      int index = 0;

      while (current < metric.length) {
        final segment = dash[index % dash.length];
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
  bool shouldRepaint(covariant _MiniPolygonPreviewPainter oldDelegate) {
    return oldDelegate.symbol != symbol;
  }
}