import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/float_action_button.dart';
import 'package:sipged/_widgets/geo/visualizations/catalog/tab_widget_catalog.dart';
import 'package:sipged/_widgets/geo/visualizations/catalog/tab_widget_data.dart';

class TabWidgetPanel extends StatelessWidget {
  final ValueChanged<TabWidgetsCatalog>? onItemTap;
  final String? selectedItemId;

  const TabWidgetPanel({
    super.key,
    this.onItemTap,
    this.selectedItemId,
  });

  static const List<TabWidgetsCatalog> items = [
    TabWidgetsCatalog(
      id: 'chart_bar_vertical',
      title: 'Barra vertical',
      icon: Icons.bar_chart,
      category: 'Gráficos',
      description: 'Categoria + valor agregado',
    ),
    TabWidgetsCatalog(
      id: 'chart_donut',
      title: 'Rosca',
      icon: Icons.donut_large,
      category: 'Gráficos',
      description: 'Segmentos proporcionais',
    ),
    TabWidgetsCatalog(
      id: 'chart_line',
      title: 'Linha',
      icon: Icons.show_chart,
      category: 'Gráficos',
      description: 'Série temporal ou evolução',
    ),
    TabWidgetsCatalog(
      id: 'widget_card',
      title: 'Card resumo',
      icon: Icons.crop_7_5,
      category: 'Widgets',
      description: 'Resumo com título e valor',
    ),
    TabWidgetsCatalog(
      id: 'widget_kpi',
      title: 'KPI',
      icon: Icons.speed,
      category: 'Widgets',
      description: 'Indicador principal',
    ),
    TabWidgetsCatalog(
      id: 'widget_table',
      title: 'Tabela',
      icon: Icons.table_chart,
      category: 'Widgets',
      description: 'Listagem tabular',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final grouped = <String, List<TabWidgetsCatalog>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => <TabWidgetsCatalog>[]);
      grouped[item.category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabWidgetCatalog(title: entry.key),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((item) {
                  final selected = selectedItemId == item.id;

                  final tile = FloatActionButton(
                    tooltip: item.description == null
                        ? item.title
                        : '${item.title}\n${item.description}',
                    cursor: SystemMouseCursors.grab,
                    iconColor: selected
                        ? primary
                        : primary.withValues(alpha: 0.90),
                    borderColor: selected
                        ? primary.withValues(alpha: 0.75)
                        : Colors.black.withValues(alpha: 0.08),
                    borderHoverColor: selected
                        ? primary
                        : primary.withValues(alpha: 0.35),
                    width: 74,
                    height: 74,
                    borderRadius: 8,
                    backgroundColor: selected
                        ? primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    hoverBackgroundColor:
                    primary.withValues(alpha: 0.08),
                    shadowColor: selected
                        ? primary.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.10),
                    shadowBlurRadius: selected ? 8 : 6,
                    shadowOffset: const Offset(0, 2),
                    onTap: () => onItemTap?.call(item),
                    customChild: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected
                              ? primary
                              : primary.withValues(alpha: 0.90),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  return Draggable<TabWidgetsCatalog>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: FloatActionButton(
                        tooltip: item.title,
                        cursor: SystemMouseCursors.grabbing,
                        iconColor: primary,
                        borderColor:
                        primary.withValues(alpha: 0.45),
                        borderHoverColor:
                        primary.withValues(alpha: 0.45),
                        width: 180,
                        height: 46,
                        borderRadius: 10,
                        backgroundColor: Colors.white,
                        hoverBackgroundColor: Colors.white,
                        shadowColor:
                        Colors.black.withValues(alpha: 0.14),
                        shadowBlurRadius: 10,
                        shadowOffset: const Offset(0, 4),
                        customChild: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 18,
                                color: primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: tile,
                    ),
                    child: tile,
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}