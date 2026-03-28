import 'package:flutter/material.dart';

class LayerItemsList<T> extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<T> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  final Widget Function(
      BuildContext context,
      T item,
      int index,
      bool isSelected,
      ) previewBuilder;

  final String Function(T item, int index) titleBuilder;

  final TextStyle? titleStyle;
  final double spacing;

  const LayerItemsList({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.previewBuilder,
    required this.titleBuilder,
    this.title = 'Camadas',
    this.emptyMessage = 'Nenhuma camada cadastrada.',
    this.titleStyle,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
              child: Text(emptyMessage),
            )
                : RepaintBoundary(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedIndex == index;

                  return InkWell(
                    onTap: () => onSelect(index),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.10)
                          : Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            previewBuilder(
                              context,
                              item,
                              index,
                              isSelected,
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: Text(
                                titleBuilder(item, index),
                                style: titleStyle ??
                                    const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}