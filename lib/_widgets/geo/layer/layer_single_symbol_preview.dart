import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

class DrawerSingleSymbolPreview extends StatelessWidget {
  final LayerSimpleSymbolData symbol;
  final bool isSelected;
  final bool isActive;

  const DrawerSingleSymbolPreview({
    super.key,
    required this.symbol,
    required this.isSelected,
    required this.isActive,
  });

  static const double _degToRad = math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    final previewWidth = symbol.width.clamp(8.0, 22.0).toDouble();
    final previewHeight = symbol.height.clamp(8.0, 22.0).toDouble();
    final rotation = symbol.rotationDegrees * _degToRad;

    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
      return Transform.rotate(
        angle: rotation,
        child: Icon(
          IconsCatalog.iconFor(symbol.iconKey),
          size: math.max(previewWidth, previewHeight),
          color: symbol.fillColor,
        ),
      );
    }

    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: ShapePainter(
              shape: symbol.shapeType,
              fillColor: symbol.fillColor,
              strokeColor: symbol.strokeColor,
              strokeWidth: symbol.strokeWidth.clamp(0.6, 1.5).toDouble(),
              rotationDegrees: 0,
            ),
          ),
        ),
      ),
    );
  }
}