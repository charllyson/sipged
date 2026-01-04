import 'package:flutter/material.dart';

/// Uma linha única que NUNCA faz wrap nem scroll:
class OneLineRow extends StatelessWidget {
  final List<Widget> children;
  final Color? textColor;

  const OneLineRow({super.key, required this.children, this.textColor});

  @override
  Widget build(BuildContext context) {
    final row = DefaultTextStyle.merge(
      style: TextStyle(color: textColor),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
    return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: row);
  }
}
