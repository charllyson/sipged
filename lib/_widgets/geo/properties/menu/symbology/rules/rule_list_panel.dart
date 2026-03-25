import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/buttons/geo_action_button.dart';

class RuleListPanel extends StatelessWidget {
  final List<LayerRuleData> rules;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;
  final String Function(LayerRuleOperator op) operatorLabel;

  const RuleListPanel({
    super.key,
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
      GeoActionButton(
        icon: Icons.add,
        color: Colors.green.shade600,
        tooltip: 'Adicionar regra',
        onTap: onAdd,
      ),
      GeoActionButton(
        icon: Icons.remove,
        color: Colors.red.shade600,
        tooltip: 'Remover regra',
        onTap: onRemove,
      ),
      GeoActionButton(
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
                : RepaintBoundary(
              child: Scrollbar(
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