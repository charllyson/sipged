import 'package:flutter/material.dart';

enum LayerGeometryKind { point, line, polygon, mixed, unknown }

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
      strokeColorValue:
      (map['strokeColorValue'] as num?)?.toInt() ?? 0xFF1F2937,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 1.2,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toDouble() ?? 0,
      enabled: map['enabled'] != false,
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
  final List<LayerSimpleSymbolData> symbolLayers;

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
    this.symbolLayers = const [],
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
    final visible = effectiveSymbolLayers.where((e) => e.enabled);
    if (visible.isNotEmpty) return visible.first;
    return effectiveSymbolLayers.isNotEmpty ? effectiveSymbolLayers.first : null;
  }

  Color get displayColor {
    return topVisibleSymbol?.fillColor ?? color;
  }

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
    List<LayerSimpleSymbolData>? symbolLayers,
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
      symbolLayers: symbolLayers ?? this.symbolLayers,
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
      'symbolLayers': symbolLayers.map((e) => e.toMap()).toList(),
    };
  }

  factory GeoLayersData.fromMap(Map<String, dynamic> map) {
    final rawChildren = (map['children'] as List?) ?? const [];
    final rawSymbolLayers = (map['symbolLayers'] as List?) ?? const [];

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
      symbolLayers: rawSymbolLayers
          .whereType<Map>()
          .map(
            (e) => LayerSimpleSymbolData.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
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
      symbolLayers: const [],
    );
  }

  static List<GeoLayersData> bootstrapTree() {
    return const [];
  }
}