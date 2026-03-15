import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/geometry/shape_painter.dart';

class DrawerSingleSymbolPreview extends StatelessWidget {
  final LayerSimpleSymbolData symbol;
  final bool isSelected;
  final bool isActive;

  const DrawerSingleSymbolPreview({super.key,
    required this.symbol,
    required this.isSelected,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = symbol.fillColor;
    final strokeColor = symbol.strokeColor;

    final previewWidth = symbol.width.clamp(8.0, 22.0).toDouble();
    final previewHeight = symbol.height.clamp(8.0, 22.0).toDouble();

    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
      return Transform.rotate(
        angle: symbol.rotationDegrees * 3.141592653589793 / 180,
        child: Icon(
          IconsCatalog.iconFor(symbol.iconKey),
          size: previewWidth > previewHeight ? previewWidth : previewHeight,
          color: fillColor,
        ),
      );
    }

    return Transform.rotate(
      angle: symbol.rotationDegrees * 3.141592653589793 / 180,
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: CustomPaint(
          painter: ShapePainter(
            shape: symbol.shapeType,
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: symbol.strokeWidth.clamp(0.6, 1.5).toDouble(),
            rotationDegrees: 0,
          ),
        ),
      ),
    );
  }
}
