import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;

// importe seu TypeBadgeButton
import 'type_badge_button.dart';

class MagicHeaderRow extends StatelessWidget {
  const MagicHeaderRow({
    super.key,
    required this.ctrl,
    required this.hHeaderCtrl,
    required this.headerHeight,
    this.ghostColWidth = 48,
    this.rightScrollGap = 0,
    required this.onAddColumn,
    required this.onRemoveColumn,
  });

  final bc.MagicTableController ctrl;
  final ScrollController hHeaderCtrl;
  final double headerHeight;
  final double ghostColWidth;
  final double rightScrollGap;
  final VoidCallback onAddColumn;
  final void Function(int col) onRemoveColumn;

  static const double _resizeHandleWidth = 8;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: hHeaderCtrl,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(ctrl.colCount, (c) {
            final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;
            final hasType = (c < ctrl.colTypes.length) &&
                ctrl.colTypes[c] != bc.ColumnType.auto;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // célula do header
                Container(
                  width: w,
                  height: headerHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Text(
                    ctrl.excelColName(c),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

                // --- handle de resize (fica por baixo do badge) ---
                Positioned(
                  right: -_resizeHandleWidth / 2,
                  top: 0,
                  bottom: 0,
                  width: _resizeHandleWidth,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        final numeric = ctrl.isNumericEffective(c);
                        final maxW = numeric
                            ? double.infinity
                            : bc.MagicTableController.maxColWidthNonNumeric;
                        final next = (ctrl.colWidths[c] + details.delta.dx).clamp(
                          bc.MagicTableController.minColWidth,
                          maxW,
                        );
                        ctrl.colWidths[c] = next.toDouble();
                        ctrl.notifyListeners();
                      },
                      onDoubleTap: () {
                        ctrl.colWidths[c] = ctrl.autoFitColWidth(c);
                        ctrl.notifyListeners();
                      },
                    ),
                  ),
                ),

                // --- badge do tipo (desenhado por último => fica por cima) ---
                Positioned(
                  top: 4,
                  // dá uma folga da borda direita pra não pegar a área do resize
                  right: 8,
                  child: SizedBox(
                    width: 24, // área de clique um pouco maior
                    height: 24,
                    child: Center(
                      child: TypeBadgeButton(
                        hasType: hasType,
                        type: (c < ctrl.colTypes.length)
                            ? ctrl.colTypes[c]
                            : bc.ColumnType.auto,
                        onSelected: (t) => ctrl.setColumnType(c, t),
                        onRemove: () => onRemoveColumn(c),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          // Coluna fantasma (+)
          SizedBox(
            width: ghostColWidth,
            height: headerHeight,
            child: Material(
              color: Colors.grey.shade100,
              child: InkWell(
                onTap: onAddColumn,
                child: const Center(
                  child: Icon(Icons.add, size: 18),
                ),
              ),
            ),
          ),

          // gap à direita (só aparece no fim da rolagem horizontal)
          SizedBox(width: rightScrollGap, height: headerHeight),
        ],
      ),
    );
  }
}
