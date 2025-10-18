import 'package:flutter/material.dart';
import 'magic_table_controller.dart' as bc;
import 'type_badge_button.dart';

/// Cabeçalho de letras (A..Z) com suporte a colunas extras (painel direito)
/// Pode usar o PRÓPRIO scroll interno (padrão) ou um scroll EXTERNO
/// quando [useExternalHScroll] = true.
class MagicHeaderRow extends StatelessWidget {
  const MagicHeaderRow({
    super.key,
    required this.ctrl,
    required this.hHeaderCtrl,
    required this.headerHeight,

    this.ghostColWidth = 48,
    this.rightScrollGap = 0,

    this.onAddColumn,
    this.onRemoveColumn,

    this.allowAddColumn = true,
    this.allowRemoveColumn = true,
    this.showTypeBadge = true,

    this.extraCount = 0,
    this.extraWidth,
    this.extraLabel,

    this.useExternalHScroll = false,

    /// Quando true, desenha a borda superior do header.
    /// Útil quando NÃO há a faixa de “bandas” acima.
    this.addTopBorder = false,
  });

  final bc.MagicTableController ctrl;
  final ScrollController hHeaderCtrl;
  final double headerHeight;
  final double ghostColWidth;
  final double rightScrollGap;

  final VoidCallback? onAddColumn;
  final void Function(int col)? onRemoveColumn;

  final bool allowAddColumn;
  final bool allowRemoveColumn;
  final bool showTypeBadge;

  final int extraCount;
  final double Function(int i)? extraWidth;
  final String Function(int i)? extraLabel;

  /// Quando true, NÃO cria `SingleChildScrollView` interno.
  final bool useExternalHScroll;

  /// Quando true, pinta a borda superior do header.
  final bool addTopBorder;

  static const double _resizeHandleWidth = 8;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];

    final topBorder = addTopBorder
        ? BorderSide(color: Colors.grey.shade300, width: 1)
        : BorderSide.none;

    // ====== GRID PRINCIPAL (A..)
    for (int c = 0; c < ctrl.colCount; c++) {
      final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;
      final hasType =
          (c < ctrl.colTypes.length) && ctrl.colTypes[c] != bc.ColumnType.auto;

      final isLastMain = c == ctrl.colCount - 1;
      final showRightBorderOnMain = !(isLastMain && extraCount == 0);

      cells.add(
        Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Container(
              width: w,
              height: headerHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: topBorder, // ✅ borda superior opcional
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: showRightBorderOnMain
                      ? BorderSide(color: Colors.grey.shade300, width: 1)
                      : BorderSide.none,
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
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

            // handle de resize
            Positioned(
              right: 0,
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
                    final next = (ctrl.colWidths[c] + details.delta.dx)
                        .clamp(bc.MagicTableController.minColWidth, maxW)
                        .toDouble();
                    ctrl.colWidths[c] = next;
                    ctrl.notifyListeners();
                  },
                  onDoubleTap: () {
                    ctrl.colWidths[c] = ctrl.autoFitColWidth(c);
                    ctrl.notifyListeners();
                  },
                ),
              ),
            ),

            if (showTypeBadge)
              Positioned(
                top: 4,
                right: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: TypeBadgeButton(
                      hasType: hasType,
                      type: (c < ctrl.colTypes.length)
                          ? ctrl.colTypes[c]
                          : bc.ColumnType.auto,
                      onSelected: (t) => ctrl.setColumnType(c, t),
                      onRemove: (allowRemoveColumn && onRemoveColumn != null)
                          ? () => onRemoveColumn!(c)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ====== EXTRAS (PAINEL DIREITO)
    for (int i = 0; i < extraCount; i++) {
      final w = (extraWidth != null) ? extraWidth!(i) : 120.0;
      final label = (extraLabel != null)
          ? extraLabel!(i)
          : ctrl.excelColName(ctrl.colCount + i);
      final isLastExtra = i == extraCount - 1;

      cells.add(
        Container(
          width: w,
          height: headerHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              top: topBorder, // ✅ borda superior opcional
              left: BorderSide(color: Colors.grey.shade300, width: 1),
              right: isLastExtra
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // “+ coluna”
    if (allowAddColumn && onAddColumn != null && ghostColWidth > 0) {
      cells.add(
        SizedBox(
          width: ghostColWidth,
          height: headerHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: topBorder, // ✅ borda superior opcional
                left: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddColumn,
                child: const Center(child: Icon(Icons.add, size: 18)),
              ),
            ),
          ),
        ),
      );
    }

    if (rightScrollGap > 0) {
      cells.add(
        SizedBox(
          width: rightScrollGap,
          height: headerHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                top: topBorder, // ✅ borda superior opcional (para continuidade)
              ),
            ),
          ),
        ),
      );
    }

    final content = Row(children: cells);

    // 🔹 Se o scroll é externo, devolve só o Row
    if (useExternalHScroll) return content;

    // 🔹 Caso contrário, cria o scroller interno
    return SingleChildScrollView(
      controller: hHeaderCtrl,
      scrollDirection: Axis.horizontal,
      child: content,
    );
  }
}
