import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/flyout_tile.dart';
import 'package:siged/_widgets/toolBox/tool_action.dart';

class FlyoutList extends StatelessWidget {
  const FlyoutList({
    super.key,
    required this.items,
    required this.maxHeight,
    required this.onItemTap,
    required this.onItemHover,
  });

  final List<ToolAction> items;
  final double maxHeight;
  final void Function(int index, ToolAction action) onItemTap;
  final void Function(int index, ToolAction action) onItemHover;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(
        FlyoutTile(
          icon: items[i].icon,
          label: items[i].tooltip,
          hasSide: items[i].sideBuilder != null,
          onTap: () => onItemTap(i, items[i]),
          onHover: () => onItemHover(i, items[i]),
        ),
      );
      if (i != items.length - 1) {
        children.add(const SizedBox(
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF6E6E6E)),
          ),
        ));
      }
    }

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            widthFactor: 1,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}
