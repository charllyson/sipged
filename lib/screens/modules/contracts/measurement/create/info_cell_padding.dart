import 'package:flutter/material.dart';
import 'package:siged/screens/modules/contracts/measurement/create/label_value.dart';

class InfoCellPadding extends StatelessWidget {
  const InfoCellPadding({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class InfoCell extends StatelessWidget {
  const InfoCell({super.key, required this.item});
  final LabelValue item;

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(fontWeight: FontWeight.w700, fontSize: 12);
    const valueStyle = TextStyle(fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Text(item.label, style: labelStyle),
          const SizedBox(width: 6),
          Expanded(
            child: Align(
              alignment: item.alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(item.value, style: valueStyle, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

