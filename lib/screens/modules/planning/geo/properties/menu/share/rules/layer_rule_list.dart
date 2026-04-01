import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_buttons.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_column.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_core.dart';

class LayerRuleList<T> extends StatelessWidget {
  final List<T> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;

  final String Function(T item) labelOf;
  final bool Function(T item) enabledOf;
  final String Function(T item) fieldOf;
  final LayerRuleOperator Function(T item) operatorOf;
  final String Function(T item) valueOf;
  final double? Function(T item) minZoomOf;
  final double? Function(T item) maxZoomOf;
  final List<LayerRuleColumn<T>> extraColumns;

  final String labelColumnTitle;
  final String ruleColumnTitle;
  final String emptyMessage;

  const LayerRuleList({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
    required this.onDuplicate,
    required this.labelOf,
    required this.enabledOf,
    required this.fieldOf,
    required this.operatorOf,
    required this.valueOf,
    required this.minZoomOf,
    required this.maxZoomOf,
    this.extraColumns = const [],
    this.labelColumnTitle = 'Rótulo',
    this.ruleColumnTitle = 'Regra',
    this.emptyMessage = 'Nenhuma regra cadastrada.',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelHeight = screenWidth < 760 ? 220.0 : 300.0;

    final columns = <RuleTableColumn>[
      const RuleTableColumn(title: '', width: 34),
      RuleTableColumn(title: labelColumnTitle, width: 180),
      RuleTableColumn(title: ruleColumnTitle, width: 240),
      ...extraColumns.map(
            (column) => RuleTableColumn(
          title: column.title,
          width: column.width,
        ),
      ),
      const RuleTableColumn(title: 'Escala mín.', width: 110),
      const RuleTableColumn(title: 'Escala máx.', width: 110),
    ];

    final contentMinWidth =
        columns.fold<double>(0, (sum, column) => sum + column.width) + 20;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(
          constraints.maxWidth,
          contentMinWidth,
        );

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
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Container(
                      color: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: columns
                            .map(
                              (column) => SizedBox(
                            width: column.width,
                            child: Text(
                              column.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                  child: Text(emptyMessage),
                )
                    : RepaintBoundary(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = selectedIndex == index;

                        return InkWell(
                          onTap: () => onSelect(index),
                          child: Container(
                            color: isSelected
                                ? Colors.blue.withValues(alpha: 0.10)
                                : Colors.transparent,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
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
                                          value: enabledOf(item),
                                          onChanged: null,
                                          visualDensity:
                                          VisualDensity.compact,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          labelOf(item).trim().isEmpty
                                              ? '(sem rótulo)'
                                              : labelOf(item),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 240,
                                        child: Text(
                                          LayerRuleCore.ruleText(
                                            field: fieldOf(item),
                                            operatorType:
                                            operatorOf(item),
                                            value: valueOf(item),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ...extraColumns.map(
                                            (column) => SizedBox(
                                          width: column.width,
                                          child:
                                          column.cellBuilder(item),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          minZoomOf(item)
                                              ?.toStringAsFixed(1) ??
                                              '-',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          maxZoomOf(item)
                                              ?.toStringAsFixed(1) ??
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
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                  color: Colors.grey.shade50,
                ),
                child: RuleActionButtons(
                  onAdd: onAdd,
                  onRemove: onRemove,
                  onDuplicate: onDuplicate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}