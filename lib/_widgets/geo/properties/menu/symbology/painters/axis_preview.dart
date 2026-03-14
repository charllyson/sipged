import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/geometry/shape_painter.dart';

class AxisPreview extends StatelessWidget {
  final List<LayerSimpleSymbolData> layers;

  const AxisPreview({
    super.key,
    required this.layers,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          painter: _AxisPreviewPainter(
            layers: List<LayerSimpleSymbolData>.from(layers),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AxisPreviewPainter extends CustomPainter {
  final List<LayerSimpleSymbolData> layers;

  const _AxisPreviewPainter({
    required this.layers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    final axisPaint = Paint()
      ..color = const Color(0xFF8B8B8B)
      ..strokeWidth = 1;

    // eixo vertical
    canvas.drawLine(
      Offset(center.dx, 12),
      Offset(center.dx, size.height - 12),
      axisPaint,
    );

    // eixo horizontal
    canvas.drawLine(
      Offset(12, center.dy),
      Offset(size.width - 12, center.dy),
      axisPaint,
    );

    final visibleLayers = layers.where((e) => e.enabled).toList(growable: false);

    for (final layer in visibleLayers.reversed) {
      _drawLayer(canvas, center, layer);
    }
  }

  void _drawLayer(Canvas canvas, Offset center, LayerSimpleSymbolData layer) {
    if (layer.type == LayerSimpleSymbolType.svgMarker) {
      final iconData = IconsCatalog.iconFor(layer.iconKey);

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: layer.height <= 0 ? 24 : layer.height,
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

    final width = layer.width <= 0 ? 24.0 : layer.width;
    final height = layer.height <= 0 ? 24.0 : layer.height;

    final painter = ShapePainter(
      shape: layer.shapeType,
      fillColor: Color(layer.fillColorValue),
      strokeColor: Color(layer.strokeColorValue),
      strokeWidth: layer.strokeWidth,
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

  @override
  bool shouldRepaint(covariant _AxisPreviewPainter oldDelegate) {
    if (oldDelegate.layers.length != layers.length) return true;

    for (int i = 0; i < layers.length; i++) {
      final a = oldDelegate.layers[i];
      final b = layers[i];

      if (a.id != b.id ||
          a.enabled != b.enabled ||
          a.type != b.type ||
          a.iconKey != b.iconKey ||
          a.shapeType != b.shapeType ||
          a.width != b.width ||
          a.height != b.height ||
          a.fillColorValue != b.fillColorValue ||
          a.strokeColorValue != b.strokeColorValue ||
          a.strokeWidth != b.strokeWidth ||
          a.rotationDegrees != b.rotationDegrees) {
        return true;
      }
    }

    return false;
  }
}