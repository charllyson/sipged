// lib/_widgets/table/magic/magic_bands_footer_totals_grouped.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;

class MagicBandsFooterTotalsGrouped extends StatelessWidget {
  const MagicBandsFooterTotalsGrouped({
    super.key,
    required this.ctrl,
    this.height = 36,
    this.cellPad = const EdgeInsets.symmetric(horizontal: 12),
    this.labelTotais = 'TOTAIS',
    this.rightScrollGap = 0,
    this.groupLabelForFirstCell = 'CONTRATO', // onde escrever "TOTAIS"
    this.showGroupBackground = true,
  });

  final bc.MagicTableController ctrl;
  final double height;
  final EdgeInsets cellPad;
  final String labelTotais;
  final double rightScrollGap;

  /// Se existir um grupo com esse nome, "TOTAIS" ficará na 1ª coluna desse grupo.
  /// Caso não exista, cai para a 1ª coluna da tabela.
  final String groupLabelForFirstCell;

  /// Se true, aplica um leve cinza nas colunas de um mesmo grupo (sutil).
  final bool showGroupBackground;

  bool _isNumeric(int c) => ctrl.isNumericEffective(c);

  bool _isMoney(int c) {
    if (ctrl.hasSchema) {
      return c >= 0 &&
          c < ctrl.columns.length &&
          ctrl.columns[c].type == bc.ColumnType.money;
    }
    return c >= 0 &&
        c < ctrl.colTypes.length &&
        ctrl.colTypes[c] == bc.ColumnType.money;
  }

  double _sumColumn(int c) {
    double acc = 0;
    for (int r = 1; r < ctrl.tableData.length; r++) {
      if (c < ctrl.tableData[r].length) {
        acc += ctrl.parseBR(ctrl.tableData[r][c]) ?? 0.0;
      }
    }
    return acc;
  }

  @override
  Widget build(BuildContext context) {
    if (!ctrl.hasData) return const SizedBox.shrink();

    // Descobre intervalo (start..end) de cada grupo contíguo
    final groups = <_GroupSlice>[];
    String? curr;
    int start = 0;

    String? groupOf(int c) {
      if (ctrl.hasSchema && c < ctrl.columns.length) {
        return ctrl.columns[c].group;
      }
      // Fallback: sem schema → tudo vira um único "grupo" virtual
      return null;
    }

    for (int c = 0; c < ctrl.colCount; c++) {
      final g = groupOf(c);
      if (c == 0) {
        curr = g;
        start = 0;
      } else {
        if (g != curr) {
          groups.add(_GroupSlice(group: curr, start: start, endInclusive: c - 1));
          curr = g;
          start = c;
        }
      }
    }
    groups.add(_GroupSlice(group: curr, start: start, endInclusive: ctrl.colCount - 1));

    // Encontra o grupo onde queremos imprimir "TOTAIS"
    _GroupSlice? groupForLabel = groups.firstWhere(
          (g) => (g.group ?? '').toUpperCase().trim() == groupLabelForFirstCell.toUpperCase().trim(),
      orElse: () => groups.first,
    );

    final rowChildren = <Widget>[];

    for (int c = 0; c < ctrl.colCount; c++) {
      final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;
      final isNum = _isNumeric(c);
      final isMoney = _isMoney(c);

      final sum = isNum ? _sumColumn(c) : 0.0;
      final text = isNum
          ? (isMoney ? ctrl.formatMoneyBR(sum)
          : ctrl.formatNumberBR(sum, decimals: 2, trimZeros: false))
          : '';

      // Checa se esta coluna é a 1ª do grupo escolhido para escrever "TOTAIS"
      final isFirstColumnOfTotalsGroup = (c == groupForLabel.start);

      String finalText = text;
      TextAlign align = TextAlign.left;
      if (isFirstColumnOfTotalsGroup) {
        finalText = labelTotais;
        align = TextAlign.left;
      } else if (isNum) {
        align = TextAlign.right;
      }

      // Define se aplica um leve bg por grupo (apenas cosmético)
      final parentGroup = groups.firstWhere((g) => g.contains(c));
      final bg = showGroupBackground && parentGroup.group != null
          ? Colors.grey.shade100
          : Colors.grey.shade50;

      final isLast = (c == ctrl.colCount - 1);

      rowChildren.add(
        Container(
          width: w,
          height: height,
          alignment: (align == TextAlign.right)
              ? Alignment.centerRight
              : Alignment.centerLeft,
          padding: cellPad,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
              top: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
              right: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            finalText,
            textAlign: align,
            style: TextStyle(
              fontWeight: isFirstColumnOfTotalsGroup ? FontWeight.w700 : FontWeight.w600,
            ),
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (rightScrollGap > 0) {
      rowChildren.add(SizedBox(width: rightScrollGap, height: height));
    }

    return Row(children: rowChildren);
  }
}

class _GroupSlice {
  final String? group;
  final int start;
  final int endInclusive;

  const _GroupSlice({required this.group, required this.start, required this.endInclusive});

  bool contains(int c) => c >= start && c <= endInclusive;
}
