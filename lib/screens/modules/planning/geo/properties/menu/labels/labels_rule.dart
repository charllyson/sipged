import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/labels/labels_rule_details.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_column.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_core.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_list.dart';

class LabelsRule extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerDataSimple> symbolLayers;
  final List<GeoLabelRuleData> rules;
  final List<String> availableFields;
  final ValueChanged<List<GeoLabelRuleData>> onChanged;

  const LabelsRule({
    super.key,
    required this.geometryKind,
    required this.symbolLayers,
    required this.rules,
    required this.availableFields,
    required this.onChanged,
  });

  @override
  State<LabelsRule> createState() => _LabelsRuleState();
}

class _LabelsRuleState extends State<LabelsRule> {
  late List<GeoLabelRuleData> _rules;
  int _selectedRuleIndex = 0;

  @override
  void initState() {
    super.initState();
    _rules = List<GeoLabelRuleData>.from(widget.rules);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant LabelsRule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.rules, widget.rules)) {
      _rules = List<GeoLabelRuleData>.from(widget.rules);
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
    widget.onChanged(List<GeoLabelRuleData>.unmodifiable(_rules));
  }

  GeoLabelRuleData? get _selectedRule {
    if (_rules.isEmpty) return null;
    return _rules[_selectedRuleIndex];
  }

  void _addRule() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final defaultField =
    widget.availableFields.isNotEmpty ? widget.availableFields.first : '';

    _rules.add(
      GeoLabelRuleData(
        id: 'label_rule_$now',
        label: 'Nova regra ${_rules.length + 1}',
        field: defaultField,
        style: LayerRuleCore.createDefaultLabelStyle(
          id: 'label_style_$now',
          title: 'Rótulo da regra ${_rules.length + 1}',
          text: defaultField,
        ),
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
      id: 'label_rule_$now',
      label: '${selected.label} (cópia)',
      style: selected.style.copyWith(
        id: 'label_style_$now',
        title: '${selected.style.title} (cópia)',
      ),
    );

    _rules.insert(_selectedRuleIndex + 1, duplicated);
    _selectedRuleIndex++;
    _notifyParent();
  }

  void _updateSelectedRule(GeoLabelRuleData value) {
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
        LayerRuleList<GeoLabelRuleData>(
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
          extraColumns: [
            LayerRuleColumn<GeoLabelRuleData>(
              title: 'Campo do rótulo',
              width: 180,
              cellBuilder: (rule) => Text(
                rule.style.text,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          emptyMessage: 'Nenhuma regra de rótulo cadastrada.',
        ),
        const SizedBox(height: 12),
        if (selected != null)
          LabelsRuleDetails(
            key: ValueKey(selected.id),
            geometryKind: widget.geometryKind,
            symbolLayers: widget.symbolLayers,
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