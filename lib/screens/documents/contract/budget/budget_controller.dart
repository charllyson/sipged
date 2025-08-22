import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipos de coluna configuráveis (fonte única do enum)
enum ColumnType { auto, text, number, money, boolean_, date }

class BudgetController extends ChangeNotifier {
  BudgetController({required this.cellPadHorizontal});

  // --------- Estado dos dados/colunas ----------
  List<List<String>> tableData = [];
  List<double> colWidths = [];
  List<bool> numericCols = [];
  List<ColumnType> colTypes = [];

  // --------- Constantes de layout/largura ----------
  static const double minColWidth = 80;
  static const double maxColWidthNonNumeric = 380;
  final double cellPadHorizontal;

  // --------- PROPRIEDADES P/ UI ----------
  int get rowCount => tableData.isEmpty ? 0 : tableData.length;
  int get colCount => tableData.isEmpty ? 0 : tableData.first.length;
  bool get hasData => tableData.isNotEmpty;

  // --------- COLAR DO EXCEL ----------
  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null || raw.trim().isEmpty) return;

    final rows = raw.trimRight().split('\n').map((r) => r.split('\t')).toList();

    tableData = rows;
    colTypes = List.generate(_getColCount(rows), (_) => ColumnType.auto);
    numericCols = List.generate(colTypes.length, (c) => isNumericEffective(c, rows));
    colWidths = computeColWidths(rows);
    notifyListeners();
  }

  String excelColName(int index) {
    int n = index;
    String name = '';
    while (n >= 0) {
      name = String.fromCharCode((n % 26) + 65) + name;
      n = (n ~/ 26) - 1;
    }
    return name;
  }

  String typeBadge(ColumnType t) {
    switch (t) {
      case ColumnType.money:    return '\$';
      case ColumnType.date:     return 'D';
      case ColumnType.text:     return 'T';
      case ColumnType.number:   return 'N';
      case ColumnType.boolean_: return 'B';
      case ColumnType.auto:     return '+';
    }
  }

  // Coluna numérica efetiva (respeita tipo escolhido; senão auto)
  bool isNumericEffective(int col, [List<List<String>>? rows]) {
    if (col < colTypes.length) {
      final t = colTypes[col];
      if (t == ColumnType.number || t == ColumnType.money) return true;
      if (t == ColumnType.text || t == ColumnType.boolean_ || t == ColumnType.date) return false;
    }
    final src = rows ?? tableData;
    if (src.isEmpty) return false;
    return _isNumericColumnAuto(src, col);
  }

  // Auto-ajuste de largura para a coluna c
  double autoFitColWidth(int c) {
    final maxW = isNumericEffective(c) ? double.infinity : maxColWidthNonNumeric;
    double w = minColWidth;

    bool isFirstRow(int r) => r == 0;
    bool isIntegerRow(int r) =>
        !isFirstRow(r) && tableData[r].isNotEmpty && int.tryParse(tableData[r][0]) != null;
    bool isUpperCaseRow(int r) {
      if (isFirstRow(r) || tableData[r].length < 2) return false;
      final s = tableData[r][1];
      final only = s.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
      return only.isNotEmpty && only == only.toUpperCase();
    }

    for (var r = 0; r < tableData.length; r++) {
      final txt = (c < tableData[r].length) ? tableData[r][c] : '';
      final style = isFirstRow(r)
          ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          : isIntegerRow(r)
          ? const TextStyle(fontWeight: FontWeight.bold)
          : isUpperCaseRow(r)
          ? const TextStyle(fontStyle: FontStyle.italic)
          : const TextStyle();
      final needed = _measureCellWidth(txt, style);
      if (needed > w) w = needed;
      if (w >= maxW) { w = maxW; break; }
    }
    return w;
  }

  // Recalcula larguras respeitando tipos
  List<double> computeColWidths(List<List<String>> rows) {
    final colCount = _getColCount(rows);
    if (colCount == 0) return [];

    final result = List<double>.filled(colCount, minColWidth);
    const textStyle = TextStyle();
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);
    const italicStyle = TextStyle(fontStyle: FontStyle.italic);

    bool isFirstRow(int r) => r == 0;
    bool isIntegerRow(int r) =>
        !isFirstRow(r) && rows[r].isNotEmpty && int.tryParse(rows[r][0]) != null;
    bool isUpperCaseRow(int r) {
      if (isFirstRow(r) || rows[r].length < 2) return false;
      final s = rows[r][1];
      final onlyLetters = s.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
      return onlyLetters.isNotEmpty && onlyLetters == onlyLetters.toUpperCase();
    }

    final hasTypes = colTypes.length == colCount;

    for (var c = 0; c < colCount; c++) {
      final numeric = hasTypes ? isNumericEffective(c, rows) : _isNumericColumnAuto(rows, c);
      final maxW = numeric ? double.infinity : maxColWidthNonNumeric;
      double maxWidth = minColWidth;

      for (var r = 0; r < rows.length; r++) {
        final txt = (c < rows[r].length) ? rows[r][c] : '';
        final style = isFirstRow(r)
            ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            : isIntegerRow(r)
            ? boldStyle
            : isUpperCaseRow(r)
            ? italicStyle
            : textStyle;

        final needed = _measureCellWidth(txt, style);
        if (needed > maxWidth) maxWidth = needed;
        if (maxWidth > maxW) { maxWidth = maxW; break; }
      }
      if (maxWidth < minColWidth) maxWidth = minColWidth;
      result[c] = maxWidth;
    }
    return result;
  }

  // --------- Serialização/Carregamento no Controller ----------
  List<String> get headers =>
      hasData ? List<String>.from(tableData.first) : <String>[];

  List<String> get colTypesAsString =>
      colTypes.map((t) => t.name).toList();

  Map<String, dynamic> toMetaMap() => {
    'headers': headers,
    'colTypes': colTypesAsString,
    'colWidths': colWidths,
    'version': 1,
  };

  List<List<String>> get rowsWithoutHeader =>
      hasData ? tableData.sublist(1) : <List<String>>[];

  void loadFromSnapshot({
    required List<List<String>> table,
    required List<String> colTypesAsString,
    required List<double> widths,
  }) {
    tableData = table;
    colTypes = colTypesAsString.map((s) {
      switch (s) {
        case 'text': return ColumnType.text;
        case 'number': return ColumnType.number;
        case 'money': return ColumnType.money;
        case 'boolean_': return ColumnType.boolean_;
        case 'date': return ColumnType.date;
        case 'auto':
        default: return ColumnType.auto;
      }
    }).toList();

    colWidths = widths;
    numericCols = List.generate(colTypes.length, (c) => isNumericEffective(c, tableData));
    notifyListeners();
  }

  // --------- Ações de tipo/edição ----------
  void setColumnType(int colIndex, ColumnType selected) {
    if (colIndex < 0 || colIndex >= colCount) return;
    colTypes[colIndex] = selected;
    _convertColumnValues(colIndex, selected);
    numericCols = List.generate(colCount, (c) => isNumericEffective(c));
    colWidths = computeColWidths(tableData);
    notifyListeners();
  }

  String normalizeValueOnCommit(int col, String raw) {
    String value = raw;
    if (col < 0 || col >= colCount) return value;

    switch (colTypes[col]) {
      case ColumnType.money:
        final d = _parseBR(raw);
        if (d != null) value = _formatMoneyBR(d);
        break;
      case ColumnType.number:
        final d2 = _parseBR(raw);
        if (d2 != null) value = _formatNumberBR(d2, decimals: 2, trimZeros: true);
        break;
      case ColumnType.boolean_:
        final v = raw.toLowerCase();
        if (['true', 't', 'sim', 's', '1'].contains(v)) value = 'true';
        else if (['false', 'f', 'nao', 'não', 'n', '0'].contains(v)) value = 'false';
        break;
      case ColumnType.date:
        DateTime? dt;
        try {
          if (raw.contains('/')) {
            final p = raw.split('/');
            if (p.length == 3) {
              final d = int.tryParse(p[0]);
              final m = int.tryParse(p[1]);
              final y = int.tryParse(p[2]);
              if (d != null && m != null && y != null) dt = DateTime(y, m, d);
            }
          } else if (raw.contains('-')) {
            dt = DateTime.tryParse(raw);
          }
        } catch (_) {}
        if (dt != null) {
          final dd = dt.day.toString().padLeft(2, '0');
          final mm = dt.month.toString().padLeft(2, '0');
          final yy = dt.year.toString();
          value = '$dd/$mm/$yy';
        }
        break;
      case ColumnType.text:
      case ColumnType.auto:
        break;
    }
    return value;
  }

  void setCellValue(int row, int col, String value) {
    if (row < 0) return;
    if (row >= tableData.length) {
      tableData = [
        ...tableData,
        for (int i = tableData.length; i <= row; i++) <String>[]
      ];
    }
    if (col >= tableData[row].length) {
      tableData[row] = [...tableData[row], for (int i = tableData[row].length; i <= col; i++) ''];
    }
    tableData[row][col] = value;

    numericCols = List.generate(colCount, (i) => isNumericEffective(i));
    colWidths = computeColWidths(tableData);
    notifyListeners();
  }

  // --------- Helpers (detecção/format) ----------
  bool _isNumericBR(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    final re = RegExp(r'^\d{1,3}(\.\d{3})*(,\d+)?$|^\d+(,\d+)?$');
    return re.hasMatch(v);
  }

  double? _parseBR(String s) {
    final cleaned = s.replaceAll(RegExp(r'[Rr]\$'), '').replaceAll(RegExp(r'[^0-9,.\-]'), '').trim();
    final canonical = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(canonical);
  }

  String _formatThousands(String intPart) {
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idx = intPart.length - i - 1;
      buf.write(intPart[idx]);
      if (i % 3 == 2 && idx != 0) buf.write('.');
    }
    return buf.toString().split('').reversed.join();
  }

  String _formatMoneyBR(double d) {
    final isNeg = d < 0;
    final v = d.abs();
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = _formatThousands(parts[0]);
    final dec = parts[1];
    return '${isNeg ? '-R\$ ' : 'R\$ '}$intPart,$dec';
  }

  String _formatNumberBR(double d, {int decimals = 2, bool trimZeros = true}) {
    final neg = d < 0;
    final v = d.abs();
    String s = v.toStringAsFixed(decimals);
    if (trimZeros) s = s.replaceFirst(RegExp(r'\.?0*$'), '');
    if (!s.contains('.')) return (neg ? '-' : '') + _formatThousands(s);
    final parts = s.split('.');
    return '${neg ? '-' : ''}${_formatThousands(parts[0])},${parts[1]}';
  }

  bool _isNumericColumnAuto(List<List<String>> rows, int colIndex) {
    for (var r = 1; r < rows.length; r++) {
      if (colIndex >= rows[r].length) continue;
      final cell = rows[r][colIndex].trim();
      if (cell.isEmpty) continue;
      if (!_isNumericBR(cell)) return false;
    }
    return true;
  }

  double _measureCellWidth(String txt, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: txt, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width + cellPadHorizontal;
  }

  int _getColCount(List<List<String>> rows) =>
      rows.map((r) => r.length).fold<int>(0, (m, l) => l > m ? l : m);

  void _convertColumnValues(int col, ColumnType t) {
    if (tableData.isEmpty) return;
    for (int r = 1; r < tableData.length; r++) {
      if (col >= tableData[r].length) continue;
      final raw = tableData[r][col].trim();
      if (raw.isEmpty) continue;

      switch (t) {
        case ColumnType.money:
          final d = _parseBR(raw);
          if (d != null) tableData[r][col] = _formatMoneyBR(d);
          break;
        case ColumnType.number:
          final d2 = _parseBR(raw);
          if (d2 != null) tableData[r][col] = _formatNumberBR(d2, decimals: 2, trimZeros: true);
          break;
        case ColumnType.boolean_:
          final v = raw.toLowerCase();
          if (['true', 't', 'sim', 's', '1'].contains(v)) {
            tableData[r][col] = 'true';
          } else if (['false', 'f', 'nao', 'não', 'n', '0'].contains(v)) {
            tableData[r][col] = 'false';
          }
          break;
        case ColumnType.date:
          DateTime? dt;
          try {
            if (raw.contains('/')) {
              final p = raw.split('/');
              if (p.length == 3) {
                final d = int.tryParse(p[0]);
                final m = int.tryParse(p[1]);
                final y = int.tryParse(p[2]);
                if (d != null && m != null && y != null) dt = DateTime(y, m, d);
              }
            } else if (raw.contains('-')) {
              dt = DateTime.tryParse(raw);
            }
          } catch (_) {}
          if (dt != null) {
            final dd = dt.day.toString().padLeft(2, '0');
            final mm = dt.month.toString().padLeft(2, '0');
            final yy = dt.year.toString();
            tableData[r][col] = '$dd/$mm/$yy';
          }
          break;
        case ColumnType.text:
        case ColumnType.auto:
          break;
      }
    }
  }
}
