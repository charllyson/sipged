import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;

class MagicGridBody extends StatelessWidget {
  const MagicGridBody({
    super.key,
    required this.ctrl,
    required this.vGridCtrl,
    required this.hGridCtrl,
    required this.rowHeight,
    required this.cellPad,
    required this.editRow,
    required this.editCol,
    required this.cellController,
    required this.cellFocus,
    required this.onStartEdit,
    required this.onCommitEdit,
    this.bottomScrollGap = 0,
    this.rightScrollGap = 0,
  });

  final bc.MagicTableController ctrl;
  final ScrollController vGridCtrl;
  final ScrollController hGridCtrl;

  final double rowHeight;
  final EdgeInsets cellPad;

  final int? editRow;
  final int? editCol;
  final TextEditingController cellController;
  final FocusNode cellFocus;

  final void Function(int r, int c) onStartEdit;
  final VoidCallback onCommitEdit;

  final double bottomScrollGap;
  final double rightScrollGap;

  bool _isUpperCase(String v) {
    final only = v.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    return only.isNotEmpty && only == only.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: vGridCtrl,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        controller: hGridCtrl,
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            ...List.generate(ctrl.rowCount, (r) {
              final isFirstRow = r == 0;
              final firstCol = ctrl.tableData[r].isNotEmpty ? ctrl.tableData[r][0] : '';
              final secondCol = ctrl.tableData[r].length > 1 ? ctrl.tableData[r][1] : '';
              final isIntegerRow = !isFirstRow && int.tryParse(firstCol) != null;
              final isUpperCaseRow = !isFirstRow && _isUpperCase(secondCol);

              final isEditingRow = (editRow != null && editRow == r);

              final baseBg = isFirstRow
                  ? const Color(0xFF091D68)
                  : isIntegerRow
                  ? Colors.grey.shade200
                  : isUpperCaseRow
                  ? Colors.grey.shade100
                  : Colors.white;

              final baseText = isFirstRow
                  ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  : isIntegerRow
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : isUpperCaseRow
                  ? const TextStyle(fontStyle: FontStyle.italic)
                  : const TextStyle();

              return Row(
                children: [
                  ...List.generate(ctrl.colCount, (c) {
                    final cell = (c < ctrl.tableData[r].length) ? ctrl.tableData[r][c] : '';
                    final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;
                    final isHeaderCell = isFirstRow;
                    final isNumericCol = !isHeaderCell && ctrl.isNumericEffective(c);
                    final canEdit = !isHeaderCell && ctrl.isEditable(c);
                    final isEditing = canEdit && (editRow == r && editCol == c);

                    final textAlign = isHeaderCell
                        ? TextAlign.center
                        : (isNumericCol ? TextAlign.right : TextAlign.left);

                    // fundo: mantém lógica existente, mas destaca read-only
                    final rowBg = (!isFirstRow && isEditingRow)
                        ? Colors.yellow.shade100
                        : baseBg;

                    // 🔧 NÃO mude a cor de linhas especiais (ex.: subtotal em cinza 200).
                    // Aplique cinza clarinho apenas quando a linha teria fundo branco.
                    final bool isReadOnly = !isHeaderCell && !canEdit;
                    final cellBg = (isReadOnly && rowBg == Colors.white)
                        ? Colors.grey.shade50   // destaque leve só em linhas "normais"
                        : rowBg;


                    final content = isEditing
                        ? TextField(
                      controller: cellController,
                      focusNode: cellFocus,
                      autofocus: true,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: textAlign,
                      maxLines: 1,
                      keyboardType: isNumericCol
                          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                          : TextInputType.text,
                      inputFormatters: isNumericCol
                          ? <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\-\sRr\$]')),
                      ]
                          : null,
                      onSubmitted: (_) => onCommitEdit(),
                      onTapOutside: (_) => onCommitEdit(),
                      style: baseText,
                    )
                        : Text(cell, softWrap: true, textAlign: textAlign, style: baseText);

                    final cellBox = Container(
                      width: w,
                      height: rowHeight,
                      alignment: isHeaderCell
                          ? Alignment.center
                          : (isNumericCol ? Alignment.centerRight : Alignment.centerLeft),
                      padding: cellPad,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: cellBg,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300, width: 1),
                          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      child: content,
                    );

                    Widget clickable = cellBox;

                    // tooltip para células bloqueadas
                    if (isReadOnly) {
                      clickable = Tooltip(
                        message: 'Valor gerado automaticamente.',
                        waitDuration: const Duration(milliseconds: 300),
                        child: cellBox,
                      );
                    }

                    if (!isEditing) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: canEdit ? () => onStartEdit(r, c) : null,
                        onDoubleTap: canEdit ? () => onStartEdit(r, c) : null,
                        child: clickable,
                      );
                    } else {
                      return clickable;
                    }
                  }),
                  SizedBox(width: rightScrollGap, height: rowHeight),
                ],
              );
            }),
            SizedBox(height: bottomScrollGap),
          ],
        ),
      ),
    );
  }
}
