import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/rules/rule_details.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/rules/rule_list_panel.dart';

class RuleSymbology extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final List<GeoLayersDataRule> rules;
  final List<String> availableFields;
  final ValueChanged<List<GeoLayersDataRule>> onChanged;

  const RuleSymbology({
    super.key,
    required this.geometryKind,
    required this.rules,
    required this.availableFields,
    required this.onChanged,
  });

  @override
  State<RuleSymbology> createState() => _RuleSymbologyState();
}

class _RuleSymbologyState extends State<RuleSymbology> {
  late List<GeoLayersDataRule> _rules;
  int _selectedRuleIndex = 0;

  @override
  void initState() {
    super.initState();
    _rules = List<GeoLayersDataRule>.from(widget.rules);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant RuleSymbology oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.rules, widget.rules)) {
      _rules = List<GeoLayersDataRule>.from(widget.rules);
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
    widget.onChanged(List<GeoLayersDataRule>.unmodifiable(_rules));
  }

  GeoLayersDataRule? get _selectedRule {
    if (_rules.isEmpty) return null;
    return _rules[_selectedRuleIndex];
  }

  LayerSymbolFamily _familyFromGeometry() {
    switch (widget.geometryKind) {
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

  void _addRule() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final defaultField =
    widget.availableFields.isNotEmpty ? widget.availableFields.first : '';

    _rules.add(
      GeoLayersDataRule(
        id: 'rule_$now',
        label: 'Nova regra ${_rules.length + 1}',
        field: defaultField,
        symbolLayers: [
          GeoLayersDataSimple(
            id: 'symbol_$now',
            family: _familyFromGeometry(),
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

    final duplicated = selected.copyWith(
      id: 'rule_$now',
      label: '${selected.label} (cópia)',
      symbolLayers: selected.symbolLayers
          .map(
            (e) => e.copyWith(
          id: 'symbol_${DateTime.now().microsecondsSinceEpoch}_${e.id}',
          family: _familyFromGeometry(),
        ),
      )
          .toList(growable: false),
    );

    _rules.insert(_selectedRuleIndex + 1, duplicated);
    _selectedRuleIndex++;
    _notifyParent();
  }

  void _updateSelectedRule(GeoLayersDataRule value) {
    if (_selectedRule == null) return;
    _rules[_selectedRuleIndex] = value;
    _notifyParent();
  }

  String _operatorLabel(LayerRuleOperator op) {
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

  LayerRuleOperator _operatorFromLabel(String? value) {
    for (final op in LayerRuleOperator.values) {
      if (_operatorLabel(op) == value) return op;
    }
    return LayerRuleOperator.equals;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedRule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RuleListPanel(
          rules: _rules,
          selectedIndex: _selectedRuleIndex,
          onSelect: (index) {
            if (_selectedRuleIndex == index) return;
            setState(() => _selectedRuleIndex = index);
          },
          onAdd: _addRule,
          onRemove: _rules.isEmpty ? null : _removeRule,
          onDuplicate: _rules.isEmpty ? null : _duplicateRule,
          operatorLabel: _operatorLabel,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          RuleDetails(
            key: ValueKey(selected.id),
            geometryKind: widget.geometryKind,
            rule: selected,
            availableFields: widget.availableFields,
            operatorLabel: _operatorLabel,
            operatorFromLabel: _operatorFromLabel,
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