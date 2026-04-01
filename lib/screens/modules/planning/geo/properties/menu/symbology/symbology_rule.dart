import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_core.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_list.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/symbology/symbology_rule_details.dart';

class SymbologyRule extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataRule> rules;
  final List<String> availableFields;
  final ValueChanged<List<LayerDataRule>> onChanged;

  const SymbologyRule({
    super.key,
    required this.geometryKind,
    required this.rules,
    required this.availableFields,
    required this.onChanged,
  });

  @override
  State<SymbologyRule> createState() => _SymbologyRuleState();
}

class _SymbologyRuleState extends State<SymbologyRule> {
  late List<LayerDataRule> _rules;
  int _selectedRuleIndex = 0;

  @override
  void initState() {
    super.initState();
    _rules = List<LayerDataRule>.from(widget.rules);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant SymbologyRule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.rules, widget.rules)) {
      _rules = List<LayerDataRule>.from(widget.rules);
      _normalizeSelection();
    }
  }

  void _normalizeSelection() {
    if (_rules.isEmpty) {
      _selectedRuleIndex = 0;
      return;
    }

    if (_selectedRuleIndex >= _rules.length) {
      _selectedRuleIndex = _rules.length - 1;
    }
  }

  void _notifyParent() {
    widget.onChanged(List<LayerDataRule>.unmodifiable(_rules));
  }

  LayerDataRule? get _selectedRule {
    if (_rules.isEmpty) return null;
    return _rules[_selectedRuleIndex];
  }

  void _addRule() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final defaultField =
    widget.availableFields.isNotEmpty ? widget.availableFields.first : '';

    _rules.add(
      LayerDataRule(
        id: 'rule_$now',
        label: 'Nova regra ${_rules.length + 1}',
        field: defaultField,
        symbolLayers: [
          LayerRuleCore.createDefaultSymbolLayer(
            id: 'symbol_$now',
            geometryKind: widget.geometryKind,
          ),
        ],
      ),
    );

    _selectedRuleIndex = _rules.length - 1;
    _notifyParent();
  }

  void _removeRule() {
    if (_rules.isEmpty) return;

    _rules.removeAt(_selectedRuleIndex);

    if (_selectedRuleIndex >= _rules.length) {
      _selectedRuleIndex = _rules.isEmpty ? 0 : _rules.length - 1;
    }

    _notifyParent();
  }

  void _duplicateRule() {
    final selected = _selectedRule;
    if (selected == null) return;

    final now = DateTime.now().microsecondsSinceEpoch;
    final family = LayerRuleCore.symbolFamilyFromGeometry(widget.geometryKind);

    final duplicated = selected.copyWith(
      id: 'rule_$now',
      label: '${selected.label} (cópia)',
      symbolLayers: selected.symbolLayers
          .map(
            (item) => item.copyWith(
          id: 'symbol_${DateTime.now().microsecondsSinceEpoch}_${item.id}',
          family: family,
        ),
      )
          .toList(growable: false),
    );

    _rules.insert(_selectedRuleIndex + 1, duplicated);
    _selectedRuleIndex++;
    _notifyParent();
  }

  void _updateSelectedRule(LayerDataRule value) {
    if (_selectedRule == null) return;
    _rules[_selectedRuleIndex] = value;
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayerRuleList<LayerDataRule>(
          items: _rules,
          selectedIndex: _selectedRuleIndex,
          onSelect: (index) {
            if (_selectedRuleIndex == index) return;
            setState(() => _selectedRuleIndex = index);
          },
          onAdd: _addRule,
          onRemove: _rules.isEmpty ? null : _removeRule,
          onDuplicate: _rules.isEmpty ? null : _duplicateRule,
          labelOf: (rule) => rule.label,
          enabledOf: (rule) => rule.enabled,
          fieldOf: (rule) => rule.field,
          operatorOf: (rule) => rule.operatorType,
          valueOf: (rule) => rule.value,
          minZoomOf: (rule) => rule.minZoom,
          maxZoomOf: (rule) => rule.maxZoom,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          SymbologyRuleDetails(
            key: ValueKey(selected.id),
            geometryKind: widget.geometryKind,
            rule: selected,
            availableFields: widget.availableFields,
            onChanged: _updateSelectedRule,
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text('Nenhuma regra cadastrada.'),
            ),
          ),
      ],
    );
  }
}