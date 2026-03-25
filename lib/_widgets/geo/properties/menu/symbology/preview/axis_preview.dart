import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

class AxisPreview extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerSimpleSymbolData> layers;

  const AxisPreview({
    super.key,
    required this.geometryKind,
    required this.layers,
  });

  @override
  Widget build(BuildContext context) {
    return AxisPreviewCanvas(
      geometryKind: geometryKind,
      layers: layers,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      showAxes: true,
      borderRadius: BorderRadius.circular(0),
    );
  }
}

class AxisPreviewCanvas extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerSimpleSymbolData> layers;
  final Color backgroundColor;
  final EdgeInsets padding;
  final bool showAxes;
  final BorderRadius borderRadius;

  const AxisPreviewCanvas({
    super.key,
    required this.geometryKind,
    required this.layers,
    this.backgroundColor = Colors.transparent,
    this.padding = EdgeInsets.zero,
    this.showAxes = true,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: backgroundColor,
          padding: padding,
          child: CustomPaint(
            isComplex: true,
            willChange: false,
            painter: AxisPreviewPainter(
              geometryKind: geometryKind,
              layers: List<LayerSimpleSymbolData>.unmodifiable(layers),
              showAxes: showAxes,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class AxisPreviewPainter extends CustomPainter {
  final LayerGeometryKind geometryKind;
  final List<LayerSimpleSymbolData> layers;
  final bool showAxes;

  const AxisPreviewPainter({
    required this.geometryKind,
    required this.layers,
    this.showAxes = true,
  });

  static const double _outerPadding = 10.0;
  static const double _baseLineHalf = 60.0;
  static const double _basePolygonWidth = 90.0;
  static const double _basePolygonHeight = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    if (showAxes) {
      final axisPaint = Paint()
        ..color = const Color(0xFF8B8B8B)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(center.dx, 12),
        Offset(center.dx, size.height - 12),
        axisPaint,
      );

      canvas.drawLine(
        Offset(12, center.dy),
        Offset(size.width - 12, center.dy),
        axisPaint,
      );
    }

    final visibleLayers = layers.where((e) => e.enabled).toList(growable: false);
    if (visibleLayers.isEmpty) return;

    final scale = _computeFitScale(size, visibleLayers);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    for (final layer in visibleLayers.reversed) {
      _drawLayer(canvas, size, center, layer);
    }

    canvas.restore();
  }

  double _computeFitScale(Size size, List<LayerSimpleSymbolData> visibleLayers) {
    switch (geometryKind) {
      case LayerGeometryKind.line:
        return _computeLineFitScale(size, visibleLayers);
      case LayerGeometryKind.polygon:
        return _computePolygonFitScale(size, visibleLayers);
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return _computePointFitScale(size, visibleLayers);
    }
  }

  double _computePointFitScale(Size size, List<LayerSimpleSymbolData> visibleLayers) {
    double maxW = 0;
    double maxH = 0;

    for (final layer in visibleLayers) {
      if (layer.type == LayerSimpleSymbolType.svgMarker) {
        maxW = math.max(maxW, math.max(layer.width, layer.height));
        maxH = math.max(maxH, math.max(layer.width, layer.height));
      } else {
        maxW = math.max(maxW, layer.width);
        maxH = math.max(maxH, layer.height);
      }
    }

    maxW += _outerPadding * 2;
    maxH += _outerPadding * 2;

    final scaleX = size.width / math.max(1, maxW);
    final scaleY = size.height / math.max(1, maxH);
    return math.min(1.0, math.min(scaleX, scaleY));
  }

  double _computeLineFitScale(Size size, List<LayerSimpleSymbolData> visibleLayers) {
    const baseHalf = _baseLineHalf;

    double minX = -baseHalf;
    double maxX = baseHalf;
    double minY = 0;
    double maxY = 0;

    for (final layer in visibleLayers) {
      final halfStroke = math.max(0.5, layer.strokeWidth / 2);
      final y = layer.offset;
      final localMinY = y - halfStroke;
      final localMaxY = y + halfStroke;

      minY = math.min(minY, localMinY);
      maxY = math.max(maxY, localMaxY);
    }

    final width = (maxX - minX) + (_outerPadding * 2);
    final height = (maxY - minY) + (_outerPadding * 2);

    final scaleX = size.width / math.max(1, width);
    final scaleY = size.height / math.max(1, height);

    return math.min(1.0, math.min(scaleX, scaleY));
  }

  double _computePolygonFitScale(Size size, List<LayerSimpleSymbolData> visibleLayers) {
    const baseW = _basePolygonWidth;
    const baseH = _basePolygonHeight;

    double extraStroke = 0;
    for (final layer in visibleLayers) {
      extraStroke = math.max(extraStroke, layer.strokeWidth);
    }

    final width = baseW + extraStroke + (_outerPadding * 2);
    final height = baseH + extraStroke + (_outerPadding * 2);

    final scaleX = size.width / math.max(1, width);
    final scaleY = size.height / math.max(1, height);

    return math.min(1.0, math.min(scaleX, scaleY));
  }

  void _drawLayer(
      Canvas canvas,
      Size size,
      Offset center,
      LayerSimpleSymbolData layer,
      ) {
    switch (geometryKind) {
      case LayerGeometryKind.line:
        _drawLinePreview(canvas, center, layer);
        return;
      case LayerGeometryKind.polygon:
        _drawPolygonPreview(canvas, center, layer);
        return;
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        _drawPointPreview(canvas, center, layer);
        return;
    }
  }

  void _drawPointPreview(
      Canvas canvas,
      Offset center,
      LayerSimpleSymbolData layer,
      ) {
    if (layer.type == LayerSimpleSymbolType.svgMarker) {
      final iconData = IconsCatalog.iconFor(layer.iconKey);
      final previewSize = math.max(1.0, math.max(layer.width, layer.height));

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: previewSize,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Color(layer.fillColorValue),
          ),
        ),
      )..layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(layer.rotationDegrees * math.pi / 180);
      canvas.translate(-center.dx, -center.dy);

      final iconOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, iconOffset);
      canvas.restore();
      return;
    }

    final width = math.max(1.0, layer.width);
    final height = math.max(1.0, layer.height);

    final painter = ShapePainter(
      shape: layer.shapeType,
      fillColor: Color(layer.fillColorValue),
      strokeColor: Color(layer.strokeColorValue),
      strokeWidth: math.max(0.1, layer.strokeWidth),
      rotationDegrees: layer.rotationDegrees,
    );

    canvas.save();
    canvas.translate(
      center.dx - (width / 2),
      center.dy - (height / 2),
    );
    painter.paint(canvas, Size(width, height));
    canvas.restore();
  }

  void _drawLinePreview(
      Canvas canvas,
      Offset center,
      LayerSimpleSymbolData layer,
      ) {
    final paint = Paint()
      ..color = layer.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.1, layer.strokeWidth)
      ..strokeCap = layer.uiStrokeCap
      ..strokeJoin = layer.uiStrokeJoin;

    final start = Offset(center.dx - _baseLineHalf, center.dy + layer.offset);
    final end = Offset(center.dx + _baseLineHalf, center.dy + layer.offset);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(layer.rotationDegrees * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    _drawStrokePatternLine(
      canvas: canvas,
      start: start,
      end: end,
      paint: paint,
      pattern: layer.strokePattern,
      dashArray: layer.effectiveDashArray,
    );

    canvas.restore();
  }

  void _drawPolygonPreview(
      Canvas canvas,
      Offset center,
      LayerSimpleSymbolData layer,
      ) {
    final fillPaint = Paint()
      ..color = layer.fillColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = layer.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.1, layer.strokeWidth)
      ..strokeCap = layer.uiStrokeCap
      ..strokeJoin = layer.uiStrokeJoin;

    final rect = Rect.fromCenter(
      center: center,
      width: _basePolygonWidth,
      height: _basePolygonHeight,
    );

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(layer.rotationDegrees * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawPath(path, fillPaint);

    if (layer.strokePattern == LayerStrokePattern.solid ||
        layer.effectiveDashArray.isEmpty) {
      canvas.drawPath(path, strokePaint);
    } else {
      final dashed = Path();
      final metrics = path.computeMetrics().toList(growable: false);
      final pattern = layer.effectiveDashArray;

      for (final metric in metrics) {
        double distance = 0;
        int index = 0;

        while (distance < metric.length) {
          final len = pattern[index % pattern.length];
          final isDraw = index.isEven;

          if (isDraw) {
            dashed.addPath(
              metric.extractPath(
                distance,
                math.min(distance + len, metric.length),
              ),
              Offset.zero,
            );
          }

          distance += len;
          index++;
        }
      }

      canvas.drawPath(dashed, strokePaint);
    }

    canvas.restore();
  }

  void _drawStrokePatternLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    required LayerStrokePattern pattern,
    required List<double> dashArray,
  }) {
    if (pattern == LayerStrokePattern.solid || dashArray.isEmpty) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final totalDx = end.dx - start.dx;
    final totalDy = end.dy - start.dy;
    final totalDistance = math.sqrt((totalDx * totalDx) + (totalDy * totalDy));

    if (totalDistance == 0) return;

    final unitX = totalDx / totalDistance;
    final unitY = totalDy / totalDistance;

    double distance = 0;
    int index = 0;

    while (distance < totalDistance) {
      final segment = dashArray[index % dashArray.length];
      final drawSegment = index.isEven;

      final from = distance;
      final to = math.min(distance + segment, totalDistance);

      if (drawSegment) {
        final p1 = Offset(
          start.dx + (unitX * from),
          start.dy + (unitY * from),
        );
        final p2 = Offset(
          start.dx + (unitX * to),
          start.dy + (unitY * to),
        );
        canvas.drawLine(p1, p2, paint);
      }

      distance += segment;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant AxisPreviewPainter oldDelegate) {
    if (oldDelegate.geometryKind != geometryKind) return true;
    if (oldDelegate.showAxes != showAxes) return true;
    if (oldDelegate.layers.length != layers.length) return true;

    for (int i = 0; i < layers.length; i++) {
      final a = oldDelegate.layers[i];
      final b = layers[i];

      if (a.id != b.id ||
          a.family != b.family ||
          a.enabled != b.enabled ||
          a.type != b.type ||
          a.iconKey != b.iconKey ||
          a.shapeType != b.shapeType ||
          a.width != b.width ||
          a.height != b.height ||
          a.fillColorValue != b.fillColorValue ||
          a.strokeColorValue != b.strokeColorValue ||
          a.strokeWidth != b.strokeWidth ||
          a.rotationDegrees != b.rotationDegrees ||
          a.strokePattern != b.strokePattern ||
          a.offset != b.offset ||
          a.useCustomDashPattern != b.useCustomDashPattern ||
          a.dashWidth != b.dashWidth ||
          a.dashGap != b.dashGap ||
          a.strokeJoin != b.strokeJoin ||
          a.strokeCap != b.strokeCap ||
          listEquals(a.dashArray, b.dashArray) == false) {
        return true;
      }
    }

    return false;
  }
}