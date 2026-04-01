import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/component/component_data_catalog.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/component/component_section.dart';

class ComponentPanel extends StatelessWidget {
  final ValueChanged<ComponentDataCatalog>? onItemTap;
  final String? selectedItemId;

  const ComponentPanel({
    super.key,
    this.onItemTap,
    this.selectedItemId,
  });

  static const List<ComponentDataCatalog> items = [
    ComponentDataCatalog(
      id: 'chart_bar_vertical',
      title: 'Barra vertical',
      icon: Icons.bar_chart_rounded,
      category: 'Gráficos',
      description: 'Categoria + valor agregado',
    ),
    ComponentDataCatalog(
      id: 'chart_donut',
      title: 'Rosca',
      icon: Icons.donut_large_rounded,
      category: 'Gráficos',
      description: 'Segmentos proporcionais',
    ),
    ComponentDataCatalog(
      id: 'chart_line',
      title: 'Linha',
      icon: Icons.show_chart_rounded,
      category: 'Gráficos',
      description: 'Série temporal ou evolução',
    ),
    ComponentDataCatalog(
      id: 'widget_card',
      title: 'Card resumo',
      icon: Icons.crop_7_5_rounded,
      category: 'Widgets',
      description: 'Resumo com título e valor',
    ),
  ];

  static final Map<String, List<ComponentDataCatalog>> groupedItems = () {
    final grouped = <String, List<ComponentDataCatalog>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => <ComponentDataCatalog>[]);
      grouped[item.category]!.add(item);
    }
    return grouped;
  }();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: groupedItems.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: ComponentSection(
            title: entry.key,
            items: entry.value,
            selectedItemId: selectedItemId,
            onItemTap: onItemTap,
          ),
        );
      }).toList(growable: false),
    );
  }
}