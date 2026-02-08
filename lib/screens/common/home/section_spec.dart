import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/module/module_data.dart';
import 'package:siged/_widgets/cards/action/action_card.dart';
import 'package:siged/_widgets/cards/action/action_item.dart';

class SectionSpec {
  final String title;
  final List<ActionItem> items;
  SectionSpec({required this.title, required this.items});
}

class SectionGrid extends StatelessWidget {
  const SectionGrid({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
  });

  final String title;
  final List<ActionItem> items;
  final void Function(ModuleItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.blueGrey.shade900;

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
            if (w >= 1100) cross = 3;
            else if (w >= 740) cross = 2;

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
                final a = items[i];
                return ActionCard(
                  item: a,
                  onTap: () => onSelect?.call(a.item),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
