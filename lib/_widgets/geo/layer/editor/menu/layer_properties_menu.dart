import 'package:flutter/material.dart';

import 'package:sipged/_widgets/geo/layer/editor/menu/layer_properties_types.dart';

class LayerPropertiesMenu extends StatelessWidget {
  final List<LayerPropertiesMenuItemData> items;
  final LayerPropertiesTab selectedTab;
  final ValueChanged<LayerPropertiesTab> onTapItem;
  final bool isCompact;

  const LayerPropertiesMenu({
    super.key,
    required this.items,
    required this.selectedTab,
    required this.onTapItem,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F23),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: EdgeInsets.all(isCompact ? 6 : 3),
          children: items
              .map(
                (item) => LayerPropertiesMenuItem(
              item: item,
              isCompact: isCompact,
              selected: item.tab == selectedTab,
              onTap: () => onTapItem(item.tab),
            ),
          )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class LayerPropertiesMenuItem extends StatelessWidget {
  final LayerPropertiesMenuItemData item;
  final bool selected;
  final bool isCompact;
  final VoidCallback onTap;

  const LayerPropertiesMenuItem({
    super.key,
    required this.item,
    required this.selected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 0 : 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.18)
                : Colors.transparent,
            border: selected
                ? Border.all(
              color: selectedColor.withValues(alpha: 0.70),
              width: 1.2,
            )
                : null,
          ),
          child: isCompact
              ? Center(
            child: Icon(
              item.icon,
              color: selected ? Colors.white : Colors.white70,
              size: 20,
            ),
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                color: selected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isCompact) {
      return Tooltip(
        message: item.title,
        child: child,
      );
    }

    return child;
  }
}