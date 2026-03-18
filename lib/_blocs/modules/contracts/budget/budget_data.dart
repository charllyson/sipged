enum BudgetColumnType { auto, text, number, money, percent, date, code, sectionTitle }

class BudgetColumn {
  final String name;
  final BudgetColumnType type;
  final double width;
  final String? unit;
  final int? precision;

  const BudgetColumn({
    required this.name,
    this.type = BudgetColumnType.auto,
    this.width = 120.0,
    this.unit,
    this.precision,
  });

  BudgetColumn copyWith({
    String? name,
    BudgetColumnType? type,
    double? width,
    String? unit,
    int? precision,
  }) =>
      BudgetColumn(
        name: name ?? this.name,
        type: type ?? this.type,
        width: width ?? this.width,
        unit: unit ?? this.unit,
        precision: precision ?? this.precision,
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'width': width,
    'unit': unit,
    'precision': precision,
  };

  factory BudgetColumn.fromMap(Map<String, dynamic> m) => BudgetColumn(
    name: (m['name'] ?? '').toString(),
    type: BudgetColumnType.values.firstWhere(
          (t) => t.name == (m['type'] ?? 'auto'),
      orElse: () => BudgetColumnType.auto,
    ),
    width: (m['width'] is num) ? (m['width'] as num).toDouble() : 120.0,
    unit: m['unit'] as String?,
    precision: (m['precision'] is num) ? (m['precision'] as num).toInt() : null,
  );
}

class BudgetSchema {
  final List<BudgetColumn> columns;
  final Map<String, int> _indexByName;

  BudgetSchema._(this.columns, this._indexByName);

  factory BudgetSchema(List<BudgetColumn> cols) {
    final map = <String, int>{};
    for (var i = 0; i < cols.length; i++) {
      map[cols[i].name] = i;
    }
    return BudgetSchema._(List.unmodifiable(cols), Map.unmodifiable(map));
  }

  int? indexOf(String colName) => _indexByName[colName];
  bool has(String colName) => _indexByName.containsKey(colName);

  List<String> get headerNames => columns.map((c) => c.name).toList();
  List<String> get headerTypes => columns.map((c) => c.type.name).toList();
  List<double> get headerWidths => columns.map((c) => c.width).toList();

  Map<String, dynamic> toMap() => {
    'columns': columns.map((c) => c.toMap()).toList(),
  };

  factory BudgetSchema.fromLegacy({
    required List<String> names,
    required List<String> types,
    required List<double> widths,
  }) {
    final len = names.length;
    final cols = List<BudgetColumn>.generate(len, (i) {
      final t = (i < types.length) ? types[i] : 'auto';
      final w = (i < widths.length) ? widths[i] : 120.0;
      final type = BudgetColumnType.values.firstWhere(
            (x) => x.name == t,
        orElse: () => BudgetColumnType.auto,
      );
      return BudgetColumn(name: names[i], type: type, width: w);
    });
    return BudgetSchema(cols);
  }
}

abstract class BudgetEntry {
  const BudgetEntry();
  bool get isSection => this is BudgetSection;
  bool get isItem => this is BudgetItem;
}

class BudgetSection extends BudgetEntry {
  final int order;
  final String title;

  const BudgetSection({required this.order, required this.title});
}

class BudgetItem extends BudgetEntry {
  final String code;
  final int depth;
  final List<String> values;

  const BudgetItem({
    required this.code,
    required this.depth,
    required this.values,
  });

  String? value(BudgetSchema schema, String colName) {
    final i = schema.indexOf(colName);
    if (i == null || i >= values.length) return null;
    return values[i];
  }

  num? valueNum(BudgetSchema schema, String colName) {
    final v = value(schema, colName);
    if (v == null) return null;
    final vv = v.replaceAll('.', '').replaceAll(',', '.');
    return num.tryParse(vv);
  }
}

class BudgetData {
  final BudgetSchema schema;
  final List<BudgetEntry> entries;

  const BudgetData({required this.schema, required this.entries});

  bool get isEmpty => entries.isEmpty || schema.columns.isEmpty;

  Iterable<BudgetSection> get sections sync* {
    for (final e in entries) {
      if (e is BudgetSection) yield e;
    }
  }

  Iterable<BudgetItem> get items sync* {
    for (final e in entries) {
      if (e is BudgetItem) yield e;
    }
  }

  BudgetItem? itemByCode(String code) {
    for (final item in items) {
      if (item.code == code) return item;
    }
    return null;
  }

  Iterable<BudgetItem> itemsUnderSection(BudgetSection s) sync* {
    bool inRange = false;
    for (final e in entries) {
      if (e is BudgetSection) {
        inRange = e.order == s.order;
        continue;
      }
      if (inRange && e is BudgetItem) yield e;
    }
  }

  num sumColumn(String colName, {BudgetSection? within}) {
    final idx = schema.indexOf(colName);
    if (idx == null) return 0;
    final range = (within == null) ? items : itemsUnderSection(within);

    num total = 0;
    for (final it in range) {
      final raw = (idx < it.values.length) ? it.values[idx] : null;
      if (raw == null || raw.trim().isEmpty) continue;
      final vv = raw.replaceAll('.', '').replaceAll(',', '.');
      final n = num.tryParse(vv);
      if (n != null) total += n;
    }
    return total;
  }

  List<List<String>> toTableData() {
    final table = <List<String>>[];
    table.add(schema.headerNames);

    for (final e in entries) {
      if (e is BudgetSection) {
        final row = List<String>.filled(schema.columns.length, '');
        row[0] = e.order.toString();
        if (schema.columns.length > 1) row[1] = e.title;
        table.add(row);
      } else if (e is BudgetItem) {
        final row = List<String>.generate(
          schema.columns.length,
              (i) => (i < e.values.length) ? e.values[i] : '',
        );
        table.add(row);
      }
    }
    return table;
  }

  factory BudgetData.fromLegacy({
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> tableData,
  }) {
    final schema = BudgetSchema.fromLegacy(
      names: headers,
      types: colTypes,
      widths: colWidths,
    );

    bool isSectionRow(List<String> r) {
      if (r.isEmpty) return false;
      final c0 = r[0].trim();
      final n = int.tryParse(c0);
      if (n == null) return false;
      final title = (r.length > 1 ? r[1] : '').trim();
      final onlyLetters = title.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ ]'), '');
      return onlyLetters.isNotEmpty && onlyLetters == onlyLetters.toUpperCase();
    }

    final codeRe = RegExp(r'^\d+(?:\.\d+)+$');
    final entries = <BudgetEntry>[];

    if (tableData.isEmpty) {
      return BudgetData(schema: schema, entries: const []);
    }

    final dataRows = tableData.skip(1);
    int currentSectionOrder = -1;

    for (final row0 in dataRows) {
      final row =
      _padRow(row0.map((e) => e.toString()).toList(), schema.columns.length);
      if (row.every((c) => c.trim().isEmpty)) continue;

      if (isSectionRow(row)) {
        currentSectionOrder =
            int.tryParse(row[0].trim()) ?? (currentSectionOrder + 1);
        final title = (row.length > 1 ? row[1].trim() : '');
        entries.add(BudgetSection(order: currentSectionOrder, title: title));
        continue;
      }

      final c0 = row[0].trim();
      if (codeRe.hasMatch(c0)) {
        final depth = c0.split('.').length;
        entries.add(BudgetItem(code: c0, depth: depth, values: row));
      }
    }

    return BudgetData(schema: schema, entries: List.unmodifiable(entries));
  }

  factory BudgetData.withSchema(BudgetSchema schema) =>
      BudgetData(schema: schema, entries: const []);

  BudgetData copyWith({
    BudgetSchema? schema,
    List<BudgetEntry>? entries,
  }) =>
      BudgetData(
        schema: schema ?? this.schema,
        entries: entries ?? this.entries,
      );
}

List<String> _padRow(List<String> r, int headerLen) {
  if (r.length >= headerLen) return r.take(headerLen).toList();
  return [...r, for (int i = r.length; i < headerLen; i++) ''];
}