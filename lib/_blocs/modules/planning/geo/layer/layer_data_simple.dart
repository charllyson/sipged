import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_catalog.dart';

class LayerDataSimple {
  final String id;
  final LayerSymbolFamily family;

  // point / visual kind
  final LayerSimpleSymbolType type;

  // svg
  final String iconKey;

  // simple geometry
  final LayerShapeType shapeType;
  final double width;
  final double height;
  final bool keepAspectRatio;

  // text
  final String title;
  final String text;
  final double textFontSize;
  final int textColorValue;
  final FontWeight textFontWeight;
  final double textOffsetX;
  final double textOffsetY;

  // generic / line / polygon
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final double rotationDegrees;
  final bool enabled;

  // line / polygon border
  final LayerStrokePattern strokePattern;
  final List<double> dashArray;
  final double offset;

  // extras
  final bool useCustomDashPattern;
  final double dashWidth;
  final double dashGap;
  final LayerStrokeJoinType strokeJoin;
  final LayerStrokeCapType strokeCap;

  const LayerDataSimple({
    required this.id,
    this.family = LayerSymbolFamily.point,
    this.type = LayerSimpleSymbolType.svgMarker,
    this.iconKey = 'location_on_outlined',
    this.shapeType = LayerShapeType.circle,
    this.width = 28,
    this.height = 28,
    this.keepAspectRatio = true,
    this.title = '',
    this.text = 'Texto',
    this.textFontSize = 13,
    this.textColorValue = 0xFF111827,
    this.textFontWeight = FontWeight.w600,
    this.textOffsetX = 0,
    this.textOffsetY = 0,
    this.fillColorValue = 0xFF2563EB,
    this.strokeColorValue = 0xFF1F2937,
    this.strokeWidth = 1.2,
    this.rotationDegrees = 0,
    this.enabled = true,
    this.strokePattern = LayerStrokePattern.solid,
    this.dashArray = const [],
    this.offset = 0,
    this.useCustomDashPattern = false,
    this.dashWidth = 10,
    this.dashGap = 6,
    this.strokeJoin = LayerStrokeJoinType.miter,
    this.strokeCap = LayerStrokeCapType.butt,
  });

  Color get fillColor => Color(fillColorValue);
  Color get strokeColor => Color(strokeColorValue);
  Color get textColor => Color(textColorValue);

  List<double> get effectiveDashArray {
    if (strokePattern == LayerStrokePattern.solid) {
      return const [];
    }

    if (useCustomDashPattern) {
      final dash = dashWidth <= 0 ? 1.0 : dashWidth;
      final gap = dashGap <= 0 ? 1.0 : dashGap;
      return [dash, gap];
    }

    if (dashArray.isNotEmpty) {
      return dashArray;
    }

    switch (strokePattern) {
      case LayerStrokePattern.dashed:
        return const [12, 8];
      case LayerStrokePattern.dotted:
        return const [2, 6];
      case LayerStrokePattern.solid:
        return const [];
    }
  }

  StrokeJoin get uiStrokeJoin {
    switch (strokeJoin) {
      case LayerStrokeJoinType.bevel:
        return StrokeJoin.bevel;
      case LayerStrokeJoinType.round:
        return StrokeJoin.round;
      case LayerStrokeJoinType.miter:
        return StrokeJoin.miter;
    }
  }

  StrokeCap get uiStrokeCap {
    switch (strokeCap) {
      case LayerStrokeCapType.square:
        return StrokeCap.square;
      case LayerStrokeCapType.round:
        return StrokeCap.round;
      case LayerStrokeCapType.butt:
        return StrokeCap.butt;
    }
  }

  LayerDataSimple copyWith({
    String? id,
    LayerSymbolFamily? family,
    LayerSimpleSymbolType? type,
    String? iconKey,
    LayerShapeType? shapeType,
    double? width,
    double? height,
    bool? keepAspectRatio,
    String? title,
    String? text,
    double? textFontSize,
    int? textColorValue,
    FontWeight? textFontWeight,
    double? textOffsetX,
    double? textOffsetY,
    int? fillColorValue,
    int? strokeColorValue,
    double? strokeWidth,
    double? rotationDegrees,
    bool? enabled,
    LayerStrokePattern? strokePattern,
    List<double>? dashArray,
    double? offset,
    bool? useCustomDashPattern,
    double? dashWidth,
    double? dashGap,
    LayerStrokeJoinType? strokeJoin,
    LayerStrokeCapType? strokeCap,
  }) {
    return LayerDataSimple(
      id: id ?? this.id,
      family: family ?? this.family,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      shapeType: shapeType ?? this.shapeType,
      width: width ?? this.width,
      height: height ?? this.height,
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
      title: title ?? this.title,
      text: text ?? this.text,
      textFontSize: textFontSize ?? this.textFontSize,
      textColorValue: textColorValue ?? this.textColorValue,
      textFontWeight: textFontWeight ?? this.textFontWeight,
      textOffsetX: textOffsetX ?? this.textOffsetX,
      textOffsetY: textOffsetY ?? this.textOffsetY,
      fillColorValue: fillColorValue ?? this.fillColorValue,
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      enabled: enabled ?? this.enabled,
      strokePattern: strokePattern ?? this.strokePattern,
      dashArray: dashArray ?? this.dashArray,
      offset: offset ?? this.offset,
      useCustomDashPattern:
      useCustomDashPattern ?? this.useCustomDashPattern,
      dashWidth: dashWidth ?? this.dashWidth,
      dashGap: dashGap ?? this.dashGap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      strokeCap: strokeCap ?? this.strokeCap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family': family.name,
      'type': type.name,
      'iconKey': iconKey,
      'shapeType': shapeType.name,
      'width': width,
      'height': height,
      'keepAspectRatio': keepAspectRatio,
      'title': title,
      'text': text,
      'textFontSize': textFontSize,
      'textColorValue': textColorValue,
      'textFontWeight': _fontWeightToIndex(textFontWeight),
      'textOffsetX': textOffsetX,
      'textOffsetY': textOffsetY,
      'fillColorValue': fillColorValue,
      'strokeColorValue': strokeColorValue,
      'strokeWidth': strokeWidth,
      'rotationDegrees': rotationDegrees,
      'enabled': enabled,
      'strokePattern': strokePattern.name,
      'dashArray': dashArray,
      'offset': offset,
      'useCustomDashPattern': useCustomDashPattern,
      'dashWidth': dashWidth,
      'dashGap': dashGap,
      'strokeJoin': strokeJoin.name,
      'strokeCap': strokeCap.name,
    };
  }

  factory LayerDataSimple.fromMap(Map<String, dynamic> map) {
    final rawDashArray = (map['dashArray'] as List?) ?? const [];

    return LayerDataSimple(
      id: (map['id'] ?? '').toString(),
      family: LayerSymbolFamily.values.firstWhere(
            (e) => e.name == map['family'],
        orElse: () => LayerSymbolFamily.point,
      ),
      type: LayerSimpleSymbolType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => LayerSimpleSymbolType.svgMarker,
      ),
      iconKey: (map['iconKey'] ?? 'location_on_outlined').toString(),
      shapeType: LayerShapeType.values.firstWhere(
            (e) => e.name == map['shapeType'],
        orElse: () => LayerShapeType.circle,
      ),
      width: (map['width'] as num?)?.toDouble() ?? 28,
      height: (map['height'] as num?)?.toDouble() ?? 28,
      keepAspectRatio: map['keepAspectRatio'] != false,
      title: (map['title'] ?? '').toString(),
      text: (map['text'] ?? 'Texto').toString(),
      textFontSize: (map['textFontSize'] as num?)?.toDouble() ?? 13,
      textColorValue: (map['textColorValue'] as num?)?.toInt() ?? 0xFF111827,
      textFontWeight:
      _fontWeightFromIndex((map['textFontWeight'] as num?)?.toInt()),
      textOffsetX: (map['textOffsetX'] as num?)?.toDouble() ?? 0,
      textOffsetY: (map['textOffsetY'] as num?)?.toDouble() ?? 0,
      fillColorValue: (map['fillColorValue'] as num?)?.toInt() ?? 0xFF2563EB,
      strokeColorValue:
      (map['strokeColorValue'] as num?)?.toInt() ?? 0xFF1F2937,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 1.2,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toDouble() ?? 0,
      enabled: map['enabled'] != false,
      strokePattern: LayerStrokePattern.values.firstWhere(
            (e) => e.name == map['strokePattern'],
        orElse: () => LayerStrokePattern.solid,
      ),
      dashArray: rawDashArray
          .whereType<num>()
          .map((e) => e.toDouble())
          .toList(growable: false),
      offset: (map['offset'] as num?)?.toDouble() ?? 0,
      useCustomDashPattern: map['useCustomDashPattern'] == true,
      dashWidth: (map['dashWidth'] as num?)?.toDouble() ?? 10,
      dashGap: (map['dashGap'] as num?)?.toDouble() ?? 6,
      strokeJoin: LayerStrokeJoinType.values.firstWhere(
            (e) => e.name == map['strokeJoin'],
        orElse: () => LayerStrokeJoinType.miter,
      ),
      strokeCap: LayerStrokeCapType.values.firstWhere(
            (e) => e.name == map['strokeCap'],
        orElse: () => LayerStrokeCapType.butt,
      ),
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

  static LayerDataSimple defaultForGeometryKind(
      LayerGeometryKind kind, {
        required String id,
        required String iconKey,
        required int colorValue,
      }) {
    switch (kind) {
      case LayerGeometryKind.point:
        return LayerDataSimple(
          id: id,
          family: LayerSymbolFamily.point,
          type: LayerSimpleSymbolType.svgMarker,
          iconKey: iconKey,
          fillColorValue: colorValue,
          strokeColorValue: 0xFF1F2937,
          width: 28,
          height: 28,
        );

      case LayerGeometryKind.line:
        return LayerDataSimple(
          id: id,
          family: LayerSymbolFamily.line,
          type: LayerSimpleSymbolType.simpleMarker,
          fillColorValue: 0x00000000,
          strokeColorValue: colorValue,
          strokeWidth: 3,
          width: 28,
          height: 8,
          strokePattern: LayerStrokePattern.solid,
          useCustomDashPattern: false,
          dashWidth: 10,
          dashGap: 6,
          strokeJoin: LayerStrokeJoinType.miter,
          strokeCap: LayerStrokeCapType.butt,
        );

      case LayerGeometryKind.polygon:
        return LayerDataSimple(
          id: id,
          family: LayerSymbolFamily.polygon,
          type: LayerSimpleSymbolType.simpleMarker,
          fillColorValue: colorValue,
          strokeColorValue: 0xFF1F2937,
          strokeWidth: 1.4,
          width: 28,
          height: 28,
          strokePattern: LayerStrokePattern.solid,
          useCustomDashPattern: false,
          dashWidth: 10,
          dashGap: 6,
          strokeJoin: LayerStrokeJoinType.miter,
          strokeCap: LayerStrokeCapType.butt,
        );

      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return LayerDataSimple(
          id: id,
          family: LayerSymbolFamily.point,
          type: LayerSimpleSymbolType.svgMarker,
          iconKey: iconKey,
          fillColorValue: colorValue,
          strokeColorValue: 0xFF1F2937,
          width: 28,
          height: 28,
        );
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LayerDataSimple &&
        other.id == id &&
        other.family == family &&
        other.type == type &&
        other.iconKey == iconKey &&
        other.shapeType == shapeType &&
        other.width == width &&
        other.height == height &&
        other.keepAspectRatio == keepAspectRatio &&
        other.title == title &&
        other.text == text &&
        other.textFontSize == textFontSize &&
        other.textColorValue == textColorValue &&
        other.textFontWeight == textFontWeight &&
        other.textOffsetX == textOffsetX &&
        other.textOffsetY == textOffsetY &&
        other.fillColorValue == fillColorValue &&
        other.strokeColorValue == strokeColorValue &&
        other.strokeWidth == strokeWidth &&
        other.rotationDegrees == rotationDegrees &&
        other.enabled == enabled &&
        other.strokePattern == strokePattern &&
        listEquals(other.dashArray, dashArray) &&
        other.offset == offset &&
        other.useCustomDashPattern == useCustomDashPattern &&
        other.dashWidth == dashWidth &&
        other.dashGap == dashGap &&
        other.strokeJoin == strokeJoin &&
        other.strokeCap == strokeCap;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    family,
    type,
    iconKey,
    shapeType,
    width,
    height,
    keepAspectRatio,
    title,
    text,
    textFontSize,
    textColorValue,
    textFontWeight,
    textOffsetX,
    textOffsetY,
    fillColorValue,
    strokeColorValue,
    strokeWidth,
    rotationDegrees,
    enabled,
    strokePattern,
    Object.hashAll(dashArray),
    offset,
    useCustomDashPattern,
    dashWidth,
    dashGap,
    strokeJoin,
    strokeCap,
  ]);
}