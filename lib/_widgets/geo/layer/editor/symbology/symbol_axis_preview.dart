import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/icons_catalog.dart';
import 'package:sipged/_widgets/geo/layer/simple_shape_painter.dart';

class SymbolAxisPreview extends StatelessWidget {
  final List<LayerSimpleSymbolData> layers;

  const SymbolAxisPreview({
    super.key,
    required this.layers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: _AxisPreviewPainter(layers: layers),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AxisPreviewPainter extends CustomPainter {
  final List<LayerSimpleSymbolData> layers;

  _AxisPreviewPainter({
    required this.layers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final axisPaint = Paint()
      ..color = const Color(0xFF707070)
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

    final visibleLayers =
    layers.where((e) => e.enabled).toList(growable: false);

    /// importante:
    /// a camada do topo da lista precisa ser desenhada por último
    /// para ficar visualmente por cima das anteriores
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
            fontSize: layer.height,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Color(layer.fillColorValue),
          ),
        ),
      )..layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(layer.rotationDegrees * 3.141592653589793 / 180);
      canvas.translate(-center.dx, -center.dy);

      final iconOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, iconOffset);
      canvas.restore();
      return;
    }

    final painter = SimpleShapePainter(
      shape: layer.shapeType,
      fillColor: Color(layer.fillColorValue),
      strokeColor: Color(layer.strokeColorValue),
      strokeWidth: layer.strokeWidth,
      rotationDegrees: layer.rotationDegrees,
    );

    canvas.save();
    canvas.translate(
      center.dx - (layer.width / 2),
      center.dy - (layer.height / 2),
    );
    painter.paint(canvas, Size(layer.width, layer.height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AxisPreviewPainter oldDelegate) {
    return oldDelegate.layers != layers;
  }
}