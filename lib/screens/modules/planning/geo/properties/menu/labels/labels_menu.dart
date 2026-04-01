import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/labels/labels_rule.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/labels/labels_single.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/layer_exhibition/layer_exhibition.dart';

class LabelsMenu extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> symbolLayers;

  final LabelRendererType rendererType;
  final List<LayerDataLabel> labelLayers;
  final List<GeoLabelRuleData> ruleBasedLabels;
  final List<String> availableRuleFields;

  final ValueChanged<LabelRendererType> onRendererTypeChanged;
  final ValueChanged<List<LayerDataLabel>> onLabelLayersChanged;
  final ValueChanged<List<GeoLabelRuleData>> onRuleBasedLabelsChanged;

  const LabelsMenu({
    super.key,
    required this.geometryKind,
    required this.symbolLayers,
    required this.rendererType,
    required this.labelLayers,
    required this.ruleBasedLabels,
    required this.availableRuleFields,
    required this.onRendererTypeChanged,
    required this.onLabelLayersChanged,
    required this.onRuleBasedLabelsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isRuleMode = rendererType == LabelRendererType.ruleBasedLabel;

    return LayerExhibition(
      modeLabelText: 'Tipo de exibição',
      singleLabel: 'Exibição simples',
      ruleLabel: 'Exibição baseada em regra',
      isRuleMode: isRuleMode,
      onModeChanged: (isRule) {
        onRendererTypeChanged(
          isRule
              ? LabelRendererType.ruleBasedLabel
              : LabelRendererType.singleLabel,
        );
      },
      singleChild: LabelsSingle(
        geometryKind: geometryKind,
        symbolLayers: symbolLayers,
        labelLayers: labelLayers,
        availableFields: availableRuleFields,
        onChanged: onLabelLayersChanged,
      ),
      ruleChild: LabelsRule(
        geometryKind: geometryKind,
        symbolLayers: symbolLayers,
        rules: ruleBasedLabels,
        availableFields: availableRuleFields,
        onChanged: onRuleBasedLabelsChanged,
      ),
    );
  }
}