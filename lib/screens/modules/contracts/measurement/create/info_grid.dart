import 'package:flutter/material.dart';
import 'package:siged/screens/modules/contracts/measurement/create/info_cell_padding.dart';
import 'package:siged/screens/modules/contracts/measurement/create/label_value.dart';

class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key,
    required this.rows,
    this.columns = 1,
  });

  final List<LabelValue> rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade400;

    List<List<LabelValue>> chunked = <List<LabelValue>>[];
    if (columns <= 1) {
      chunked.add(rows);
    } else {
      final per = (rows.length / columns).ceil();
      for (int i = 0; i < rows.length; i += per) {
        chunked.add(rows.sublist(i, (i + per > rows.length) ? rows.length : i + per));
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int c = 0; c < chunked.length; c++) ...[
            if (c > 0) Container(width: 1, color: borderColor),
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < chunked[c].length; i++) ...[
                    if (i > 0) Container(height: 1, color: borderColor),
                    const InfoCellPadding(),
                    InfoCell(item: chunked[c][i]),
                  ]
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}