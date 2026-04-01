import 'package:flutter/foundation.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';

class LayerDataRule {
  final String id;
  final String label;
  final bool enabled;
  final String field;
  final LayerRuleOperator operatorType;
  final String value;
  final double? minZoom;
  final double? maxZoom;
  final List<LayerDataSimple> symbolLayers;

  const LayerDataRule({
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

  List<LayerDataSimple> effectiveSymbolLayers({
    required LayerGeometryKind geometryKind,
    required String fallbackIconKey,
    required int fallbackColorValue,
  }) {
    if (symbolLayers.isNotEmpty) return symbolLayers;

    return [
      LayerDataSimple.defaultForGeometryKind(
        geometryKind,
        id: 'rule_symbol_$id',
        iconKey: fallbackIconKey,
        colorValue: fallbackColorValue,
      ),
    ];
  }

  LayerDataRule copyWith({
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
    List<LayerDataSimple>? symbolLayers,
  }) {
    return LayerDataRule(
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
      'table': field,
      'operatorType': operatorType.name,
      'value': value,
      'minZoom': minZoom,
      'maxZoom': maxZoom,
      'symbolLayers': symbolLayers.map((e) => e.toMap()).toList(),
    };
  }

  factory LayerDataRule.fromMap(Map<String, dynamic> map) {
    final rawSymbols = (map['symbolLayers'] as List?) ?? const [];

    return LayerDataRule(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      enabled: map['enabled'] != false,
      field: (map['field'] ?? map['table'] ?? '').toString(),
      operatorType: LayerRuleOperator.values.firstWhere(
            (e) => e.name == map['operatorType'],
        orElse: () => LayerRuleOperator.equals,
      ),
      value: (map['value'] ?? '').toString(),
      minZoom: (map['minZoom'] as num?)?.toDouble(),
      maxZoom: (map['maxZoom'] as num?)?.toDouble(),
      symbolLayers: rawSymbols
          .whereType<Map>()
          .map((e) => LayerDataSimple.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LayerDataRule &&
        other.id == id &&
        other.label == label &&
        other.enabled == enabled &&
        other.field == field &&
        other.operatorType == operatorType &&
        other.value == value &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        listEquals(other.symbolLayers, symbolLayers);
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
    Object.hashAll(symbolLayers),
  );
}