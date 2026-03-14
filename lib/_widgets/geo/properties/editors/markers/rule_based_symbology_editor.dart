import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/editors/markers/single_symbol_symbology_editor.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/widgets/stack_action_button.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class RuleBasedSymbologyEditor extends StatefulWidget {
  final List<LayerRuleData> rules;
  final List<String> availableFields;
  final ValueChanged<List<LayerRuleData>> onChanged;

  const RuleBasedSymbologyEditor({
    super.key,
    required this.rules,
    required this.availableFields,
    required this.onChanged,
  });

  @override
  State<RuleBasedSymbologyEditor> createState() =>
      _RuleBasedSymbologyEditorState();
}

class _RuleBasedSymbologyEditorState extends State<RuleBasedSymbologyEditor> {
  late List<LayerRuleData> _rules;
  int _selectedRuleIndex = 0;

  @override
  void initState() {
    super.initState();
    _rules = List<LayerRuleData>.from(widget.rules);
    _normalizeSelection();
  }

  @override
  void didUpdateWidget(covariant RuleBasedSymbologyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.rules, widget.rules)) {
      _rules = List<LayerRuleData>.from(widget.rules);
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

  void _emit() {
    widget.onChanged(List<LayerRuleData>.from(_rules));
    if (mounted) {
      setState(() {});
    }
  }

  LayerRuleData? get _selectedRule {
    if (_rules.isEmpty) return null;
    return _rules[_selectedRuleIndex];
  }

  void _addRule() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final defaultField =
    widget.availableFields.isNotEmpty ? widget.availableFields.first : '';

    _rules.add(
      LayerRuleData(
        id: 'rule_$now',
        label: 'Nova regra ${_rules.length + 1}',
        field: defaultField,
        symbolLayers: [
          LayerSimpleSymbolData(
            id: 'symbol_$now',
          ),
        ],
      ),
    );

    _selectedRuleIndex = _rules.length - 1;
    _emit();
  }

  void _removeRule() {
    if (_rules.isEmpty) return;

    _rules.removeAt(_selectedRuleIndex);

    if (_selectedRuleIndex >= _rules.length) {
      _selectedRuleIndex = _rules.isEmpty ? 0 : _rules.length - 1;
    }

    _emit();
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
        ),
      )
          .toList(growable: false),
    );

    _rules.insert(_selectedRuleIndex + 1, duplicated);
    _selectedRuleIndex++;
    _emit();
  }

  void _updateSelectedRule(LayerRuleData value) {
    if (_selectedRule == null) return;
    _rules[_selectedRuleIndex] = value;
    _emit();
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
        _RuleListPanel(
          rules: _rules,
          selectedIndex: _selectedRuleIndex,
          onSelect: (index) => setState(() => _selectedRuleIndex = index),
          onAdd: _addRule,
          onRemove: _rules.isEmpty ? null : _removeRule,
          onDuplicate: _rules.isEmpty ? null : _duplicateRule,
          operatorLabel: _operatorLabel,
        ),
        const SizedBox(height: 12),
        if (selected != null)
          _RuleDetailsEditor(
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

class _RuleListPanel extends StatelessWidget {
  final List<LayerRuleData> rules;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;
  final String Function(LayerRuleOperator op) operatorLabel;

  const _RuleListPanel({
    required this.rules,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
    required this.onDuplicate,
    required this.operatorLabel,
  });

  String _ruleText(LayerRuleData rule) {
    if (rule.field.trim().isEmpty) return '(sem filtro)';

    if (rule.operatorType == LayerRuleOperator.isEmpty ||
        rule.operatorType == LayerRuleOperator.isNotEmpty) {
      return '${rule.field} ${operatorLabel(rule.operatorType)}';
    }

    return '${rule.field} ${operatorLabel(rule.operatorType)} ${rule.value}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelHeight = screenWidth < 760 ? 220.0 : 300.0;

    final actions = [
      StackActionButton(
        icon: Icons.add,
        color: Colors.green.shade600,
        tooltip: 'Adicionar regra',
        onTap: onAdd,
      ),
      StackActionButton(
        icon: Icons.remove,
        color: Colors.red.shade600,
        tooltip: 'Remover regra',
        onTap: onRemove,
      ),
      StackActionButton(
        icon: Icons.copy_outlined,
        color: Colors.orange.shade700,
        tooltip: 'Duplicar regra',
        onTap: onDuplicate,
      ),
    ];

    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 34, child: Text('Atv')),
                      SizedBox(
                        width: 180,
                        child: Text(
                          'Rótulo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: Text(
                          'Regra',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Escala mín.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Escala máx.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: rules.isEmpty
                ? const Center(child: Text('Nenhuma regra cadastrada.'))
                : Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  final isSelected = selectedIndex == index;

                  return InkWell(
                    onTap: () => onSelect(index),
                    child: Container(
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.10)
                          : Colors.transparent,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(minWidth: 720),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 34,
                                  child: Checkbox(
                                    value: rule.enabled,
                                    onChanged: null,
                                    visualDensity:
                                    VisualDensity.compact,
                                  ),
                                ),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    rule.label.isEmpty
                                        ? '(sem rótulo)'
                                        : rule.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 240,
                                  child: Text(
                                    _ruleText(rule),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    rule.minZoom?.toStringAsFixed(1) ??
                                        '-',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    rule.maxZoom?.toStringAsFixed(1) ??
                                        '-',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleDetailsEditor extends StatefulWidget {
  final LayerRuleData rule;
  final List<String> availableFields;
  final String Function(LayerRuleOperator op) operatorLabel;
  final LayerRuleOperator Function(String? label) operatorFromLabel;
  final ValueChanged<LayerRuleData> onChanged;

  const _RuleDetailsEditor({
    required this.rule,
    required this.availableFields,
    required this.operatorLabel,
    required this.operatorFromLabel,
    required this.onChanged,
  });

  @override
  State<_RuleDetailsEditor> createState() => _RuleDetailsEditorState();
}

class _RuleDetailsEditorState extends State<_RuleDetailsEditor> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _fieldCtrl;
  late final TextEditingController _operatorCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _minZoomCtrl;
  late final TextEditingController _maxZoomCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.rule.label);
    _fieldCtrl = TextEditingController(text: widget.rule.field);
    _operatorCtrl = TextEditingController(
      text: widget.operatorLabel(widget.rule.operatorType),
    );
    _valueCtrl = TextEditingController(text: widget.rule.value);
    _minZoomCtrl = TextEditingController(
      text: widget.rule.minZoom?.toString() ?? '',
    );
    _maxZoomCtrl = TextEditingController(
      text: widget.rule.maxZoom?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _RuleDetailsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rule != widget.rule) {
      _labelCtrl.text = widget.rule.label;
      _fieldCtrl.text = widget.rule.field;
      _operatorCtrl.text = widget.operatorLabel(widget.rule.operatorType);
      _valueCtrl.text = widget.rule.value;
      _minZoomCtrl.text = widget.rule.minZoom?.toString() ?? '';
      _maxZoomCtrl.text = widget.rule.maxZoom?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _fieldCtrl.dispose();
    _operatorCtrl.dispose();
    _valueCtrl.dispose();
    _minZoomCtrl.dispose();
    _maxZoomCtrl.dispose();
    super.dispose();
  }

  void _emit(LayerRuleData value) {
    widget.onChanged(value);
  }

  bool get _hideValueField {
    return widget.rule.operatorType == LayerRuleOperator.isEmpty ||
        widget.rule.operatorType == LayerRuleOperator.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 760;
        final fieldWidth = isSmall ? constraints.maxWidth : 220.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: isSmall
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 150).clamp(220.0, 9999.0),
                  child: CustomTextField(
                    controller: _labelCtrl,
                    labelText: 'Rótulo',
                    onChanged: (v) => _emit(rule.copyWith(label: v)),
                  ),
                ),
                Container(
                  width: isSmall ? constraints.maxWidth : 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativa'),
                    value: rule.enabled,
                    onChanged: (v) => _emit(rule.copyWith(enabled: v ?? true)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: DropDownButtonChange(
                    controller: _fieldCtrl,
                    labelText: 'Campo',
                    width: double.infinity,
                    items: widget.availableFields,
                    enabled: widget.availableFields.isNotEmpty,
                    onChanged: (v) {
                      _emit(rule.copyWith(field: v ?? ''));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropDownButtonChange(
                    controller: _operatorCtrl,
                    labelText: 'Operador',
                    width: double.infinity,
                    items: LayerRuleOperator.values
                        .map(widget.operatorLabel)
                        .toList(growable: false),
                    onChanged: (v) {
                      _emit(
                        rule.copyWith(
                          operatorType: widget.operatorFromLabel(v),
                        ),
                      );
                    },
                  ),
                ),
                if (!_hideValueField)
                  SizedBox(
                    width: fieldWidth,
                    child: CustomTextField(
                      controller: _valueCtrl,
                      labelText: 'Valor',
                      onChanged: (v) => _emit(rule.copyWith(value: v)),
                    ),
                  ),
              ],
            ),
            if (widget.availableFields.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Nenhum campo disponível. Carregue a tabela de atributos da camada para usar regras por campo.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isSmall ? constraints.maxWidth : 260,
                  child: CustomTextField(
                    controller: _minZoomCtrl,
                    labelText: 'Escala mínima / zoom mínimo',
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      _emit(
                        v.trim().isEmpty
                            ? rule.copyWith(clearMinZoom: true)
                            : rule.copyWith(minZoom: parsed),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: isSmall ? constraints.maxWidth : 260,
                  child: CustomTextField(
                    controller: _maxZoomCtrl,
                    labelText: 'Escala máxima / zoom máximo',
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      _emit(
                        v.trim().isEmpty
                            ? rule.copyWith(clearMaxZoom: true)
                            : rule.copyWith(maxZoom: parsed),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cada regra possui sua própria pilha de símbolos.
            SingleSymbolSymbologyEditor(
              symbolLayers: rule.symbolLayers,
              onChanged: (layers) {
                _emit(rule.copyWith(symbolLayers: layers));
              },
            ),
          ],
        );
      },
    );
  }
}