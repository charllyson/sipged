import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/rules/layer_rule_editor.dart';
import 'package:sipged/_widgets/geo/properties/menu/share/rules/layer_rule_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/symbology_single.dart';

class SymbologyRuleDetails extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final GeoLayersDataRule rule;
  final List<String> availableFields;
  final ValueChanged<GeoLayersDataRule> onChanged;

  const SymbologyRuleDetails({
    super.key,
    required this.geometryKind,
    required this.rule,
    required this.availableFields,
    required this.onChanged,
  });

  LayerRuleData get _baseValue {
    return LayerRuleData(
      label: rule.label,
      enabled: rule.enabled,
      field: rule.field,
      operatorType: rule.operatorType,
      value: rule.value,
      minZoom: rule.minZoom,
      maxZoom: rule.maxZoom,
    );
  }

  void _handleBaseChanged(LayerRuleData value) {
    onChanged(
      rule.copyWith(
        label: value.label,
        enabled: value.enabled,
        field: value.field,
        operatorType: value.operatorType,
        value: value.value,
        minZoom: value.minZoom,
        clearMinZoom: value.minZoom == null,
        maxZoom: value.maxZoom,
        clearMaxZoom: value.maxZoom == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayerRuleEditor(
      value: _baseValue,
      availableFields: availableFields,
      onChanged: _handleBaseChanged,
      child: SymbologySingle(
        geometryKind: geometryKind,
        symbolLayers: rule.symbolLayers,
        onChanged: (layers) {
          onChanged(rule.copyWith(symbolLayers: layers));
        },
      ),
    );
  }
}