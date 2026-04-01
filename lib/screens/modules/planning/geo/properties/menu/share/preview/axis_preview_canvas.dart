import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/preview/axis_preview_painter.dart';

class AxisPreviewCanvas extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> layers;
  final Color backgroundColor;
  final EdgeInsets padding;
  final bool showAxes;
  final BorderRadius borderRadius;

  final String? overlayText;
  final Offset overlayOffset;
  final double overlayFontSize;
  final Color overlayColor;
  final FontWeight overlayFontWeight;

  const AxisPreviewCanvas({
    super.key,
    required this.geometryKind,
    required this.layers,
    this.backgroundColor = Colors.transparent,
    this.padding = EdgeInsets.zero,
    this.showAxes = true,
    this.borderRadius = BorderRadius.zero,
    this.overlayText,
    this.overlayOffset = Offset.zero,
    this.overlayFontSize = 13,
    this.overlayColor = const Color(0xFF111827),
    this.overlayFontWeight = FontWeight.w600,
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
              layers: List<LayerDataSimple>.unmodifiable(layers),
              showAxes: showAxes,
              overlayText: overlayText,
              overlayOffset: overlayOffset,
              overlayFontSize: overlayFontSize,
              overlayColor: overlayColor,
              overlayFontWeight: overlayFontWeight,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}