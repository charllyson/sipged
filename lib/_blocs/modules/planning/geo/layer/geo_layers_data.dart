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

class LayerSimpleSymbolData {
  final String id;
  final LayerSimpleSymbolType type;
  final String iconKey;
  final LayerSimpleMarkerShapeType shapeType;
  final double width;
  final double height;
  final bool keepAspectRatio;
  final int fillColorValue;
  final int strokeColorValue;
  final double strokeWidth;
  final double rotationDegrees;
  final bool enabled;

  const LayerSimpleSymbolData({
    required this.id,
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
  });

  Color get fillColor => Color(fillColorValue);
  Color get strokeColor => Color(strokeColorValue);

  LayerSimpleSymbolData copyWith({
    String? id,
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
  }) {
    return LayerSimpleSymbolData(
      id: id ?? this.id,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    };
  }

  factory LayerSimpleSymbolData.fromMap(Map<String, dynamic> map) {
    return LayerSimpleSymbolData(
      id: (map['id'] ?? '').toString(),
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
      strokeColorValue: (map['strokeColorValue'] as num?)?.toInt() ?? 0xFF1F2937,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 1.2,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toDouble() ?? 0,
      enabled: map['enabled'] != false,
    );
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

  List<LayerSimpleSymbolData> get effectiveSymbolLayers {
    if (symbolLayers.isNotEmpty) return symbolLayers;
    return [
      LayerSimpleSymbolData(
        id: 'rule_symbol_$id',
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
      LayerSimpleSymbolData(
        id: 'symbol_default_$id',
        type: LayerSimpleSymbolType.svgMarker,
        iconKey: iconKey,
        fillColorValue: colorValue,
        strokeColorValue: 0xFF1F2937,
        width: 28,
        height: 28,
      ),
    ];
  }

  LayerSimpleSymbolData? get topVisibleSymbol {
    final source = rendererType == LayerRendererType.ruleBased &&
        ruleBasedSymbols.any((e) => e.enabled)
        ? ruleBasedSymbols.firstWhere((e) => e.enabled).effectiveSymbolLayers
        : effectiveSymbolLayers;

    final visible = source.where((e) => e.enabled);
    if (visible.isNotEmpty) return visible.first;
    return source.isNotEmpty ? source.first : null;
  }

  Color get displayColor => topVisibleSymbol?.fillColor ?? color;

  String get displayIconKey {
    final symbol = topVisibleSymbol;
    if (symbol == null) return iconKey;
    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
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
        LayerSimpleSymbolData(
          id: 'symbol_$id',
          type: LayerSimpleSymbolType.svgMarker,
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.unknown),
          fillColorValue: 0xFF2563EB,
          strokeColorValue: 0xFF1F2937,
          width: 28,
          height: 28,
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