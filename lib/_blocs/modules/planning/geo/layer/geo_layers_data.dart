import 'package:flutter/material.dart';

enum LayerGeometryKind { point, line, polygon, mixed, unknown }

enum LayerRendererType {
  singleSymbol,
  ruleBased,
}

enum LayerSimpleSymbolType {
  svgMarker,
  simpleMarker,
}

enum LayerSimpleMarkerShapeType {
  square,
  trapezoid,
  parallelogram,
  diamond,
  pentagon,
  hexagon,
  octagon,
  decagon,
  roundedSquare,
  triangle,
  star4,
  star5,
  heart,
  arrow,
  circle,
  plus,
  cross,
  line,
  arc,
  semicircle,
  quarterCircle,
  rectangle,
  rightTriangle,
}

enum LayerRuleOperator {
  equals,
  notEquals,
  contains,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  isEmpty,
  isNotEmpty,
}

enum LayerSymbolFamily {
  point,
  line,
  polygon,
}

enum LayerStrokePattern {
  solid,
  dashed,
  dotted,
}

enum LayerStrokeJoinType {
  miter,
  bevel,
  round,
}

enum LayerStrokeCapType {
  butt,
  square,
  round,
}

extension LayerGeometryKindX on LayerGeometryKind {
  bool get isPointFamily => this == LayerGeometryKind.point;
  bool get isLineFamily => this == LayerGeometryKind.line;
  bool get isPolygonFamily => this == LayerGeometryKind.polygon;

  LayerSymbolFamily get symbolFamily {
    switch (this) {
      case LayerGeometryKind.point:
        return LayerSymbolFamily.point;
      case LayerGeometryKind.line:
        return LayerSymbolFamily.line;
      case LayerGeometryKind.polygon:
        return LayerSymbolFamily.polygon;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return LayerSymbolFamily.point;
    }
  }
}

class LayerSimpleSymbolData {
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

  const LayerSimpleSymbolData({
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

  LayerSimpleSymbolData copyWith({
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
    return LayerSimpleSymbolData(
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

  factory LayerSimpleSymbolData.fromMap(Map<String, dynamic> map) {
    final rawDashArray = (map['dashArray'] as List?) ?? const [];

    return LayerSimpleSymbolData(
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

  static LayerSimpleSymbolData defaultForGeometryKind(
      LayerGeometryKind kind, {
        required String id,
        required String iconKey,
        required int colorValue,
      }) {
    switch (kind) {
      case LayerGeometryKind.point:
        return LayerSimpleSymbolData(
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
        return LayerSimpleSymbolData(
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
        return LayerSimpleSymbolData(
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
        return LayerSimpleSymbolData(
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

class LayerRuleData {
  final String id;
  final String label;
  final bool enabled;
  final String field;
  final LayerRuleOperator operatorType;
  final String value;
  final double? minZoom;
  final double? maxZoom;
  final List<LayerSimpleSymbolData> symbolLayers;

  const LayerRuleData({
    required this.id,
    required this.label,
    this.enabled = true,
    this.field = '',
    this.operatorType = LayerRuleOperator.equals,
    this.value = '',
    this.minZoom,
    this.maxZoom,
    this.symbolLayers = const [],
  });

  List<LayerSimpleSymbolData> effectiveSymbolLayers({
    required LayerGeometryKind geometryKind,
    required String fallbackIconKey,
    required int fallbackColorValue,
  }) {
    if (symbolLayers.isNotEmpty) return symbolLayers;

    return [
      LayerSimpleSymbolData.defaultForGeometryKind(
        geometryKind,
        id: 'rule_symbol_$id',
        iconKey: fallbackIconKey,
        colorValue: fallbackColorValue,
      ),
    ];
  }

  LayerRuleData copyWith({
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
    List<LayerSimpleSymbolData>? symbolLayers,
  }) {
    return LayerRuleData(
      id: id ?? this.id,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      field: field ?? this.field,
      operatorType: operatorType ?? this.operatorType,
      value: value ?? this.value,
      minZoom: clearMinZoom ? null : (minZoom ?? this.minZoom),
      maxZoom: clearMaxZoom ? null : (maxZoom ?? this.maxZoom),
      symbolLayers: symbolLayers ?? this.symbolLayers,
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
      'symbolLayers': symbolLayers.map((e) => e.toMap()).toList(),
    };
  }

  factory LayerRuleData.fromMap(Map<String, dynamic> map) {
    final rawSymbols = (map['symbolLayers'] as List?) ?? const [];

    return LayerRuleData(
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
      symbolLayers: rawSymbols
          .whereType<Map>()
          .map((e) => LayerSimpleSymbolData.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}

class GeoLayersData {
  final String id;
  final String title;
  final String iconKey;
  final int colorValue;
  final bool defaultVisible;
  final bool isGroup;
  final List<GeoLayersData> children;
  final String? collectionPath;
  final LayerGeometryKind geometryKind;
  final bool supportsConnect;
  final bool isTemporary;
  final bool isSystem;
  final LayerRendererType rendererType;
  final List<LayerSimpleSymbolData> symbolLayers;
  final List<LayerRuleData> ruleBasedSymbols;

  const GeoLayersData({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    this.defaultVisible = false,
    this.isGroup = false,
    this.children = const [],
    this.collectionPath,
    this.geometryKind = LayerGeometryKind.unknown,
    this.supportsConnect = true,
    this.isTemporary = false,
    this.isSystem = false,
    this.rendererType = LayerRendererType.singleSymbol,
    this.symbolLayers = const [],
    this.ruleBasedSymbols = const [],
  });

  Color get color => Color(colorValue);

  String? get effectiveCollectionPath {
    final raw = collectionPath?.trim() ?? '';
    if (raw.isNotEmpty) return raw;

    if (isGroup || !supportsConnect) return null;
    return 'geo/catalog/layers/$id/features';
  }

  List<LayerSimpleSymbolData> get effectiveSymbolLayers {
    if (symbolLayers.isNotEmpty) return symbolLayers;

    return [
      LayerSimpleSymbolData.defaultForGeometryKind(
        geometryKind,
        id: 'symbol_default_$id',
        iconKey: iconKey,
        colorValue: colorValue,
      ),
    ];
  }

  LayerSimpleSymbolData? get topVisibleSymbol {
    if (rendererType == LayerRendererType.ruleBased) {
      for (final rule in ruleBasedSymbols) {
        if (!rule.enabled) continue;

        final source = rule.effectiveSymbolLayers(
          geometryKind: geometryKind,
          fallbackIconKey: iconKey,
          fallbackColorValue: colorValue,
        );
        final visible = source.where((e) => e.enabled);
        if (visible.isNotEmpty) return visible.first;
        if (source.isNotEmpty) return source.first;
      }
    }

    final source = effectiveSymbolLayers;
    final visible = source.where((e) => e.enabled);
    if (visible.isNotEmpty) return visible.first;
    return source.isNotEmpty ? source.first : null;
  }

  Color get displayColor {
    final symbol = topVisibleSymbol;
    if (symbol == null) return color;

    switch (geometryKind) {
      case LayerGeometryKind.line:
        return symbol.strokeColor;
      case LayerGeometryKind.polygon:
        return symbol.fillColor;
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return symbol.fillColor;
    }
  }

  String get displayIconKey {
    final symbol = topVisibleSymbol;
    if (symbol == null) return iconKey;
    if (symbol.family == LayerSymbolFamily.point &&
        symbol.type == LayerSimpleSymbolType.svgMarker) {
      return symbol.iconKey;
    }
    return iconKey;
  }

  GeoLayersData copyWith({
    String? id,
    String? title,
    String? iconKey,
    int? colorValue,
    bool? defaultVisible,
    bool? isGroup,
    List<GeoLayersData>? children,
    String? collectionPath,
    bool clearCollectionPath = false,
    LayerGeometryKind? geometryKind,
    bool? supportsConnect,
    bool? isTemporary,
    bool? isSystem,
    LayerRendererType? rendererType,
    List<LayerSimpleSymbolData>? symbolLayers,
    List<LayerRuleData>? ruleBasedSymbols,
  }) {
    return GeoLayersData(
      id: id ?? this.id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      defaultVisible: defaultVisible ?? this.defaultVisible,
      isGroup: isGroup ?? this.isGroup,
      children: children ?? this.children,
      collectionPath:
      clearCollectionPath ? null : (collectionPath ?? this.collectionPath),
      geometryKind: geometryKind ?? this.geometryKind,
      supportsConnect: supportsConnect ?? this.supportsConnect,
      isTemporary: isTemporary ?? this.isTemporary,
      isSystem: isSystem ?? this.isSystem,
      rendererType: rendererType ?? this.rendererType,
      symbolLayers: symbolLayers ?? this.symbolLayers,
      ruleBasedSymbols: ruleBasedSymbols ?? this.ruleBasedSymbols,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'defaultVisible': defaultVisible,
      'isGroup': isGroup,
      'children': children.map((e) => e.toMap()).toList(),
      'collectionPath': collectionPath,
      'geometryKind': geometryKind.name,
      'supportsConnect': supportsConnect,
      'isTemporary': isTemporary,
      'isSystem': isSystem,
      'rendererType': rendererType.name,
      'symbolLayers': symbolLayers.map((e) => e.toMap()).toList(),
      'ruleBasedSymbols': ruleBasedSymbols.map((e) => e.toMap()).toList(),
    };
  }

  factory GeoLayersData.fromMap(Map<String, dynamic> map) {
    final rawChildren = (map['children'] as List?) ?? const [];
    final rawSymbolLayers = (map['symbolLayers'] as List?) ?? const [];
    final rawRuleBasedSymbols = (map['ruleBasedSymbols'] as List?) ?? const [];

    return GeoLayersData(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      iconKey: (map['iconKey'] ?? 'layers_outlined').toString(),
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF4B5563,
      defaultVisible: map['defaultVisible'] == true,
      isGroup: map['isGroup'] == true,
      children: rawChildren
          .whereType<Map>()
          .map((e) => GeoLayersData.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      collectionPath: map['collectionPath']?.toString(),
      geometryKind: LayerGeometryKind.values.firstWhere(
            (e) => e.name == map['geometryKind'],
        orElse: () => LayerGeometryKind.unknown,
      ),
      supportsConnect: map['supportsConnect'] != false,
      isTemporary: map['isTemporary'] == true,
      isSystem: map['isSystem'] == true,
      rendererType: LayerRendererType.values.firstWhere(
            (e) => e.name == map['rendererType'],
        orElse: () => LayerRendererType.singleSymbol,
      ),
      symbolLayers: rawSymbolLayers
          .whereType<Map>()
          .map((e) => LayerSimpleSymbolData.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      ruleBasedSymbols: rawRuleBasedSymbols
          .whereType<Map>()
          .map((e) => LayerRuleData.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  static String defaultIconKeyForGeometry(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return 'location_on_outlined';
      case LayerGeometryKind.line:
        return 'timeline';
      case LayerGeometryKind.polygon:
        return 'hexagon_outlined';
      case LayerGeometryKind.mixed:
        return 'folder_open_outlined';
      case LayerGeometryKind.unknown:
        return 'layers_outlined';
    }
  }

  static GeoLayersData temporaryLayer({
    required String id,
    required int sequence,
  }) {
    return GeoLayersData(
      id: id,
      title: 'NOVA CAMADA $sequence',
      iconKey: defaultIconKeyForGeometry(LayerGeometryKind.unknown),
      colorValue: 0xFF2563EB,
      defaultVisible: false,
      isGroup: false,
      children: const [],
      collectionPath: 'geo/catalog/layers/$id/features',
      geometryKind: LayerGeometryKind.unknown,
      supportsConnect: true,
      isTemporary: true,
      isSystem: false,
      rendererType: LayerRendererType.singleSymbol,
      symbolLayers: [
        LayerSimpleSymbolData.defaultForGeometryKind(
          LayerGeometryKind.unknown,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.unknown),
          colorValue: 0xFF2563EB,
        ),
      ],
      ruleBasedSymbols: const [],
    );
  }

  static GeoLayersData temporaryPointLayer({
    required String id,
    required int sequence,
    int colorValue = 0xFF2563EB,
  }) {
    return GeoLayersData(
      id: id,
      title: 'CAMADA DE PONTOS $sequence',
      iconKey: defaultIconKeyForGeometry(LayerGeometryKind.point),
      colorValue: colorValue,
      defaultVisible: true,
      isGroup: false,
      children: const [],
      collectionPath: 'geo/catalog/layers/$id/features',
      geometryKind: LayerGeometryKind.point,
      supportsConnect: false,
      isTemporary: true,
      isSystem: false,
      rendererType: LayerRendererType.singleSymbol,
      symbolLayers: [
        LayerSimpleSymbolData.defaultForGeometryKind(
          LayerGeometryKind.point,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.point),
          colorValue: colorValue,
        ),
      ],
      ruleBasedSymbols: const [],
    );
  }

  static GeoLayersData temporaryLineLayer({
    required String id,
    required int sequence,
    int colorValue = 0xFF2563EB,
  }) {
    return GeoLayersData(
      id: id,
      title: 'CAMADA DE LINHAS $sequence',
      iconKey: defaultIconKeyForGeometry(LayerGeometryKind.line),
      colorValue: colorValue,
      defaultVisible: true,
      isGroup: false,
      children: const [],
      collectionPath: 'geo/catalog/layers/$id/features',
      geometryKind: LayerGeometryKind.line,
      supportsConnect: false,
      isTemporary: true,
      isSystem: false,
      rendererType: LayerRendererType.singleSymbol,
      symbolLayers: [
        LayerSimpleSymbolData.defaultForGeometryKind(
          LayerGeometryKind.line,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.line),
          colorValue: colorValue,
        ),
      ],
      ruleBasedSymbols: const [],
    );
  }

  static GeoLayersData temporaryPolygonLayer({
    required String id,
    required int sequence,
    int colorValue = 0xFF2563EB,
  }) {
    return GeoLayersData(
      id: id,
      title: 'CAMADA DE POLÍGONOS $sequence',
      iconKey: defaultIconKeyForGeometry(LayerGeometryKind.polygon),
      colorValue: colorValue,
      defaultVisible: true,
      isGroup: false,
      children: const [],
      collectionPath: 'geo/catalog/layers/$id/features',
      geometryKind: LayerGeometryKind.polygon,
      supportsConnect: false,
      isTemporary: true,
      isSystem: false,
      rendererType: LayerRendererType.singleSymbol,
      symbolLayers: [
        LayerSimpleSymbolData.defaultForGeometryKind(
          LayerGeometryKind.polygon,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.polygon),
          colorValue: colorValue,
        ),
      ],
      ruleBasedSymbols: const [],
    );
  }

  static GeoLayersData temporaryGroup({
    required String id,
    required int sequence,
    List<GeoLayersData> children = const [],
  }) {
    return GeoLayersData(
      id: id,
      title: 'NOVO GRUPO $sequence',
      iconKey: 'folder_open_outlined',
      colorValue: 0xFF374151,
      defaultVisible: false,
      isGroup: true,
      children: children,
      collectionPath: null,
      geometryKind: LayerGeometryKind.mixed,
      supportsConnect: false,
      isTemporary: false,
      isSystem: false,
      rendererType: LayerRendererType.singleSymbol,
      symbolLayers: const [],
      ruleBasedSymbols: const [],
    );
  }

  static List<GeoLayersData> bootstrapTree() {
    return const [];
  }
}