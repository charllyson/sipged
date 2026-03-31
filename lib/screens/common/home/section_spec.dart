import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class SectionSpec<T> {
  final String title;
  final List<BasicCardItem<T>> items;

  const SectionSpec({
    required this.title,
    required this.items,
  });
}

class SectionGrid<T> extends StatelessWidget {
  const SectionGrid({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    required this.isDark,
  });

  final String title;
  final List<BasicCardItem<T>> items;
  final void Function(T value)? onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.blueGrey.shade900;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.blueGrey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
              color: titleColor,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            int cross = 1;

            if (w >= 1100) {
              cross = 3;
            } else if (w >= 740) {
              cross = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 16 / 7,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];

                return BasicCard(
                  isDark: isDark,
                  onTap: () => onSelect?.call(item.value),
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color:
                          item.color.withValues(alpha: isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon,
                          size: 28,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}