import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ColumnType { auto, text, number, money, boolean_, date }

typedef ComputeCell = String Function(int row, List<String> rowValues, MagicTableController ctrl);

class ColumnMeta {
  final String key;
  final String title;
  final ColumnType type;
  final bool editable;
  final ComputeCell? compute;
  final String? group;
  final String Function(String raw)? normalizeOnCommit;
  final String Function(String raw)? formatter;

  const ColumnMeta({
    required this.key,
    required this.title,
    this.type = ColumnType.text,
    this.editable = true,
    this.compute,
    this.group,
    this.normalizeOnCommit,
    this.formatter,
  });
}

class MagicTableController extends ChangeNotifier {
  MagicTableController({required this.cellPadHorizontal});

  List<List<String>> tableData = [];
  List<double> colWidths = [];
  List<bool> numericCols = [];
  List<ColumnType> colTypes = [];

  List<ColumnMeta>? _schema;
  bool get hasSchema => _schema != null && _schema!.isNotEmpty;
  List<ColumnMeta> get columns => _schema ?? _columnsFromHeader();

  Map<int,double> previousQtyByRow = {};
  Map<int,double> previousValByRow = {};

  static const double minColWidth = 80;
  static const double maxColWidthNonNumeric = 380;
  final double cellPadHorizontal;

  int get rowCount => tableData.isEmpty ? 0 : tableData.length;
  int get colCount => tableData.isEmpty ? 0 : tableData.first.length;
  bool get hasData => tableData.isNotEmpty;

  int colIndexByKey(String key) => columns.indexWhere((c) => c.key == key);
  bool isDerived(int col) => hasSchema && col >= 0 && col < columns.length && columns[col].compute != null;
  bool isEditable(int col) => !hasSchema ? true : (col >= 0 && col < columns.length ? columns[col].editable && columns[col].compute == null : true);

  void setSchema({
    required List<ColumnMeta> schema,
    Map<int,double>? previousQty,
    Map<int,double>? previousVal,
    bool setHeaderFromSchema = true,
  }) {
    _schema = List<ColumnMeta>.from(schema);
    if (previousQty != null) previousQtyByRow = Map<int,double>.from(previousQty);
    if (previousVal != null) previousValByRow = Map<int,double>.from(previousVal);

    if (tableData.isEmpty) tableData = [<String>[]];
    final cc = _schema!.length;

    if (setHeaderFromSchema) {
      final header = _schema!.map((c) => c.title).toList();
      if (tableData.isEmpty) {
        tableData = [header];
      } else {
        if (tableData.first.length < cc) {
          final fixed = List<String>.from(tableData.first, growable: true)
            ..addAll(List.filled(cc - tableData.first.length, ''));
          fixed.setAll(0, header);
          tableData[0] = fixed;
        } else {
          tableData[0] = List<String>.from(header);
        }
      }
    } else {
      if (tableData.first.length < cc) {
        tableData[0] = [...tableData.first, ...List<String>.filled(cc - tableData.first.length, '')];
      }
    }

    for (int r = 0; r < tableData.length; r++) {
      if (tableData[r].length < cc) {
        tableData[r] = [...tableData[r], ...List<String>.filled(cc - tableData[r].length, '')];
      } else if (tableData[r].length > cc) {
        tableData[r] = List<String>.from(tableData[r].take(cc));
      }
    }

    colTypes = _schema!.map((m) => m.type).toList(growable: true);
    recomputeAll();
    _syncAfterShapeChange();
    notifyListeners();
  }

  /// Acrescenta colunas **à direita**
  void appendColumns(List<ColumnMeta> metas) {
    if (metas.isEmpty) return;

    if (!hasData) {
      setSchema(schema: metas, setHeaderFromSchema: true);
      return;
    }

    if (!hasSchema) {
      final legacy = _columnsFromHeader();
      _schema = [...legacy, ...metas];
    } else {
      _schema = [...columns, ...metas];
    }

    // 1) Header
    tableData[0] = [...tableData[0], ...metas.map((m) => m.title)];

    // 2) Linhas
    for (int r = 1; r < tableData.length; r++) {
      tableData[r] = [...tableData[r], ...List<String>.filled(metas.length, '')];
    }

    // 3) Tipos
    colTypes = _schema!.map((m) => m.type).toList(growable: true);

    // 4) Recalcula
    recomputeAll();
    colWidths = computeColWidths(tableData);
    numericCols = List<bool>.generate(colCount, (i) => isNumericEffective(i), growable: true);
    notifyListeners();
  }

  // ====== Operações padrão ======
  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null || raw.trim().isEmpty) return;

    final rows = raw.trimRight().split('\n').map((r) => r.split('\t')).toList();
    final sanitized = rows.map((r) => r.map(_singleLine).toList(growable: true)).toList(growable: true);

    tableData = sanitized;

    if (!hasSchema) {
      colTypes = List<ColumnType>.generate(_getColCount(sanitized), (_) => ColumnType.auto, growable: true);
    } else {
      setSchema(schema: columns, setHeaderFromSchema: false);
    }

    _syncAfterShapeChange();
    notifyListeners();
  }

  String excelColName(int index) {
    int n = index; String name = '';
    while (n >= 0) { name = String.fromCharCode((n % 26) + 65) + name; n = (n ~/ 26) - 1; }
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

  bool isNumericEffective(int col, [List<List<String>>? rows]) {
    if (hasSchema) {
      final t = columns[col].type;
      if (t == ColumnType.number || t == ColumnType.money) return true;
      if (t == ColumnType.text || t == ColumnType.boolean_ || t == ColumnType.date) return false;
    } else if (col < colTypes.length) {
      final t = colTypes[col];
      if (t == ColumnType.number || t == ColumnType.money) return true;
      if (t == ColumnType.text || t == ColumnType.boolean_ || t == ColumnType.date) return false;
    }
    final src = rows ?? tableData;
    if (src.isEmpty) return false;
    return _isNumericColumnAuto(src, col);
  }

  double autoFitColWidth(int c) {
    final maxW = isNumericEffective(c) ? double.infinity : maxColWidthNonNumeric;
    double w = minColWidth;

    bool isFirstRow(int r) => r == 0;
    bool isIntegerRow(int r) => !isFirstRow(r) && tableData[r].isNotEmpty && int.tryParse(tableData[r][0]) != null;
    bool isUpperCaseRow(int r) {
      if (isFirstRow(r) || tableData[r].length < 2) return false;
      final s = tableData[r][1];
      final only = s.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
      return only.isNotEmpty && only == only.toUpperCase();
    }

    for (var r = 0; r < tableData.length; r++) {
      final raw = (c < tableData[r].length) ? tableData[r][c] : '';
      final txt = _singleLine(raw);
      final style = isFirstRow(r)
          ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          : isIntegerRow(r) ? const TextStyle(fontWeight: FontWeight.bold)
          : isUpperCaseRow(r) ? const TextStyle(fontStyle: FontStyle.italic)
          : const TextStyle();
      final needed = _measureCellWidth(txt, style);
      if (needed > w) w = needed;
      if (w >= maxW) { w = maxW; break; }
    }
    return w;
  }

  List<double> computeColWidths(List<List<String>> rows) {
    final colCount = _getColCount(rows);
    if (colCount == 0) return <double>[];
    final result = List<double>.filled(colCount, minColWidth, growable: true);
    const textStyle = TextStyle();
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);
    const italicStyle = TextStyle(fontStyle: FontStyle.italic);

    bool isFirstRow(int r) => r == 0;
    bool isIntegerRow(int r) => !isFirstRow(r) && rows[r].isNotEmpty && int.tryParse(rows[r][0]) != null;
    bool isUpperCaseRow(int r) {
      if (isFirstRow(r) || rows[r].length < 2) return false;
      final s = rows[r][1];
      final only = s.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
      return only.isNotEmpty && only == only.toUpperCase();
    }

    final hasTypes = hasSchema ? true : colTypes.length == colCount;

    for (var c = 0; c < colCount; c++) {
      final numeric = hasTypes ? isNumericEffective(c, rows) : _isNumericColumnAuto(rows, c);
      final maxW = numeric ? double.infinity : maxColWidthNonNumeric;
      double maxWidth = minColWidth;

      for (var r = 0; r < rows.length; r++) {
        final raw = (c < rows[r].length) ? rows[r][c] : '';
        final txt = _singleLine(raw);
        final style = isFirstRow(r)
            ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            : isIntegerRow(r) ? boldStyle
            : isUpperCaseRow(r) ? italicStyle
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

  List<String> get headers => hasData ? List<String>.from(tableData.first) : <String>[];
  List<String> get colTypesAsString => (hasSchema ? columns.map((c) => c.type.name) : colTypes.map((t) => t.name)).toList();

  Map<String, dynamic> toMetaMap() => {'headers': headers, 'colTypes': colTypesAsString, 'colWidths': colWidths, 'version': 1};
  List<List<String>> get rowsWithoutHeader => hasData ? tableData.sublist(1) : <List<String>>[];

  void loadFromSnapshot({
    required List<List<String>> table,
    required List<String> colTypesAsString,
    required List<double> widths,
  }) {
    tableData = table.map((r) => r.map(_singleLine).toList(growable: true)).toList(growable: true);

    if (!hasSchema) {
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
      }).toList(growable: true);
    } else {
      colTypes = columns.map((m) => m.type).toList(growable: true);
    }

    colWidths = List<double>.from(widths, growable: true);

    if (hasSchema) recomputeAll();
    _syncAfterShapeChange();
    notifyListeners();
  }

  void setColumnType(int colIndex, ColumnType selected) {
    if (hasSchema) return;
    if (colIndex < 0 || colIndex >= colCount) return;

    colTypes = List<ColumnType>.from(colTypes, growable: true);
    if (colTypes.length < colCount) {
      colTypes.addAll(List<ColumnType>.filled(colCount - colTypes.length, ColumnType.auto, growable: true));
    }

    colTypes[colIndex] = selected;
    _convertColumnValues(colIndex, selected);
    _syncAfterShapeChange();
    notifyListeners();
  }

  ColumnType _typeAt(int col) {
    if (hasSchema) return columns[col].type;
    if (col < 0) return ColumnType.auto;
    if (col >= colTypes.length) return ColumnType.auto;
    return colTypes[col];
  }

  String normalizeValueOnCommit(int col, String raw) {
    String value = _singleLine(raw);
    if (col < 0 || col >= colCount) return value;

    if (hasSchema && columns[col].normalizeOnCommit != null) {
      return columns[col].normalizeOnCommit!(value);
    }

    switch (_typeAt(col)) {
      case ColumnType.money:
        final d = _parseBR(value); if (d != null) value = _formatMoneyBR(d);
        break;
      case ColumnType.number:
        final d2 = _parseBR(value); if (d2 != null) value = _formatNumberBR(d2, decimals: 2, trimZeros: true);
        break;
      case ColumnType.boolean_:
        final v = value.toLowerCase();
        if (['true','t','sim','s','1'].contains(v)) value = 'true';
        else if (['false','f','nao','não','n','0'].contains(v)) value = 'false';
        break;
      case ColumnType.date:
        DateTime? dt;
        try {
          if (value.contains('/')) {
            final p = value.split('/');
            if (p.length == 3) {
              final d = int.tryParse(p[0]); final m = int.tryParse(p[1]); final y = int.tryParse(p[2]);
              if (d != null && m != null && y != null) dt = DateTime(y, m, d);
            }
          } else if (value.contains('-')) {
            dt = DateTime.tryParse(value);
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
    if (hasSchema && isDerived(col)) return; // bloqueia edição em derivadas

    value = _singleLine(value);

    if (row >= tableData.length) {
      tableData = [...tableData, for (int i = tableData.length; i <= row; i++) <String>[]];
    }
    if (col >= tableData[row].length) {
      tableData[row] = [...tableData[row], for (int i = tableData[row].length; i <= col; i++) ''];
    }
    tableData[row][col] = value;

    if (hasSchema && row > 0) recomputeRow(row);
    _syncAfterShapeChange();
    notifyListeners();
  }

  void addEmptyColumnAtEnd() {
    if (hasSchema) return;
    if (tableData.isEmpty) tableData = [<String>[]];
    for (int r = 0; r < tableData.length; r++) {
      tableData[r] = [...tableData[r], ''];
    }
    _syncAfterShapeChange();
    notifyListeners();
  }

  /// REMOÇÃO sem schema (modo livre)
  void removeColumn(int col) {
    if (hasSchema) return;
    if (col < 0 || col >= colCount) return;

    for (var r = 0; r < tableData.length; r++) {
      if (col < tableData[r].length) {
        final row = List<String>.from(tableData[r], growable: true);
        row.removeAt(col);
        tableData[r] = row;
      }
    }

    colTypes = List<ColumnType>.from(colTypes, growable: true);
    colWidths = List<double>.from(colWidths, growable: true);
    numericCols = List<bool>.from(numericCols, growable: true);

    if (col < colTypes.length) colTypes.removeAt(col);
    if (col < colWidths.length) colWidths.removeAt(col);
    if (col < numericCols.length) numericCols.removeAt(col);

    _syncAfterShapeChange();
    notifyListeners();
  }

  /// REMOÇÃO com schema — apaga UMA coluna
  void removeColumnWithSchema(int col) {
    if (col < 0 || col >= colCount) return;

    if (hasSchema) {
      final metas = List<ColumnMeta>.from(columns);
      if (col >= 0 && col < metas.length) {
        metas.removeAt(col);
        _schema = metas;
      }
    }

    for (var r = 0; r < tableData.length; r++) {
      if (col < tableData[r].length) {
        final row = List<String>.from(tableData[r], growable: true)..removeAt(col);
        tableData[r] = row;
      }
    }

    _syncAfterShapeChange();
    if (hasSchema) recomputeAll();
    notifyListeners();
  }

  /// REMOÇÃO com schema — apaga VÁRIAS colunas
  void removeColumnsWithSchema(Iterable<int> cols) {
    final sorted = cols
        .where((c) => c >= 0 && c < colCount)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // direita -> esquerda

    if (sorted.isEmpty) return;

    if (hasSchema) {
      final metas = List<ColumnMeta>.from(columns);
      for (final c in sorted) {
        if (c >= 0 && c < metas.length) metas.removeAt(c);
      }
      _schema = metas;
    }

    for (var r = 0; r < tableData.length; r++) {
      var row = List<String>.from(tableData[r], growable: true);
      for (final c in sorted) {
        if (c >= 0 && c < row.length) row.removeAt(c);
      }
      tableData[r] = row;
    }

    _syncAfterShapeChange();
    if (hasSchema) recomputeAll();
    notifyListeners();
  }

  /// Conveniência: apagar por NOME do cabeçalho
  bool removeColumnByHeader(String headerName) {
    final idx = headers.indexOf(headerName);
    if (idx < 0) return false;
    if (hasSchema) {
      removeColumnWithSchema(idx);
    } else {
      removeColumn(idx);
    }
    return true;
  }

  // ===== Helpers =====
  String _singleLine(String s) => s.replaceAll('\r', '').replaceAll('\n', '').trim();

  bool _isNumericBR(String s) {
    final v = _singleLine(s);
    if (v.isEmpty) return false;
    final re = RegExp(r'^\d{1,3}(\.\d{3})*(,\d+)?$|^\d+(,\d+)?$');
    return re.hasMatch(v);
  }

  double? _parseBR(String s) {
    final cleaned = _singleLine(s)
        .replaceAll(RegExp(r'[Rr]\$'), '')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .trim();
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
    bool sawValue = false, sawNonNumeric = false;
    for (var r = 1; r < rows.length; r++) {
      if (colIndex >= rows[r].length) continue;
      final cell = _singleLine(rows[r][colIndex]);
      if (cell.isEmpty) continue;
      sawValue = true;
      if (!_isNumericBR(cell)) { sawNonNumeric = true; break; }
    }
    return sawValue && !sawNonNumeric;
  }

  // ---------- Helpers públicos ----------
  double? parseBR(String s) => _parseBR(s);
  String formatNumberBR(double d, {int decimals = 2, bool trimZeros = true}) =>
      _formatNumberBR(d, decimals: decimals, trimZeros: true);
  String formatMoneyBR(double d) => _formatMoneyBR(d);

  double _measureCellWidth(String txt, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: txt, style: style), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    return tp.width + cellPadHorizontal;
  }

  int _getColCount(List<List<String>> rows) => rows.map((r) => r.length).fold<int>(0, (m, l) => l > m ? l : m);

  void _convertColumnValues(int col, ColumnType t) {
    if (hasSchema) return;
    if (tableData.isEmpty) return;
    for (int r = 1; r < tableData.length; r++) {
      if (col >= tableData[r].length) continue;
      final raw = _singleLine(tableData[r][col]);
      if (raw.isEmpty) continue;
      switch (t) {
        case ColumnType.money:
          final d = _parseBR(raw); if (d != null) tableData[r][col] = _formatMoneyBR(d);
          break;
        case ColumnType.number:
          final d2 = _parseBR(raw); if (d2 != null) tableData[r][col] = _formatNumberBR(d2, decimals: 2, trimZeros: true);
          break;
        case ColumnType.boolean_:
          final v = raw.toLowerCase();
          if (['true','t','sim','s','1'].contains(v)) tableData[r][col] = 'true';
          else if (['false','f','nao','não','n','0'].contains(v)) tableData[r][col] = 'false';
          break;
        case ColumnType.date:
          DateTime? dt;
          try {
            if (raw.contains('/')) {
              final p = raw.split('/');
              if (p.length == 3) {
                final d = int.tryParse(p[0]); final m = int.tryParse(p[1]); final y = int.tryParse(p[2]);
                if (d != null && m != null && y != null) dt = DateTime(y, m, d);
              }
            } else if (raw.contains('-')) { dt = DateTime.tryParse(raw); }
          } catch (_) {}
          if (dt != null) {
            final dd = dt.day.toString().padLeft(2,'0');
            final mm = dt.month.toString().padLeft(2,'0');
            final yy = dt.year.toString();
            tableData[r][col] = '$dd/$mm/$yy';
          }
          break;
        case ColumnType.text:
        case ColumnType.auto:
          tableData[r][col] = raw;
          break;
      }
    }
  }

  void _syncAfterShapeChange() {
    final cc = colCount;

    if (!hasSchema) {
      colTypes = List<ColumnType>.from(colTypes, growable: true);
      if (colTypes.length < cc) {
        colTypes.addAll(List<ColumnType>.filled(cc - colTypes.length, ColumnType.auto, growable: true));
      }
    } else {
      if (colTypes.length != cc) {
        colTypes = columns.map((c) => c.type).toList(growable: true);
      }
    }

    numericCols = List<bool>.generate(cc, (i) => isNumericEffective(i), growable: true);
    colWidths = computeColWidths(tableData);
  }

  void recomputeRow(int r) {
    if (!hasSchema) return;
    if (r <= 0 || r >= tableData.length) return;
    final row = tableData[r];
    for (var c = 0; c < columns.length; c++) {
      final meta = columns[c];
      if (meta.compute != null) {
        final raw = meta.compute!(r, List<String>.from(row), this);
        row[c] = meta.formatter != null ? meta.formatter!(raw) : raw;
      }
    }
  }

  void recomputeAll() {
    if (!hasSchema) return;
    for (var r = 1; r < tableData.length; r++) {
      recomputeRow(r);
    }
  }

  List<ColumnMeta> _columnsFromHeader() {
    if (!hasData) return <ColumnMeta>[];
    final hdr = headers;
    return List<ColumnMeta>.generate(hdr.length, (i) {
      return ColumnMeta(
        key: 'col_$i',
        title: hdr[i],
        type: i < colTypes.length ? colTypes[i] : ColumnType.auto,
        editable: true,
      );
    });
  }
}
