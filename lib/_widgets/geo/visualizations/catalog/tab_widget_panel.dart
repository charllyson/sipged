import 'package:flutter/material.dart';
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
      icon: Icons.bar_chart_rounded,
      category: 'Gráficos',
      description: 'Categoria + valor agregado',
    ),
    TabWidgetsCatalog(
      id: 'chart_donut',
      title: 'Rosca',
      icon: Icons.donut_large_rounded,
      category: 'Gráficos',
      description: 'Segmentos proporcionais',
    ),
    TabWidgetsCatalog(
      id: 'chart_line',
      title: 'Linha',
      icon: Icons.show_chart_rounded,
      category: 'Gráficos',
      description: 'Série temporal ou evolução',
    ),
    TabWidgetsCatalog(
      id: 'widget_card',
      title: 'Card resumo',
      icon: Icons.crop_7_5_rounded,
      category: 'Widgets',
      description: 'Resumo com título e valor',
    ),
    TabWidgetsCatalog(
      id: 'widget_table',
      title: 'Tabela',
      icon: Icons.table_chart_rounded,
      category: 'Widgets',
      description: 'Listagem tabular',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TabWidgetsCatalog>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => <TabWidgetsCatalog>[]);
      grouped[item.category]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: CatalogSection(
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

class CatalogSection extends StatelessWidget {
  final String title;
  final List<TabWidgetsCatalog> items;
  final String? selectedItemId;
  final ValueChanged<TabWidgetsCatalog>? onItemTap;

  const CatalogSection({super.key,
    required this.title,
    required this.items,
    required this.selectedItemId,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabWidgetCatalog(title: title),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final selected = selectedItemId == item.id;

            final card = CatalogWidgetCard(
              item: item,
              selected: selected,
              onTap: () => onItemTap?.call(item),
            );

            return Draggable<TabWidgetsCatalog>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.02,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CatalogWidgetCard(
                      item: item,
                      selected: true,
                      isDragging: true,
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.30,
                child: card,
              ),
              child: card,
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class CatalogWidgetCard extends StatefulWidget {
  final TabWidgetsCatalog item;
  final bool selected;
  final bool isDragging;
  final VoidCallback? onTap;

  const CatalogWidgetCard({super.key,
    required this.item,
    required this.selected,
    this.isDragging = false,
    this.onTap,
  });

  @override
  State<CatalogWidgetCard> createState() => _CatalogWidgetCardState();
}

class _CatalogWidgetCardState extends State<CatalogWidgetCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = scheme.primary;
    final hovered = _hovered || widget.selected || widget.isDragging;

    final backgroundColor = widget.selected
        ? (isDark ? const Color(0xFF1A1A22) : const Color(0xFFF8F8FA))
        : (isDark ? const Color(0xFF171717) : Colors.white);

    final borderColor = widget.selected
        ? primary.withValues(alpha: 0.70)
        : hovered
        ? primary.withValues(alpha: 0.28)
        : (isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08));

    final iconColor = widget.selected
        ? primary
        : hovered
        ? primary.withValues(alpha: 0.95)
        : primary.withValues(alpha: 0.82);

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.item.title,
        waitDuration: const Duration(milliseconds: 250),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: hovered ? 1.015 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.selected ? 1.1 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.selected
                      ? primary.withValues(alpha: isDark ? 0.18 : 0.14)
                      : Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: widget.selected ? 14 : hovered ? 12 : 8,
                  offset: Offset(0, widget.selected ? 4 : 3),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Center(
                child: Icon(
                  widget.item.icon,
                  size: 26,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}