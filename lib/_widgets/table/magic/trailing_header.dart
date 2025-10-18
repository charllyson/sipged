import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/trailing_col_meta.dart';

class MagicTrailingHeader extends StatelessWidget {
  const MagicTrailingHeader({
    super.key,
    required this.trailingCols,
    required this.rowHeight,
    required this.cellPad,
  });

  final List<TrailingColMeta> trailingCols;
  final double rowHeight;
  final EdgeInsets cellPad;

  @override
  Widget build(BuildContext context) {
    if (trailingCols.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (int i = 0; i < trailingCols.length; i++)
          Container(
            width: trailingCols[i].width,
            height: rowHeight,
            alignment: Alignment.center,
            padding: cellPad,
            decoration: BoxDecoration(
              color: const Color(0xFF091D68),
              border: Border(
                left: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                right: (i == trailingCols.length - 1)
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Text(
              trailingCols[i].title,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
