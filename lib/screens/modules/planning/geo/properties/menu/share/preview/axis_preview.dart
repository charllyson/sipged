import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/preview/axis_preview_canvas.dart';

class AxisPreview extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> layers;

  final String? overlayText;
  final Offset overlayOffset;
  final double overlayFontSize;
  final Color overlayColor;
  final FontWeight overlayFontWeight;

  const AxisPreview({
    super.key,
    required this.geometryKind,
    required this.layers,
    this.overlayText,
    this.overlayOffset = Offset.zero,
    this.overlayFontSize = 13,
    this.overlayColor = const Color(0xFF111827),
    this.overlayFontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return AxisPreviewCanvas(
      geometryKind: geometryKind,
      layers: layers,
      overlayText: overlayText,
      overlayOffset: overlayOffset,
      overlayFontSize: overlayFontSize,
      overlayColor: overlayColor,
      overlayFontWeight: overlayFontWeight,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      showAxes: true,
      borderRadius: BorderRadius.circular(0),
    );
  }
}