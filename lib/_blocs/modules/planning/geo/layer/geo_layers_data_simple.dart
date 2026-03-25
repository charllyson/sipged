
import 'package:flutter/cupertino.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class GeoLayersDataSimple {
  final String id;
  final LayerSymbolFamily family;

  // point
  final LayerSimpleSymbolType type;
  final String iconKey;
  final LayerSimpleMarkerShapeType shapeType;
  final double width;
  final double height;
  final bool keepAspectRatio;

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

  // NOVOS CAMPOS
  final bool useCustomDashPattern;
  final double dashWidth;
  final double dashGap;
  final LayerStrokeJoinType strokeJoin;
  final LayerStrokeCapType strokeCap;

  const GeoLayersDataSimple({
    required this.id,
    this.family = LayerSymbolFamily.point,
    this.type = LayerSimpleSymbolType.svgMarker,
    this.iconKey = 'location_on_outlined',
    this.shapeType = LayerSimpleMarkerShapeType.circle,
    this.width = 28,
    this.height = 28,
    this.keepAspectRatio = true,
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

  GeoLayersDataSimple copyWith({
    String? id,
    LayerSymbolFamily? family,
    LayerSimpleSymbolType? type,
    String? iconKey,
    LayerSimpleMarkerShapeType? shapeType,
    double? width,
    double? height,
    bool? keepAspectRatio,
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
    return GeoLayersDataSimple(
      id: id ?? this.id,
      family: family ?? this.family,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      shapeType: shapeType ?? this.shapeType,
      width: width ?? this.width,
      height: height ?? this.height,
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
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

  factory GeoLayersDataSimple.fromMap(Map<String, dynamic> map) {
    final rawDashArray = (map['dashArray'] as List?) ?? const [];

    return GeoLayersDataSimple(
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
      shapeType: LayerSimpleMarkerShapeType.values.firstWhere(
            (e) => e.name == map['shapeType'],
        orElse: () => LayerSimpleMarkerShapeType.circle,
      ),
      width: (map['width'] as num?)?.toDouble() ?? 28,
      height: (map['height'] as num?)?.toDouble() ?? 28,
      keepAspectRatio: map['keepAspectRatio'] != false,
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
          .where((e) => e is num)
          .map((e) => (e as num).toDouble())
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

  static GeoLayersDataSimple defaultForGeometryKind(
      LayerGeometryKind kind, {
        required String id,
        required String iconKey,
        required int colorValue,
      }) {
    switch (kind) {
      case LayerGeometryKind.point:
        return GeoLayersDataSimple(
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
        return GeoLayersDataSimple(
          id: id,
          family: LayerSymbolFamily.line,
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
        return GeoLayersDataSimple(
          id: id,
          family: LayerSymbolFamily.polygon,
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
        return GeoLayersDataSimple(
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
}
