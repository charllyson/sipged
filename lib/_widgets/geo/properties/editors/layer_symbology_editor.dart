import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/editors/markers/rule_based_symbology_editor.dart';
import 'package:sipged/_widgets/geo/properties/editors/markers/single_symbol_symbology_editor.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class LayerSymbologyEditor extends StatefulWidget {
  final LayerRendererType rendererType;
  final List<LayerSimpleSymbolData> symbolLayers;
  final List<LayerRuleData> ruleBasedSymbols;
  final List<String> availableRuleFields;

  final ValueChanged<LayerRendererType> onRendererTypeChanged;
  final ValueChanged<List<LayerSimpleSymbolData>> onSymbolLayersChanged;
  final ValueChanged<List<LayerRuleData>> onRuleBasedSymbolsChanged;

  const LayerSymbologyEditor({
    super.key,
    required this.rendererType,
    required this.symbolLayers,
    required this.ruleBasedSymbols,
    required this.availableRuleFields,
    required this.onRendererTypeChanged,
    required this.onSymbolLayersChanged,
    required this.onRuleBasedSymbolsChanged,
  });

  @override
  State<LayerSymbologyEditor> createState() => _LayerSymbologyEditorState();
}

class _LayerSymbologyEditorState extends State<LayerSymbologyEditor> {
  late final TextEditingController _rendererCtrl;

  static const String _singleLabel = 'Símbolo simples';
  static const String _ruleLabel = 'Símbolo baseado em regra';

  @override
  void initState() {
    super.initState();
    _rendererCtrl = TextEditingController(
      text: _labelFromRenderer(widget.rendererType),
    );
  }

  @override
  void didUpdateWidget(covariant LayerSymbologyEditor oldWidget) {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropDownButtonChange(
                controller: _rendererCtrl,
                labelText: 'Tipo de renderização',
                width: double.infinity,
                items: const [_singleLabel, _ruleLabel],
                onChanged: (value) {
                  widget.onRendererTypeChanged(_rendererFromLabel(value));
                },
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: widget.rendererType == LayerRendererType.singleSymbol
                    ? SingleSymbolSymbologyEditor(
                  key: const ValueKey('single'),
                  symbolLayers: widget.symbolLayers,
                  onChanged: widget.onSymbolLayersChanged,
                )
                    : RuleBasedSymbologyEditor(
                  key: const ValueKey('rule'),
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