// lib/screens/common/modules/section_spec.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';

import 'package:sipged/screens/common/modules/module_tile.dart';
import 'package:sipged/screens/common/modules/section_header.dart';

class SectionGrid extends StatelessWidget {
  const SectionGrid({
    super.key,
    required this.title,
    required this.sectionIcon,
    required this.sectionColor,
    required this.items,
    required this.onSelect,
    required this.isDark,
  });

  final String title;
  final IconData sectionIcon;
  final Color sectionColor;
  final List<ModuleData> items;
  final void Function(ModuleEnum value)? onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.blueGrey.shade900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          titleColor: titleColor,
          sectionColor: sectionColor,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = _resolveCrossAxisCount(width);
            final spacing = _resolveSpacing(width);
            final itemExtent = _resolveItemExtent(width);
            final compact = width < 600;

            return GridView.builder(
              key: PageStorageKey<String>('section-grid-$title'),
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

                return ModuleTile(
                  key: ValueKey<String>(
                    'module-tile-${item.permissionModule}',
                  ),
                  item: item,
                  isDark: isDark,
                  compact: compact,
                  fallbackIcon: sectionIcon,
                  fallbackColor: sectionColor,
                  onTap: onSelect == null
                      ? null
                      : () {
                    onSelect?.call(item.menuModuleItem);
                  },
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
    if (width >= 340) return 4;
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