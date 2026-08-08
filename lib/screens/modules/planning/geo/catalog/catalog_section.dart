import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_widgets/buttons/icon_button_changed.dart';

class CatalogSection extends StatelessWidget {
  final String title;
  final List<CatalogData> items;
  final String? selectedItemId;
  final ValueChanged<CatalogData>? onItemTap;

  const CatalogSection({
    super.key,
    required this.title,
    required this.items,
    required this.selectedItemId,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final itemId = item.id;
            final selected = selectedItemId == itemId;

            if (item.comingSoon) {
              return IconButtonChanged(
                icon: item.icon ?? Icons.widgets_outlined,
                tooltip: '${item.title} — Em breve',
                selected: false,
                enabled: false,
              );
            }

            final card = IconButtonChanged(
              icon: item.icon ?? Icons.widgets_outlined,
              tooltip: item.title,
              selected: selected,
              onTap: () => onItemTap?.call(item),
            );

            return Draggable<CatalogData>(
              data: item,
              maxSimultaneousDrags: 1,
              rootOverlay: true,
              feedback: Material(
                color: Colors.transparent,
                child: IgnorePointer(
                  child: IconButtonChanged(
                    icon: item.icon ?? Icons.widgets_outlined,
                    tooltip: item.title,
                    selected: true,
                    isDragging: true,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.30,
                child: IgnorePointer(
                  child: card,
                ),
              ),
              child: card,
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}