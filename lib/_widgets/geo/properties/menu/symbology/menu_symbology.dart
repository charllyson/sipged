import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/rules/rule_symbology.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/single/single_symbology.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class MenuSymbology extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final LayerRendererType rendererType;
  final List<GeoLayersDataSimple> symbolLayers;
  final List<GeoLayersDataRule> ruleBasedSymbols;
  final List<String> availableRuleFields;

  final ValueChanged<LayerRendererType> onRendererTypeChanged;
  final ValueChanged<List<GeoLayersDataSimple>> onSymbolLayersChanged;
  final ValueChanged<List<GeoLayersDataRule>> onRuleBasedSymbolsChanged;

  const MenuSymbology({
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
  State<MenuSymbology> createState() => _MenuSymbologyState();
}

class _MenuSymbologyState extends State<MenuSymbology> {
  static const String _singleLabel = 'Símbolo simples';
  static const String _ruleLabel = 'Símbolo baseado em regra';

  late final TextEditingController _rendererCtrl;

  @override
  void initState() {
    super.initState();
    _rendererCtrl = TextEditingController(
      text: _labelFromRenderer(widget.rendererType),
    );
  }

  @override
  void didUpdateWidget(covariant MenuSymbology oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rendererType != widget.rendererType) {
      _rendererCtrl.text = _labelFromRenderer(widget.rendererType);
    }
  }

  @override
  void dispose() {
    _rendererCtrl.dispose();
    super.dispose();
  }

  String _labelFromRenderer(LayerRendererType type) {
    switch (type) {
      case LayerRendererType.ruleBased:
        return _ruleLabel;
      case LayerRendererType.singleSymbol:
        return _singleLabel;
    }
  }

  LayerRendererType _rendererFromLabel(String? value) {
    switch (value) {
      case _ruleLabel:
        return LayerRendererType.ruleBased;
      case _singleLabel:
      default:
        return LayerRendererType.singleSymbol;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.rendererType == LayerRendererType.singleSymbol;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropDownButtonChange(
                controller: _rendererCtrl,
                labelText: 'Tipo de renderização',
                width: double.infinity,
                items: const [_singleLabel, _ruleLabel],
                onChanged: (value) {
                  final next = _rendererFromLabel(value);
                  if (next == widget.rendererType) return;
                  widget.onRendererTypeChanged(next);
                },
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSingle
                    ? SingleSymbology(
                  key: const ValueKey('single'),
                  geometryKind: widget.geometryKind,
                  symbolLayers: widget.symbolLayers,
                  onChanged: widget.onSymbolLayersChanged,
                )
                    : RuleSymbology(
                  key: const ValueKey('rule'),
                  geometryKind: widget.geometryKind,
                  rules: widget.ruleBasedSymbols,
                  availableFields: widget.availableRuleFields,
                  onChanged: widget.onRuleBasedSymbolsChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}