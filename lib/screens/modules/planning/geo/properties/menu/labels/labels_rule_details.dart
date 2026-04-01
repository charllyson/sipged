import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/labels/label_form.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/preview/axis_preview.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_data.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_editor.dart';

class LabelsRuleDetails extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> symbolLayers;
  final GeoLabelRuleData rule;
  final List<String> availableFields;
  final ValueChanged<GeoLabelRuleData> onChanged;

  const LabelsRuleDetails({
    super.key,
    required this.geometryKind,
    required this.symbolLayers,
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

  LayerDataSimple _mapRuleStyleToPreviewLayer() {
    final style = rule.style;

    return LayerDataSimple(
      id: style.id,
      title: style.title,
      enabled: style.enabled,
      family: _familyFromGeometry(geometryKind),
      type: style.type,
      iconKey: style.iconKey,
      shapeType: style.shapeType,
      width: style.width,
      height: style.height,
      keepAspectRatio: style.keepAspectRatio,
      fillColorValue: style.fillColorValue,
      strokeColorValue: style.strokeColorValue,
      strokeWidth: style.strokeWidth,
      rotationDegrees: style.rotationDegrees,
      offset: style.geometryOffset,
      text: style.text.trim().isEmpty ? 'Rótulo' : '{${style.text}}',
      textFontSize: style.fontSize,
      textColorValue: style.colorValue,
      textFontWeight: style.fontWeight,
      textOffsetX: style.offsetX,
      textOffsetY: style.offsetY,

      // defaults para preview
      strokePattern: LayerStrokePattern.solid,
      dashArray: const [],
      useCustomDashPattern: false,
      dashWidth: 10,
      dashGap: 6,
      strokeJoin: LayerStrokeJoinType.miter,
      strokeCap: LayerStrokeCapType.butt,
    );
  }

  LayerSymbolFamily _familyFromGeometry(LayerGeometryKind geometryKind) {
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

  @override
  Widget build(BuildContext context) {
    return LayerRuleEditor(
      value: _baseValue,
      availableFields: availableFields,
      onChanged: _handleBaseChanged,
      preview: AxisPreview(
        geometryKind: geometryKind,
        layers: [_mapRuleStyleToPreviewLayer()],
      ),
      child: LabelsForm(
        geometryKind: geometryKind,
        label: rule.style,
        availableFields: availableFields,
        onChanged: (style) {
          onChanged(rule.copyWith(style: style));
        },
      ),
    );
  }
}