import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/component/component_data_catalog.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/component/component_card.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/component/component_catalog.dart';

class ComponentSection extends StatelessWidget {
  final String title;
  final List<ComponentDataCatalog> items;
  final String? selectedItemId;
  final ValueChanged<ComponentDataCatalog>? onItemTap;

  const ComponentSection({
    super.key,
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
        ComponentCatalog(title: title),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final selected = selectedItemId == item.id;

            final card = ComponentCard(
              item: item,
              selected: selected,
              onTap: () => onItemTap?.call(item),
            );

            return Draggable<ComponentDataCatalog>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: ComponentCard(
                  item: item,
                  selected: true,
                  isDragging: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.30,
                child: IgnorePointer(child: card),
              ),
              child: card,
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}