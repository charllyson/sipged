import 'package:flutter/material.dart';
import 'magic_table_controller.dart' as bc;

class MagicGutterColumn extends StatelessWidget {
  const MagicGutterColumn({
    super.key,
    required this.ctrl,
    required this.vGutterCtrl,
    required this.rowHeight,
    required this.rowCountWithGhost,
    this.onAddRow,
    this.bottomScrollGap = 0,
    this.addTopBorder = false,
  });

  final bc.MagicTableController ctrl;
  final ScrollController vGutterCtrl;
  final double rowHeight;
  final int rowCountWithGhost;

  /// se null, não mostra a “linha fantasma” (+)
  final VoidCallback? onAddRow;

  final double bottomScrollGap;

  /// Quando true, aplica borda superior na primeira célula.
  final bool addTopBorder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: vGutterCtrl,
      child: Column(
        children: [
          ...List.generate(rowCountWithGhost, (r) {
            final isFirst = r == 0;
            final isGhost = r == ctrl.rowCount;

            if (isGhost && onAddRow == null) {
              return const SizedBox.shrink();
            }

            final topSide = (isFirst && addTopBorder)
                ? BorderSide(color: Colors.grey.shade300, width: 1)
                : BorderSide.none;

            Widget cell = Container(
              height: rowHeight,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isGhost
                    ? Colors.grey.shade100
                    : (isFirst ? Colors.grey.shade200 : Colors.grey.shade50),
                border: Border(
                  top: topSide,
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: BorderSide(color: Colors.grey.shade300, width: 1),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: isGhost
                  ? const Icon(Icons.add_rounded, size: 18)
                  : Text(
                '${r + 1}',
                style: TextStyle(
                  fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            );

            if (isGhost) cell = InkWell(onTap: onAddRow, child: cell);
            return cell;
          }),
          SizedBox(height: bottomScrollGap),
        ],
      ),
    );
  }
}
