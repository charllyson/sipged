import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_changed.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:siged/_widgets/table/magic/trailing_col_meta.dart';
import 'package:siged/_widgets/table/magic/gutter_column.dart';
import 'package:siged/_widgets/table/magic/grid_body.dart';
import 'leading_column.dart';
import 'trailing_header.dart';
import 'trailing_column.dart';

class MagicBodyRow extends StatelessWidget {
  const MagicBodyRow({
    super.key,
    required this.ctrl,
    required this.rowCountWithGhost,
    required this.hasLeading,
    required this.hasTrailing,
    required this.gutterWidth,
    required this.leadingWidth,
    required this.mainGridWidth,
    required this.trailingTotalWidth,
    required this.trailingCols,
    required this.cellPad,
    required this.rowHeight,
    required this.gap,
    required this.bottomScrollGap,
    required this.useExternalVScroll,
    required this.vGutterCtrl,
    required this.vGridCtrl,
    required this.hGridCtrl,
    required this.editRow,
    required this.editCol,
    required this.cellController,
    required this.cellFocus,
    required this.onStartEdit,
    required this.onCommitEdit,
    required this.vPhysics,
    required this.leadingHeaderBuilder,
    required this.leadingCellBuilder,
    required this.rowStyleResolver,
    required this.trailingRowBuilder,
  });

  final bc.MagicTableController ctrl;
  final int rowCountWithGhost;

  final bool hasLeading;
  final bool hasTrailing;

  final double gutterWidth;
  final double leadingWidth;
  final double mainGridWidth;
  final double trailingTotalWidth;

  final List<TrailingColMeta> trailingCols;

  final EdgeInsets cellPad;
  final double rowHeight;
  final double gap;
  final double bottomScrollGap;

  final bool useExternalVScroll;

  final ScrollController vGutterCtrl;
  final ScrollController vGridCtrl;
  final ScrollController hGridCtrl;

  final int? editRow;
  final int? editCol;
  final TextEditingController cellController;
  final FocusNode cellFocus;

  final void Function(int r, int c) onStartEdit;
  final VoidCallback onCommitEdit;

  final ScrollPhysics? vPhysics;

  final Widget Function(BuildContext context)? leadingHeaderBuilder;
  final Widget Function(BuildContext context, int row)? leadingCellBuilder;
  final RowStyleResolver rowStyleResolver;
  final TrailingRowBuilder? trailingRowBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // GUTTER
        SizedBox(
          width: gutterWidth,
          child: MagicGutterColumn(
            addTopBorder: true, // ✅
            ctrl: ctrl,
            vGutterCtrl: vGutterCtrl,
            rowHeight: rowHeight,
            rowCountWithGhost: rowCountWithGhost,
            bottomScrollGap: bottomScrollGap,
            onAddRow: null,
          ),
        ),
        SizedBox(width: gap),

        // LEADING
        if (hasLeading)
          SizedBox(
            width: leadingWidth,
            child: useExternalVScroll
                ? MagicLeadingColumn(
              rowCount: ctrl.rowCount,
              rowHeight: rowHeight,
              bottomScrollGap: bottomScrollGap,
              leadingHeaderBuilder: leadingHeaderBuilder,
              leadingCellBuilder: leadingCellBuilder,
              rowStyleResolver: rowStyleResolver,
            )
                : SingleChildScrollView(
              controller: vGridCtrl,
              child: MagicLeadingColumn(
                rowCount: ctrl.rowCount,
                rowHeight: rowHeight,
                bottomScrollGap: bottomScrollGap,
                leadingHeaderBuilder: leadingHeaderBuilder,
                leadingCellBuilder: leadingCellBuilder,
                rowStyleResolver: rowStyleResolver,
              ),
            ),
          ),
        if (hasLeading) SizedBox(width: gap),

        // GRID + TRAILING com scroller horizontal único
        Expanded(
          child: SingleChildScrollView(
            controller: hGridCtrl,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: mainGridWidth,
                  child: MagicGridBody(
                    ctrl: ctrl,
                    vGridCtrl: vGridCtrl,
                    hGridCtrl: hGridCtrl,
                    rowHeight: rowHeight,
                    cellPad: cellPad,
                    editRow: editRow,
                    editCol: editCol,
                    cellController: cellController,
                    cellFocus: cellFocus,
                    onStartEdit: onStartEdit,
                    onCommitEdit: onCommitEdit,
                    bottomScrollGap: bottomScrollGap,
                    rightScrollGap: 0,
                    useExternalHScroll: true,
                    useExternalVScroll: useExternalVScroll,
                    vPhysics: useExternalVScroll ? const NeverScrollableScrollPhysics() : vPhysics,
                  ),
                ),

                if (hasTrailing)
                  SizedBox(
                    width: trailingTotalWidth,
                    child: Column(
                      children: [
                        MagicTrailingHeader(
                          trailingCols: trailingCols,
                          rowHeight: rowHeight,
                          cellPad: cellPad,
                        ),
                        if (useExternalVScroll)
                          MagicTrailingColumn(
                            rowCount: ctrl.rowCount,
                            rowHeight: rowHeight,
                            bottomScrollGap: bottomScrollGap,
                            trailingCols: trailingCols,
                            trailingRowBuilder: trailingRowBuilder,
                            cellPad: cellPad,
                            rowStyleResolver: rowStyleResolver,
                          )
                        else
                          Expanded(
                            child: SingleChildScrollView(
                              controller: vGridCtrl,
                              child: MagicTrailingColumn(
                                rowCount: ctrl.rowCount,
                                rowHeight: rowHeight,
                                bottomScrollGap: bottomScrollGap,
                                trailingCols: trailingCols,
                                trailingRowBuilder: trailingRowBuilder,
                                cellPad: cellPad,
                                rowStyleResolver: rowStyleResolver,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
