import 'package:flutter/material.dart';

class GeoVisualizationCatalogItem {
  final String id;
  final String title;
  final IconData icon;
  final String category;
  final String? description;

  const GeoVisualizationCatalogItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    this.description,
  });
}

class GeoVisualizationsPanel extends StatelessWidget {
  final ValueChanged<GeoVisualizationCatalogItem>? onItemTap;
  final String? selectedItemId;

  const GeoVisualizationsPanel({
    super.key,
    this.onItemTap,
    this.selectedItemId,
  });

  static const List<GeoVisualizationCatalogItem> items = [
    GeoVisualizationCatalogItem(
      id: 'chart_bar_vertical',
      title: 'Barra vertical',
      icon: Icons.bar_chart,
      category: 'Gráficos',
      description: 'Categoria + valor agregado',
    ),
    GeoVisualizationCatalogItem(
      id: 'chart_donut',
      title: 'Rosca',
      icon: Icons.donut_large,
      category: 'Gráficos',
      description: 'Segmentos proporcionais',
    ),
    GeoVisualizationCatalogItem(
      id: 'chart_line',
      title: 'Linha',
      icon: Icons.show_chart,
      category: 'Gráficos',
      description: 'Série temporal ou evolução',
    ),
    GeoVisualizationCatalogItem(
      id: 'widget_card',
      title: 'Card resumo',
      icon: Icons.crop_7_5,
      category: 'Widgets',
      description: 'Resumo com título e valor',
    ),
    GeoVisualizationCatalogItem(
      id: 'widget_kpi',
      title: 'KPI',
      icon: Icons.speed,
      category: 'Widgets',
      description: 'Indicador principal',
    ),
    GeoVisualizationCatalogItem(
      id: 'widget_table',
      title: 'Tabela',
      icon: Icons.table_chart,
      category: 'Widgets',
      description: 'Listagem tabular',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<GeoVisualizationCatalogItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => <GeoVisualizationCatalogItem>[]);
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
              _CatalogSectionHeader(title: entry.key),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((item) {
                  return _VisualizationIconButton(
                    item: item,
                    selected: selectedItemId == item.id,
                    onTap: () => onItemTap?.call(item),
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

class _CatalogSectionHeader extends StatelessWidget {
  final String title;

  const _CatalogSectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _VisualizationIconButton extends StatefulWidget {
  final GeoVisualizationCatalogItem item;
  final VoidCallback onTap;
  final bool selected;

  const _VisualizationIconButton({
    required this.item,
    required this.onTap,
    required this.selected,
  });

  @override
  State<_VisualizationIconButton> createState() =>
      _VisualizationIconButtonState();
}

class _VisualizationIconButtonState extends State<_VisualizationIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isActive = widget.selected || _hovered;

    final child = Tooltip(
      message: widget.item.description == null
          ? widget.item.title
          : '${widget.item.title}\n${widget.item.description}',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? primary.withValues(alpha: 0.16)
                  : isActive
                  ? primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selected
                    ? primary.withValues(alpha: 0.75)
                    : isActive
                    ? primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                width: widget.selected ? 1.4 : 1,
              ),
              boxShadow: widget.selected
                  ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  size: 22,
                  color: widget.selected
                      ? primary
                      : primary.withValues(alpha: isActive ? 1.0 : 0.85),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Draggable<GeoVisualizationCatalogItem>(
      data: widget.item,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primary.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 18,
                color: primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.title,
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
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: child,
      ),
      child: child,
    );
  }
}