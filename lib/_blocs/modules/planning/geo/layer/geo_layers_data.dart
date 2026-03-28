import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';

enum LayerGeometryKind { point, line, polygon, mixed, unknown }

enum LayerRendererType {
  singleSymbol,
  ruleBased,
}

enum LayerSimpleSymbolType {
  textLayer,
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

  // simbologia
  final LayerRendererType rendererType;
  final List<GeoLayersDataSimple> symbolLayers;
  final List<GeoLayersDataRule> ruleBasedSymbols;

  // rótulos
  final LabelRendererType labelRendererType;
  final List<GeoLabelStyleData> labelLayers;
  final List<GeoLabelRuleData> ruleBasedLabels;

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
    this.labelRendererType = LabelRendererType.singleLabel,
    this.labelLayers = const [],
    this.ruleBasedLabels = const [],
  });

  Color get color => Color(colorValue);

  String? get effectiveCollectionPath {
    final raw = collectionPath?.trim() ?? '';
    if (raw.isNotEmpty) return raw;

    if (isGroup || !supportsConnect) return null;
    return 'geo/catalog/layers/$id/features';
  }

  List<GeoLayersDataSimple> get effectiveSymbolLayers {
    if (symbolLayers.isNotEmpty) return symbolLayers;

    return [
      GeoLayersDataSimple.defaultForGeometryKind(
        geometryKind,
        id: 'symbol_default_$id',
        iconKey: iconKey,
        colorValue: colorValue,
      ),
    ];
  }

  List<GeoLabelStyleData> get effectiveLabelLayers {
    return labelLayers;
  }

  GeoLayersDataSimple? get topVisibleSymbol {
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
        return symbol.type == LayerSimpleSymbolType.textLayer
            ? symbol.textColor
            : symbol.fillColor;
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
    List<GeoLayersDataSimple>? symbolLayers,
    List<GeoLayersDataRule>? ruleBasedSymbols,
    LabelRendererType? labelRendererType,
    List<GeoLabelStyleData>? labelLayers,
    List<GeoLabelRuleData>? ruleBasedLabels,
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
      labelRendererType: labelRendererType ?? this.labelRendererType,
      labelLayers: labelLayers ?? this.labelLayers,
      ruleBasedLabels: ruleBasedLabels ?? this.ruleBasedLabels,
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
      'labelRendererType': labelRendererType.name,
      'labelLayers': labelLayers.map((e) => e.toMap()).toList(),
      'ruleBasedLabels': ruleBasedLabels.map((e) => e.toMap()).toList(),
    };
  }

  factory GeoLayersData.fromMap(Map<String, dynamic> map) {
    final rawChildren = (map['children'] as List?) ?? const [];
    final rawSymbolLayers = (map['symbolLayers'] as List?) ?? const [];
    final rawRuleBasedSymbols = (map['ruleBasedSymbols'] as List?) ?? const [];
    final rawLabelLayers = (map['labelLayers'] as List?) ?? const [];
    final rawRuleBasedLabels = (map['ruleBasedLabels'] as List?) ?? const [];

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
          .map((e) => GeoLayersDataSimple.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      ruleBasedSymbols: rawRuleBasedSymbols
          .whereType<Map>()
          .map((e) => GeoLayersDataRule.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      labelRendererType: LabelRendererType.values.firstWhere(
            (e) => e.name == map['labelRendererType'],
        orElse: () => LabelRendererType.singleLabel,
      ),
      labelLayers: rawLabelLayers
          .whereType<Map>()
          .map((e) => GeoLabelStyleData.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      ruleBasedLabels: rawRuleBasedLabels
          .whereType<Map>()
          .map((e) => GeoLabelRuleData.fromMap(Map<String, dynamic>.from(e)))
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
        GeoLayersDataSimple.defaultForGeometryKind(
          LayerGeometryKind.unknown,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.unknown),
          colorValue: 0xFF2563EB,
        ),
      ],
      ruleBasedSymbols: const [],
      labelRendererType: LabelRendererType.singleLabel,
      labelLayers: const [],
      ruleBasedLabels: const [],
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
        GeoLayersDataSimple.defaultForGeometryKind(
          LayerGeometryKind.point,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.point),
          colorValue: colorValue,
        ),
      ],
      ruleBasedSymbols: const [],
      labelRendererType: LabelRendererType.singleLabel,
      labelLayers: const [],
      ruleBasedLabels: const [],
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
        GeoLayersDataSimple.defaultForGeometryKind(
          LayerGeometryKind.line,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.line),
          colorValue: colorValue,
        ),
      ],
      ruleBasedSymbols: const [],
      labelRendererType: LabelRendererType.singleLabel,
      labelLayers: const [],
      ruleBasedLabels: const [],
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
        GeoLayersDataSimple.defaultForGeometryKind(
          LayerGeometryKind.polygon,
          id: 'symbol_$id',
          iconKey: defaultIconKeyForGeometry(LayerGeometryKind.polygon),
          colorValue: colorValue,
        ),
      ],
      ruleBasedSymbols: const [],
      labelRendererType: LabelRendererType.singleLabel,
      labelLayers: const [],
      ruleBasedLabels: const [],
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
      labelRendererType: LabelRendererType.singleLabel,
      labelLayers: const [],
      ruleBasedLabels: const [],
    );
  }

  static List<GeoLayersData> bootstrapTree() {
    return const [];
  }
}