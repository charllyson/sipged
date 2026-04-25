import 'package:flutter/material.dart';
import 'package:sipged/screens/common/home/module_tile.dart';
import 'package:sipged/screens/common/home/module_data_item.dart';
import 'package:sipged/screens/common/home/section_header.dart';

class SectionGrid<T> extends StatelessWidget {
  const SectionGrid({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    required this.isDark,
  });

  final String title;
  final List<ModuleDataItem<T>> items;
  final void Function(T value)? onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.blueGrey.shade900;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.blueGrey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          titleColor: titleColor,
          subtitleColor: subtitleColor,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = _resolveCrossAxisCount(width);
            final spacing = _resolveSpacing(width);
            final itemExtent = _resolveItemExtent(width);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                mainAxisExtent: itemExtent,
              ),
              itemBuilder: (context, index) {
                final item = items[index];

                return ModuleTile<T>(
                  item: item,
                  isDark: isDark,
                  compact: width < 600,
                  onTap: () => onSelect?.call(item.value),
                );
              },
            );
          },
        ),
      ],
    );
  }

  int _resolveCrossAxisCount(double width) {
    if (width >= 1180) return 8;
    if (width >= 1040) return 7;
    if (width >= 900) return 6;
    if (width >= 720) return 5;

    // iPhone / celulares médios e grandes: semelhante ao iOS, 4 apps por linha.
    if (width >= 340) return 4;

    // Celulares muito estreitos.
    if (width >= 260) return 3;

    return 2;
  }

  double _resolveSpacing(double width) {
    if (width >= 720) return 20;
    if (width >= 340) return 12;
    return 10;
  }

  double _resolveItemExtent(double width) {
    if (width >= 720) return 148;
    if (width >= 340) return 134;
    return 128;
  }
}