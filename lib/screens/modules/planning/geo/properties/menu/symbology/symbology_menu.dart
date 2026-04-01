import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/layer_exhibition/layer_exhibition.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/symbology/symbology_rule.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/symbology/symbology_single.dart';

class SymbologyMenu extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final LayerRendererType rendererType;
  final List<LayerDataSimple> symbolLayers;
  final List<LayerDataRule> ruleBasedSymbols;
  final List<String> availableRuleFields;

  final ValueChanged<LayerRendererType> onRendererTypeChanged;
  final ValueChanged<List<LayerDataSimple>> onSymbolLayersChanged;
  final ValueChanged<List<LayerDataRule>> onRuleBasedSymbolsChanged;

  const SymbologyMenu({
    super.key,
    required this.geometryKind,
    required this.rendererType,
    required this.symbolLayers,
    required this.ruleBasedSymbols,
    required this.availableRuleFields,
    required this.onRendererTypeChanged,
    required this.onSymbolLayersChanged,
    required this.onRuleBasedSymbolsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isRuleMode = rendererType == LayerRendererType.ruleBased;

    return LayerExhibition(
      modeLabelText: 'Tipo de exibição',
      singleLabel: 'Exibição simples',
      ruleLabel: 'Exibição baseada em regra',
      isRuleMode: isRuleMode,
      onModeChanged: (isRule) {
        onRendererTypeChanged(
          isRule
              ? LayerRendererType.ruleBased
              : LayerRendererType.singleSymbol,
        );
      },
      singleChild: SymbologySingle(
        geometryKind: geometryKind,
        symbolLayers: symbolLayers,
        onChanged: onSymbolLayersChanged,
      ),
      ruleChild: SymbologyRule(
        geometryKind: geometryKind,
        rules: ruleBasedSymbols,
        availableFields: availableRuleFields,
        onChanged: onRuleBasedSymbolsChanged,
      ),
    );
  }
}