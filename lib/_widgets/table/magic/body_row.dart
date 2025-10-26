import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'gutter_column.dart';
import 'leading_column.dart';
import 'grid_body.dart';

typedef RowStyleResolver = ({Color bg, TextStyle text}) Function(int r);

class MagicBodyRow extends StatelessWidget {
  const MagicBodyRow({
    super.key,
    required this.ctrl,
    required this.rowCountWithGhost,
    required this.hasLeading,
    required this.gutterWidth,
    required this.leadingWidth,
    required this.mainGridWidth,
    required this.cellPad,
    required this.rowHeight,
    required this.gap,
    required this.bottomScrollGap,
    required this.useExternalVScroll,
    required this.useExternalHScroll, // << novo
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
  });

  final bc.MagicTableController ctrl;
  final int rowCountWithGhost;
  final bool hasLeading;

  final double gutterWidth;
  final double leadingWidth;
  final double mainGridWidth;

  final EdgeInsets cellPad;
  final double rowHeight;
  final double gap;
  final double bottomScrollGap;

  final bool useExternalVScroll;
  final bool useExternalHScroll;

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

  @override
  Widget build(BuildContext context) {
    final bodyGrid = SizedBox(
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
        useExternalHScroll: useExternalHScroll, // << respeita H externo
        useExternalVScroll: useExternalVScroll,
        vPhysics: useExternalVScroll ? const NeverScrollableScrollPhysics() : vPhysics,
      ),
    );

    return Row(
      children: [
        // GUTTER (com V scroll sincronizado externamente)
        SizedBox(
          width: gutterWidth,
          child: MagicGutterColumn(
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

        // GRID
        if (useExternalHScroll)
          bodyGrid
        else
          Expanded(
            child: SingleChildScrollView(
              controller: hGridCtrl,
              scrollDirection: Axis.horizontal,
              child: bodyGrid,
            ),
          ),
      ],
    );
  }
}
