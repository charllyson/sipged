import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

class AxisPreviewPainter extends CustomPainter {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> layers;
  final bool showAxes;

  final String? overlayText;
  final Offset overlayOffset;
  final double overlayFontSize;
  final Color overlayColor;
  final FontWeight overlayFontWeight;

  const AxisPreviewPainter({
    required this.geometryKind,
    required this.layers,
    this.showAxes = true,
    this.overlayText,
    this.overlayOffset = Offset.zero,
    this.overlayFontSize = 13,
    this.overlayColor = const Color(0xFF111827),
    this.overlayFontWeight = FontWeight.w600,
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

    final visibleLayers =
    layers.where((e) => e.enabled).toList(growable: false);

    if (visibleLayers.isNotEmpty) {
      final scale = _computeFitScale(size, visibleLayers);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      canvas.translate(-center.dx, -center.dy);

      // O preview deve respeitar exatamente a ordem recebida,
      // pois a lista e o mapa já estão corretos no fluxo atual.
      for (final layer in visibleLayers) {
        _drawLayer(canvas, size, center, layer);
      }

      canvas.restore();
    }

    _drawOverlay(canvas, center);
  }

  void _drawOverlay(Canvas canvas, Offset center) {
    final text = overlayText?.trim() ?? '';
    if (text.isEmpty) return;

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: overlayFontSize,
          color: overlayColor,
          fontWeight: overlayFontWeight,
        ),
      ),
    )..layout();

    final anchor = center + overlayOffset;

    final offset = Offset(
      anchor.dx - (painter.width / 2),
      anchor.dy - (painter.height / 2),
    );

    painter.paint(canvas, offset);
  }

  double _computeFitScale(Size size, List<LayerDataSimple> visibleLayers) {
    final hasPointLikePreview = visibleLayers.any(_usesPointLikePreview);

    if (hasPointLikePreview &&
        (geometryKind == LayerGeometryKind.line ||
            geometryKind == LayerGeometryKind.polygon)) {
      return _computePointFitScale(size, visibleLayers);
    }

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

  bool _usesPointLikePreview(LayerDataSimple layer) {
    if (layer.type == LayerSimpleSymbolType.textLayer) return true;
    if (layer.type == LayerSimpleSymbolType.svgMarker) return true;
    if (layer.type == LayerSimpleSymbolType.simpleMarker &&
        layer.family == LayerSymbolFamily.point) {
      return true;
    }
    return false;
  }

  double _computePointFitScale(
      Size size,
      List<LayerDataSimple> visibleLayers,
      ) {
    double maxW = 0;
    double maxH = 0;

    for (final layer in visibleLayers) {
      if (layer.type == LayerSimpleSymbolType.textLayer) {
        maxW = math.max(maxW, 80);
        maxH = math.max(maxH, layer.textFontSize + 16);
      } else if (_usesPointLikePreview(layer)) {
        maxW = math.max(maxW, math.max(layer.width, layer.height));
        maxH = math.max(maxH, math.max(layer.width, layer.height));
      } else if (layer.family == LayerSymbolFamily.line) {
        maxW = math.max(maxW, 120);
        maxH = math.max(maxH, layer.strokeWidth + 12);
      } else if (layer.family == LayerSymbolFamily.polygon) {
        maxW = math.max(maxW, _basePolygonWidth);
        maxH = math.max(maxH, _basePolygonHeight);
      }
    }

    maxW += _outerPadding * 2;
    maxH += _outerPadding * 2;

    final scaleX = size.width / math.max(1, maxW);
    final scaleY = size.height / math.max(1, maxH);
    return math.min(1.0, math.min(scaleX, scaleY));
  }

  double _computeLineFitScale(
      Size size,
      List<LayerDataSimple> visibleLayers,
      ) {
    const baseHalf = _baseLineHalf;

    double minX = -baseHalf;
    double maxX = baseHalf;
    double minY = 0;
    double maxY = 0;

    for (final layer in visibleLayers) {
      if (layer.type == LayerSimpleSymbolType.textLayer) {
        final textHalfW = 40.0;
        final textHalfH = (layer.textFontSize + 8) / 2;

        minY = math.min(minY, layer.textOffsetY - textHalfH);
        maxY = math.max(maxY, layer.textOffsetY + textHalfH);
        minX = math.min(minX, layer.textOffsetX - textHalfW);
        maxX = math.max(maxX, layer.textOffsetX + textHalfW);
        continue;
      }

      if (_usesPointLikePreview(layer)) {
        final halfW = layer.width / 2;
        final halfH = layer.height / 2;
        minX = math.min(minX, -halfW);
        maxX = math.max(maxX, halfW);
        minY = math.min(minY, -halfH);
        maxY = math.max(maxY, halfH);
        continue;
      }

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

  double _computePolygonFitScale(
      Size size,
      List<LayerDataSimple> visibleLayers,
      ) {
    const baseW = _basePolygonWidth;
    const baseH = _basePolygonHeight;

    double extraStroke = 0;
    double extraText = 0;
    double extraPointLike = 0;

    for (final layer in visibleLayers) {
      if (layer.type == LayerSimpleSymbolType.textLayer) {
        extraText = math.max(extraText, layer.textFontSize + 24);
      } else if (_usesPointLikePreview(layer)) {
        extraPointLike =
            math.max(extraPointLike, math.max(layer.width, layer.height));
      } else {
        extraStroke = math.max(extraStroke, layer.strokeWidth);
      }
    }

    final width =
        baseW + extraStroke + extraText + extraPointLike + (_outerPadding * 2);
    final height =
        baseH + extraStroke + extraText + extraPointLike + (_outerPadding * 2);

    final scaleX = size.width / math.max(1, width);
    final scaleY = size.height / math.max(1, height);

    return math.min(1.0, math.min(scaleX, scaleY));
  }

  void _drawLayer(
      Canvas canvas,
      Size size,
      Offset center,
      LayerDataSimple layer,
      ) {
    if (layer.type == LayerSimpleSymbolType.textLayer) {
      _drawTextPreview(canvas, center, layer);
      return;
    }

    if (_usesPointLikePreview(layer)) {
      _drawPointPreview(canvas, center, layer);
      return;
    }

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

  void _drawTextPreview(
      Canvas canvas,
      Offset center,
      LayerDataSimple layer,
      ) {
    final text = layer.text.trim().isEmpty ? 'Texto' : layer.text;

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: layer.textFontSize,
          color: Color(layer.textColorValue),
          fontWeight: layer.textFontWeight,
        ),
      ),
    )..layout();

    final anchor = Offset(
      center.dx + layer.textOffsetX,
      center.dy + layer.textOffsetY,
    );

    final offset = Offset(
      anchor.dx - (painter.width / 2),
      anchor.dy - (painter.height / 2),
    );

    painter.paint(canvas, offset);
  }

  void _drawPointPreview(
      Canvas canvas,
      Offset center,
      LayerDataSimple layer,
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
      LayerDataSimple layer,
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
      LayerDataSimple layer,
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
    if (oldDelegate.overlayText != overlayText) return true;
    if (oldDelegate.overlayOffset != overlayOffset) return true;
    if (oldDelegate.overlayFontSize != overlayFontSize) return true;
    if (oldDelegate.overlayColor != overlayColor) return true;
    if (oldDelegate.overlayFontWeight != overlayFontWeight) return true;
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
          a.text != b.text ||
          a.textFontSize != b.textFontSize ||
          a.textColorValue != b.textColorValue ||
          a.textFontWeight != b.textFontWeight ||
          a.textOffsetX != b.textOffsetX ||
          a.textOffsetY != b.textOffsetY ||
          !listEquals(a.dashArray, b.dashArray)) {
        return true;
      }
    }

    return false;
  }
}