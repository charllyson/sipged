import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';

class LayerRuleCore {
  const LayerRuleCore._();

  static String operatorLabel(LayerRuleOperator op) {
    switch (op) {
      case LayerRuleOperator.equals:
        return 'Igual a';
      case LayerRuleOperator.notEquals:
        return 'Diferente de';
      case LayerRuleOperator.contains:
        return 'Contém';
      case LayerRuleOperator.greaterThan:
        return 'Maior que';
      case LayerRuleOperator.lessThan:
        return 'Menor que';
      case LayerRuleOperator.greaterOrEqual:
        return 'Maior ou igual';
      case LayerRuleOperator.lessOrEqual:
        return 'Menor ou igual';
      case LayerRuleOperator.isEmpty:
        return 'Está vazio';
      case LayerRuleOperator.isNotEmpty:
        return 'Não está vazio';
    }
  }

  static LayerRuleOperator operatorFromLabel(String? value) {
    for (final op in LayerRuleOperator.values) {
      if (operatorLabel(op) == value) return op;
    }
    return LayerRuleOperator.equals;
  }

  static bool hidesValueField(LayerRuleOperator operatorType) {
    return operatorType == LayerRuleOperator.isEmpty ||
        operatorType == LayerRuleOperator.isNotEmpty;
  }

  static String ruleText({
    required String field,
    required LayerRuleOperator operatorType,
    required String value,
  }) {
    final normalizedField = field.trim();
    if (normalizedField.isEmpty) return '(sem filtro)';

    if (hidesValueField(operatorType)) {
      return '$normalizedField ${operatorLabel(operatorType)}';
    }

    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return '$normalizedField ${operatorLabel(operatorType)}';
    }

    return '$normalizedField ${operatorLabel(operatorType)} $normalizedValue';
  }

  static LayerSymbolFamily symbolFamilyFromGeometry(
      LayerGeometryKind geometryKind,
      ) {
    switch (geometryKind) {
      case LayerGeometryKind.line:
        return LayerSymbolFamily.line;
      case LayerGeometryKind.polygon:
        return LayerSymbolFamily.polygon;
      case LayerGeometryKind.point:
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return LayerSymbolFamily.point;
    }
  }

  static LayerDataSimple createDefaultSymbolLayer({
    required String id,
    required LayerGeometryKind geometryKind,
    String iconKey = 'location_on_outlined',
    int colorValue = 0xFF2563EB,
  }) {
    return LayerDataSimple.defaultForGeometryKind(
      geometryKind,
      id: id,
      iconKey: iconKey,
      colorValue: colorValue,
    );
  }

  static LayerDataLabel createDefaultLabelStyle({
    required String id,
    String title = '',
    String text = 'Rótulo',
  }) {
    return LayerDataLabel(
      id: id,
      title: title,
      text: text,
      enabled: true,
      type: LayerSimpleSymbolType.textLayer,
      fontSize: 13,
      colorValue: 0xFF111827,
      fontWeight: FontWeight.w600,
      offsetX: 0,
      offsetY: 0,
    );
  }
}