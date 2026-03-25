
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';

class GeoLayersDataRule {
  final String id;
  final String label;
  final bool enabled;
  final String field;
  final LayerRuleOperator operatorType;
  final String value;
  final double? minZoom;
  final double? maxZoom;
  final List<GeoLayersDataSimple> symbolLayers;

  const GeoLayersDataRule({
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

  List<GeoLayersDataSimple> effectiveSymbolLayers({
    required LayerGeometryKind geometryKind,
    required String fallbackIconKey,
    required int fallbackColorValue,
  }) {
    if (symbolLayers.isNotEmpty) return symbolLayers;

    return [
      GeoLayersDataSimple.defaultForGeometryKind(
        geometryKind,
        id: 'rule_symbol_$id',
        iconKey: fallbackIconKey,
        colorValue: fallbackColorValue,
      ),
    ];
  }

  GeoLayersDataRule copyWith({
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
    List<GeoLayersDataSimple>? symbolLayers,
  }) {
    return GeoLayersDataRule(
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

  factory GeoLayersDataRule.fromMap(Map<String, dynamic> map) {
    final rawSymbols = (map['symbolLayers'] as List?) ?? const [];

    return GeoLayersDataRule(
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
          .map((e) => GeoLayersDataSimple.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }
}