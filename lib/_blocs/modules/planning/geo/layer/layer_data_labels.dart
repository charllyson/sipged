import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_catalog.dart';

enum LabelRendererType {
  singleLabel,
  ruleBasedLabel,
}

@immutable
class LayerDataLabel {
  final String id;
  final String title;
  final String text;
  final bool enabled;

  // tipo visual
  final LayerSimpleSymbolType type;

  // texto
  final double fontSize;
  final int colorValue;
  final FontWeight fontWeight;
  final double offsetX;
  final double offsetY;

  // svg / geometria
  final String iconKey;
  final LayerShapeType shapeType;
  final double width;
  final double height;
  final bool keepAspectRatio;
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final double rotationDegrees;
  final double geometryOffset;

  const LayerDataLabel({
    required this.id,
    this.title = '',
    this.text = 'Rótulo',
    this.enabled = true,
    this.type = LayerSimpleSymbolType.textLayer,
    this.fontSize = 13,
    this.colorValue = 0xFF111827,
    this.fontWeight = FontWeight.w600,
    this.offsetX = 0,
    this.offsetY = -24,
    this.iconKey = 'location_on_outlined',
    this.shapeType = LayerShapeType.circle,
    this.width = 18,
    this.height = 18,
    this.keepAspectRatio = true,
    this.fillColorValue = 0xFF2563EB,
    this.strokeColorValue = 0xFF1F2937,
    this.strokeWidth = 1.2,
    this.rotationDegrees = 0,
    this.geometryOffset = 0,
  });

  Color get color => Color(colorValue);
  Color get fillColor => Color(fillColorValue);
  Color get strokeColor => Color(strokeColorValue);

  Offset get offset => Offset(offsetX, offsetY);

  LayerDataLabel copyWith({
    String? id,
    String? title,
    String? text,
    bool? enabled,
    LayerSimpleSymbolType? type,
    double? fontSize,
    int? colorValue,
    FontWeight? fontWeight,
    double? offsetX,
    double? offsetY,
    String? iconKey,
    LayerShapeType? shapeType,
    double? width,
    double? height,
    bool? keepAspectRatio,
    int? fillColorValue,
    int? strokeColorValue,
    double? strokeWidth,
    double? rotationDegrees,
    double? geometryOffset,
  }) {
    return LayerDataLabel(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      fontWeight: fontWeight ?? this.fontWeight,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      iconKey: iconKey ?? this.iconKey,
      shapeType: shapeType ?? this.shapeType,
      width: width ?? this.width,
      height: height ?? this.height,
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
      fillColorValue: fillColorValue ?? this.fillColorValue,
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      geometryOffset: geometryOffset ?? this.geometryOffset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'enabled': enabled,
      'type': type.name,
      'fontSize': fontSize,
      'colorValue': colorValue,
      'fontWeight': _fontWeightToIndex(fontWeight),
      'offsetX': offsetX,
      'offsetY': offsetY,
      'iconKey': iconKey,
      'shapeType': shapeType.name,
      'width': width,
      'height': height,
      'keepAspectRatio': keepAspectRatio,
      'fillColorValue': fillColorValue,
      'strokeColorValue': strokeColorValue,
      'strokeWidth': strokeWidth,
      'rotationDegrees': rotationDegrees,
      'geometryOffset': geometryOffset,
    };
  }

  factory LayerDataLabel.fromMap(Map<String, dynamic> map) {
    return LayerDataLabel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      text: (map['text'] ?? 'Rótulo').toString(),
      enabled: map['enabled'] != false,
      type: LayerSimpleSymbolType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => LayerSimpleSymbolType.textLayer,
      ),
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 13,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF111827,
      fontWeight: _fontWeightFromIndex((map['fontWeight'] as num?)?.toInt()),
      offsetX: (map['offsetX'] as num?)?.toDouble() ?? 0,
      offsetY: (map['offsetY'] as num?)?.toDouble() ?? -24,
      iconKey: (map['iconKey'] ?? 'location_on_outlined').toString(),
      shapeType: LayerShapeType.values.firstWhere(
            (e) => e.name == map['shapeType'],
        orElse: () => LayerShapeType.circle,
      ),
      width: (map['width'] as num?)?.toDouble() ?? 18,
      height: (map['height'] as num?)?.toDouble() ?? 18,
      keepAspectRatio: map['keepAspectRatio'] != false,
      fillColorValue: (map['fillColorValue'] as num?)?.toInt() ?? 0xFF2563EB,
      strokeColorValue:
      (map['strokeColorValue'] as num?)?.toInt() ?? 0xFF1F2937,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 1.2,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toDouble() ?? 0,
      geometryOffset: (map['geometryOffset'] as num?)?.toDouble() ?? 0,
    );
  }

  static int _fontWeightToIndex(FontWeight weight) {
    if (weight == FontWeight.w100) return 100;
    if (weight == FontWeight.w200) return 200;
    if (weight == FontWeight.w300) return 300;
    if (weight == FontWeight.w400) return 400;
    if (weight == FontWeight.w500) return 500;
    if (weight == FontWeight.w600) return 600;
    if (weight == FontWeight.w700) return 700;
    if (weight == FontWeight.w800) return 800;
    if (weight == FontWeight.w900) return 900;
    return 600;
  }

  static FontWeight _fontWeightFromIndex(int? value) {
    switch (value) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w600;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LayerDataLabel &&
        other.id == id &&
        other.title == title &&
        other.text == text &&
        other.enabled == enabled &&
        other.type == type &&
        other.fontSize == fontSize &&
        other.colorValue == colorValue &&
        other.fontWeight == fontWeight &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.iconKey == iconKey &&
        other.shapeType == shapeType &&
        other.width == width &&
        other.height == height &&
        other.keepAspectRatio == keepAspectRatio &&
        other.fillColorValue == fillColorValue &&
        other.strokeColorValue == strokeColorValue &&
        other.strokeWidth == strokeWidth &&
        other.rotationDegrees == rotationDegrees &&
        other.geometryOffset == geometryOffset;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    text,
    enabled,
    type,
    fontSize,
    colorValue,
    fontWeight,
    offsetX,
    offsetY,
    iconKey,
    shapeType,
    width,
    height,
    keepAspectRatio,
    fillColorValue,
    strokeColorValue,
    strokeWidth,
    rotationDegrees,
    geometryOffset,
  );
}

@immutable
class GeoLabelRuleData {
  final String id;
  final String label;
  final bool enabled;

  final String field;
  final LayerRuleOperator operatorType;
  final String value;

  final double? minZoom;
  final double? maxZoom;

  final LayerDataLabel style;

  const GeoLabelRuleData({
    required this.id,
    this.label = '',
    this.enabled = true,
    this.field = '',
    this.operatorType = LayerRuleOperator.equals,
    this.value = '',
    this.minZoom,
    this.maxZoom,
    required this.style,
  });

  GeoLabelRuleData copyWith({
    String? id,
    String? label,
    bool? enabled,
    String? field,
    LayerRuleOperator? operatorType,
    String? value,
    double? minZoom,
    bool clearMinZoom = false,
    double? maxZoom,
    bool clearMaxZoom = false,
    LayerDataLabel? style,
  }) {
    return GeoLabelRuleData(
      id: id ?? this.id,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      field: field ?? this.field,
      operatorType: operatorType ?? this.operatorType,
      value: value ?? this.value,
      minZoom: clearMinZoom ? null : (minZoom ?? this.minZoom),
      maxZoom: clearMaxZoom ? null : (maxZoom ?? this.maxZoom),
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'enabled': enabled,
      'field': field,
      'operatorType': operatorType.name,
      'value': value,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'style': style.toMap(),
    };
  }

  factory GeoLabelRuleData.fromMap(Map<String, dynamic> map) {
    return GeoLabelRuleData(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      enabled: map['enabled'] != false,
      field: (map['field'] ?? '').toString(),
      operatorType: LayerRuleOperator.values.firstWhere(
            (e) => e.name == map['operatorType'],
        orElse: () => LayerRuleOperator.equals,
      ),
      value: (map['value'] ?? '').toString(),
      minZoom: (map['minZoom'] as num?)?.toDouble(),
      maxZoom: (map['maxZoom'] as num?)?.toDouble(),
      style: LayerDataLabel.fromMap(
        Map<String, dynamic>.from(
          (map['style'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GeoLabelRuleData &&
        other.id == id &&
        other.label == label &&
        other.enabled == enabled &&
        other.field == field &&
        other.operatorType == operatorType &&
        other.value == value &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    enabled,
    field,
    operatorType,
    value,
    minZoom,
    maxZoom,
    style,
  );
}