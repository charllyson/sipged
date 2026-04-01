import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_catalog.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/list_layer/layer_mini_preview_painter.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/list_layer/layer_mini_preview_polygon.dart';

class MiniLayerPreview extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final LayerDataSimple? symbol;
  final LayerDataLabel? label;

  final double width;
  final double height;
  final bool showContainerBackground;

  const MiniLayerPreview.symbol({
    super.key,
    required this.geometryKind,
    required LayerDataSimple this.symbol,
    this.width = 24,
    this.height = 24,
    this.showContainerBackground = false,
  }) : label = null;

  const MiniLayerPreview.label({
    super.key,
    required this.geometryKind,
    required LayerDataLabel this.label,
    this.width = 34,
    this.height = 24,
    this.showContainerBackground = false,
  }) : symbol = null;

  bool get _isLabelMode => label != null;

  LayerSimpleSymbolType get _type =>
      _isLabelMode ? label!.type : symbol!.type;

  LayerSymbolFamily get _effectiveFamily {
    if (_isLabelMode) {
      if (_type == LayerSimpleSymbolType.textLayer) {
        return LayerSymbolFamily.point;
      }
      return LayerSymbolFamily.point;
    }

    return symbol!.family;
  }

  double get _rotationDegrees =>
      _isLabelMode ? label!.rotationDegrees : symbol!.rotationDegrees;

  int get _fillColorValue =>
      _isLabelMode ? label!.fillColorValue : symbol!.fillColorValue;

  int get _strokeColorValue =>
      _isLabelMode ? label!.strokeColorValue : symbol!.strokeColorValue;

  double get _strokeWidth =>
      _isLabelMode ? label!.strokeWidth : symbol!.strokeWidth;

  String get _iconKey => _isLabelMode ? label!.iconKey : symbol!.iconKey;

  LayerShapeType get _shapeType =>
      _isLabelMode ? label!.shapeType : symbol!.shapeType;

  double get _itemWidth => _isLabelMode ? label!.width : symbol!.width;

  double get _itemHeight => _isLabelMode ? label!.height : symbol!.height;

  String get _text => _isLabelMode ? label!.text : symbol!.text;

  double get _textFontSize =>
      _isLabelMode ? label!.fontSize : symbol!.textFontSize;

  FontWeight get _textFontWeight =>
      _isLabelMode ? label!.fontWeight : symbol!.textFontWeight;

  int get _textColorValue =>
      _isLabelMode ? label!.colorValue : symbol!.textColorValue;

  LayerStrokePattern get _strokePattern =>
      _isLabelMode ? LayerStrokePattern.solid : symbol!.strokePattern;

  List<double> get _effectiveDashArray =>
      _isLabelMode ? const [] : symbol!.effectiveDashArray;

  StrokeJoin get _uiStrokeJoin =>
      _isLabelMode ? StrokeJoin.miter : symbol!.uiStrokeJoin;

  StrokeCap get _uiStrokeCap =>
      _isLabelMode ? StrokeCap.butt : symbol!.uiStrokeCap;

  bool get _usesPointLikePreview {
    if (_type == LayerSimpleSymbolType.textLayer) return true;
    if (_type == LayerSimpleSymbolType.svgMarker) return true;

    if (_type == LayerSimpleSymbolType.simpleMarker) {
      return _effectiveFamily == LayerSymbolFamily.point;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final visual = _buildVisual();

    if (!showContainerBackground) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(child: visual),
      );
    }

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: visual,
    );
  }

  Widget _buildVisual() {
    if (_type == LayerSimpleSymbolType.textLayer) {
      return _buildTextPreview();
    }

    if (_usesPointLikePreview) {
      return _buildPointLikePreview();
    }

    if (_effectiveFamily == LayerSymbolFamily.line) {
      final previewSize = Size(
        math.min(width, 24),
        math.min(height, 24),
      );

      return SizedBox(
        width: previewSize.width,
        height: previewSize.height,
        child: Center(
          child: RepaintBoundary(
            child: CustomPaint(
              size: previewSize,
              painter: LayerMiniPreviewPainter(
                strokeColorValue: _strokeColorValue,
                strokeWidth: _strokeWidth,
                rotationDegrees: _rotationDegrees,
                strokePattern: _strokePattern,
                dashArray: _effectiveDashArray,
                strokeCap: _uiStrokeCap,
                strokeJoin: _uiStrokeJoin,
              ),
            ),
          ),
        ),
      );
    }

    if (_effectiveFamily == LayerSymbolFamily.polygon) {
      return SizedBox(
        width: math.min(width, 24),
        height: math.min(height, 24),
        child: Center(
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(18, 18),
              painter: LayerMiniPreviewPolygon(
                fillColorValue: _fillColorValue,
                strokeColorValue: _strokeColorValue,
                strokeWidth: _strokeWidth,
                strokePattern: _strokePattern,
                dashArray: _effectiveDashArray,
                strokeCap: _uiStrokeCap,
                strokeJoin: _uiStrokeJoin,
              ),
            ),
          ),
        ),
      );
    }

    return _buildPointLikePreview();
  }

  Widget _buildPointLikePreview() {
    if (_type == LayerSimpleSymbolType.svgMarker) {
      final previewWidth = _itemWidth.clamp(10.0, 20.0);
      final previewHeight = _itemHeight.clamp(10.0, 20.0);

      return Transform.rotate(
        angle: _rotationDegrees * math.pi / 180,
        child: Icon(
          IconsCatalog.iconFor(_iconKey),
          size: math.max(previewWidth, previewHeight),
          color: Color(_fillColorValue),
        ),
      );
    }

    final previewWidth = _itemWidth.clamp(10.0, 20.0);
    final previewHeight = _itemHeight.clamp(10.0, 20.0);

    return Transform.rotate(
      angle: _rotationDegrees * math.pi / 180,
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: ShapePainter(
              shape: _shapeType,
              fillColor: Color(_fillColorValue),
              strokeColor: Color(_strokeColorValue),
              strokeWidth: _strokeWidth.clamp(0.6, 1.5),
              rotationDegrees: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    final raw = _text.trim();
    final previewText = _resolvePreviewText(raw);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        previewText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(_textColorValue),
          fontSize: _isLabelMode
              ? _textFontSize.clamp(9.0, 14.0)
              : _textFontSize.clamp(10.0, 16.0),
          fontWeight: _textFontWeight,
          height: 1.0,
        ),
      ),
    );
  }

  String _resolvePreviewText(String raw) {
    if (raw.isEmpty) {
      return _isLabelMode ? 'Rótulo' : 'T';
    }

    if (!_isLabelMode) {
      return raw.length == 1 ? raw.toUpperCase() : raw[0].toUpperCase();
    }

    final cleaned = raw
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('_', ' ')
        .trim();

    if (cleaned.isEmpty) return 'Rótulo';
    if (cleaned.length <= 10) return cleaned;
    return cleaned.substring(0, 10);
  }
}