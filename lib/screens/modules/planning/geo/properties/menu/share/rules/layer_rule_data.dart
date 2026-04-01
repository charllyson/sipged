import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

@immutable
class LayerRuleData {
  final String label;
  final bool enabled;
  final String field;
  final LayerRuleOperator operatorType;
  final String value;
  final double? minZoom;
  final double? maxZoom;

  const LayerRuleData({
    required this.label,
    required this.enabled,
    required this.field,
    required this.operatorType,
    required this.value,
    required this.minZoom,
    required this.maxZoom,
  });

  LayerRuleData copyWith({
    String? label,
    bool? enabled,
    String? field,
    LayerRuleOperator? operatorType,
    String? value,
    double? minZoom,
    bool clearMinZoom = false,
    double? maxZoom,
    bool clearMaxZoom = false,
  }) {
    return LayerRuleData(
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      field: field ?? this.field,
      operatorType: operatorType ?? this.operatorType,
      value: value ?? this.value,
      minZoom: clearMinZoom ? null : (minZoom ?? this.minZoom),
      maxZoom: clearMaxZoom ? null : (maxZoom ?? this.maxZoom),
    );
  }
}