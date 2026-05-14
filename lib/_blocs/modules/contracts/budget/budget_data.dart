// lib/_blocs/modules/contracts/budget/budget_data.dart

enum BudgetColumnType {
  auto,
  text,
  number,
  money,
  percent,
  date,
  code,
  sectionTitle,
}

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
  }) {
    return BudgetColumn(
      name: name ?? this.name,
      type: type ?? this.type,
      width: width ?? this.width,
      unit: unit ?? this.unit,
      precision: precision ?? this.precision,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'type': type.name,
      'width': width,
      if (unit != null) 'unit': unit,
      if (precision != null) 'precision': precision,
    };
  }

  factory BudgetColumn.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] ?? BudgetColumnType.auto.name).toString();

    return BudgetColumn(
      name: (map['name'] ?? '').toString(),
      type: BudgetColumnType.values.firstWhere(
            (item) => item.name == rawType,
        orElse: () => BudgetColumnType.auto,
      ),
      width: map['width'] is num
          ? (map['width'] as num).toDouble()
          : double.tryParse((map['width'] ?? '').toString()) ?? 120.0,
      unit: map['unit']?.toString(),
      precision: map['precision'] is num
          ? (map['precision'] as num).toInt()
          : int.tryParse((map['precision'] ?? '').toString()),
    );
  }
}

class BudgetSchema {
  final List<BudgetColumn> columns;
  final Map<String, int> _indexByName;

  BudgetSchema._({
    required this.columns,
    required Map<String, int> indexByName,
  }) : _indexByName = indexByName;

  factory BudgetSchema(List<BudgetColumn> columns) {
    final normalizedColumns = List<BudgetColumn>.unmodifiable(columns);
    final index = <String, int>{};

    for (var i = 0; i < normalizedColumns.length; i++) {
      final name = normalizedColumns[i].name.trim();
      if (name.isEmpty) continue;
      index[name] = i;
    }

    return BudgetSchema._(
      columns: normalizedColumns,
      indexByName: Map<String, int>.unmodifiable(index),
    );
  }

  factory BudgetSchema.empty() {
    return BudgetSchema(const <BudgetColumn>[]);
  }

  factory BudgetSchema.fromMap(Map<String, dynamic> map) {
    final rawColumns = map['columns'];

    if (rawColumns is! List) {
      return BudgetSchema.empty();
    }

    final columns = rawColumns
        .whereType<Map>()
        .map(
          (item) => BudgetColumn.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .where((item) => item.name.trim().isNotEmpty)
        .toList();

    return BudgetSchema(columns);
  }

  factory BudgetSchema.fromTableHeaders({
    required List<String> headers,
    required List<String> types,
    required List<double> widths,
  }) {
    final columns = <BudgetColumn>[];

    for (var i = 0; i < headers.length; i++) {
      final name = headers[i].trim();
      if (name.isEmpty) continue;

      final rawType = i < types.length ? types[i].trim() : '';
      final type = BudgetColumnType.values.firstWhere(
            (item) => item.name == rawType,
        orElse: () => BudgetColumnType.auto,
      );

      final width = i < widths.length ? widths[i] : 120.0;

      columns.add(
        BudgetColumn(
          name: name,
          type: type,
          width: width <= 0 ? 120.0 : width,
        ),
      );
    }

    return BudgetSchema(columns);
  }

  int? indexOf(String columnName) {
    return _indexByName[columnName.trim()];
  }

  bool has(String columnName) {
    return _indexByName.containsKey(columnName.trim());
  }

  List<String> get headerNames {
    return columns.map((item) => item.name).toList(growable: false);
  }

  List<String> get headerTypes {
    return columns.map((item) => item.type.name).toList(growable: false);
  }

  List<double> get headerWidths {
    return columns.map((item) => item.width).toList(growable: false);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'columns': columns.map((item) => item.toMap()).toList(growable: false),
    };
  }
}

sealed class BudgetEntry {
  const BudgetEntry();

  bool get isSection => this is BudgetSection;

  bool get isItem => this is BudgetItem;
}

class BudgetSection extends BudgetEntry {
  final int order;
  final String title;
  final int entryIndex;

  const BudgetSection({
    required this.order,
    required this.title,
    this.entryIndex = 0,
  });

  BudgetSection copyWith({
    int? order,
    String? title,
    int? entryIndex,
  }) {
    return BudgetSection(
      order: order ?? this.order,
      title: title ?? this.title,
      entryIndex: entryIndex ?? this.entryIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kind': 'section',
      'order': order,
      'title': title,
      'entryIndex': entryIndex,
    };
  }

  factory BudgetSection.fromMap(Map<String, dynamic> map) {
    return BudgetSection(
      order: map['order'] is num
          ? (map['order'] as num).toInt()
          : int.tryParse((map['order'] ?? '0').toString()) ?? 0,
      title: (map['title'] ?? '').toString(),
      entryIndex: map['entryIndex'] is num
          ? (map['entryIndex'] as num).toInt()
          : int.tryParse((map['entryIndex'] ?? '0').toString()) ?? 0,
    );
  }
}

class BudgetItem extends BudgetEntry {
  final String code;
  final int depth;
  final int index;
  final List<String> values;

  const BudgetItem({
    required this.code,
    required this.depth,
    required this.values,
    this.index = 0,
  });

  BudgetItem copyWith({
    String? code,
    int? depth,
    int? index,
    List<String>? values,
  }) {
    return BudgetItem(
      code: code ?? this.code,
      depth: depth ?? this.depth,
      index: index ?? this.index,
      values: values ?? this.values,
    );
  }

  String? value(BudgetSchema schema, String columnName) {
    final index = schema.indexOf(columnName);
    if (index == null || index >= values.length) return null;
    return values[index];
  }

  num? valueNum(BudgetSchema schema, String columnName) {
    final raw = value(schema, columnName);
    return parseBrazilianNumber(raw);
  }

  Map<String, dynamic> toMap({
    required int schemaLength,
    required String orderKey,
  }) {
    return <String, dynamic>{
      'kind': 'item',
      'code': code,
      'depth': depth,
      'index': index,
      'orderKey': orderKey,
      'values': normalizedValues(schemaLength),
    };
  }

  List<String> normalizedValues(int length) {
    if (values.length == length) {
      return List<String>.unmodifiable(values);
    }

    if (values.length > length) {
      return List<String>.unmodifiable(values.take(length));
    }

    return List<String>.unmodifiable(
      <String>[
        ...values,
        for (var i = values.length; i < length; i++) '',
      ],
    );
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    final rawValues = map['values'];

    return BudgetItem(
      code: (map['code'] ?? '').toString(),
      depth: map['depth'] is num
          ? (map['depth'] as num).toInt()
          : int.tryParse((map['depth'] ?? '1').toString()) ?? 1,
      index: map['index'] is num
          ? (map['index'] as num).toInt()
          : int.tryParse((map['index'] ?? '0').toString()) ?? 0,
      values: rawValues is List
          ? rawValues.map((item) => (item ?? '').toString()).toList()
          : const <String>[],
    );
  }
}

class BudgetData {
  final BudgetSchema schema;
  final List<BudgetEntry> entries;

  const BudgetData({
    required this.schema,
    required this.entries,
  });

  factory BudgetData.empty() {
    return BudgetData(
      schema: BudgetSchema.empty(),
      entries: const <BudgetEntry>[],
    );
  }

  factory BudgetData.withSchema(BudgetSchema schema) {
    return BudgetData(
      schema: schema,
      entries: const <BudgetEntry>[],
    );
  }

  bool get isEmpty {
    return schema.columns.isEmpty || entries.isEmpty;
  }

  Iterable<BudgetSection> get sections sync* {
    for (final entry in entries) {
      if (entry is BudgetSection) yield entry;
    }
  }

  Iterable<BudgetItem> get items sync* {
    for (final entry in entries) {
      if (entry is BudgetItem) yield entry;
    }
  }

  BudgetItem? itemByCode(String code) {
    final cleanCode = code.trim();

    for (final item in items) {
      if (item.code.trim() == cleanCode) return item;
    }

    return null;
  }

  Iterable<BudgetItem> itemsUnderSection(BudgetSection section) sync* {
    var inRange = false;

    for (final entry in entries) {
      if (entry is BudgetSection) {
        inRange = entry.entryIndex == section.entryIndex &&
            entry.order == section.order &&
            entry.title == section.title;
        continue;
      }

      if (inRange && entry is BudgetItem) {
        yield entry;
      }
    }
  }

  num sumColumn(String columnName, {BudgetSection? within}) {
    final columnIndex = schema.indexOf(columnName);
    if (columnIndex == null) return 0;

    final targetItems = within == null ? items : itemsUnderSection(within);

    num total = 0;

    for (final item in targetItems) {
      if (columnIndex >= item.values.length) continue;

      final parsed = parseBrazilianNumber(item.values[columnIndex]);
      if (parsed != null) total += parsed;
    }

    return total;
  }

  List<List<String>> toTableData() {
    if (schema.columns.isEmpty) {
      return const <List<String>>[<String>[]];
    }

    final table = <List<String>>[
      schema.headerNames,
    ];

    for (final entry in entries) {
      if (entry is BudgetSection) {
        final row = List<String>.filled(schema.columns.length, '');
        row[0] = entry.order.toString();

        if (schema.columns.length > 1) {
          row[1] = entry.title;
        }

        table.add(row);
        continue;
      }

      if (entry is BudgetItem) {
        table.add(entry.normalizedValues(schema.columns.length));
      }
    }

    return table;
  }

  factory BudgetData.fromTable({
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    bool rowsIncludesHeader = true,
  }) {
    final schema = BudgetSchema.fromTableHeaders(
      headers: headers,
      types: colTypes,
      widths: colWidths,
    );

    if (schema.columns.isEmpty) {
      return BudgetData.empty();
    }

    final dataRows = rowsIncludesHeader && rows.isNotEmpty
        ? rows.skip(1).toList()
        : rows.toList();

    final entries = <BudgetEntry>[];
    final codeRegex = RegExp(r'^\d+(?:\.\d+)*$');

    var entryIndex = 0;
    var fallbackSectionOrder = 0;

    for (final rawRow in dataRows) {
      final row = normalizeRow(
        rawRow.map((item) => item.toString()).toList(),
        schema.columns.length,
      );

      if (row.every((item) => item.trim().isEmpty)) continue;

      final first = row.isNotEmpty ? row[0].trim() : '';
      final second = row.length > 1 ? row[1].trim() : '';

      final firstAsInt = int.tryParse(first);
      final isProbableSection = firstAsInt != null &&
          second.isNotEmpty &&
          !codeRegex.hasMatch(first) &&
          row.skip(2).every((item) => item.trim().isEmpty);

      if (isProbableSection) {
        entries.add(
          BudgetSection(
            order: firstAsInt,
            title: second,
            entryIndex: entryIndex,
          ),
        );

        entryIndex++;
        continue;
      }

      final isCode = codeRegex.hasMatch(first);

      if (isCode) {
        entries.add(
          BudgetItem(
            code: first,
            depth: first.split('.').length,
            index: entryIndex,
            values: row,
          ),
        );

        entryIndex++;
        continue;
      }

      if (second.isNotEmpty && firstAsInt != null) {
        entries.add(
          BudgetSection(
            order: firstAsInt,
            title: second,
            entryIndex: entryIndex,
          ),
        );

        entryIndex++;
        continue;
      }

      if (entries.isEmpty || entries.last is! BudgetSection) {
        entries.add(
          BudgetSection(
            order: fallbackSectionOrder,
            title: '',
            entryIndex: entryIndex,
          ),
        );

        fallbackSectionOrder++;
        entryIndex++;
      }

      entries.add(
        BudgetItem(
          code: first.isEmpty ? entryIndex.toString() : first,
          depth: first.split('.').where((item) => item.isNotEmpty).length,
          index: entryIndex,
          values: row,
        ),
      );

      entryIndex++;
    }

    return BudgetData(
      schema: schema,
      entries: List<BudgetEntry>.unmodifiable(entries),
    );
  }

  BudgetData copyWith({
    BudgetSchema? schema,
    List<BudgetEntry>? entries,
  }) {
    return BudgetData(
      schema: schema ?? this.schema,
      entries: entries ?? this.entries,
    );
  }
}

List<String> normalizeRow(List<String> row, int length) {
  if (row.length == length) return List<String>.unmodifiable(row);

  if (row.length > length) {
    return List<String>.unmodifiable(row.take(length));
  }

  return List<String>.unmodifiable(
    <String>[
      ...row,
      for (var i = row.length; i < length; i++) '',
    ],
  );
}

num? parseBrazilianNumber(String? value) {
  final raw = value?.trim();

  if (raw == null || raw.isEmpty) return null;

  final sanitized = raw
      .replaceAll('R\$', '')
      .replaceAll('%', '')
      .replaceAll(' ', '')
      .trim();

  if (sanitized.isEmpty) return null;

  final hasComma = sanitized.contains(',');
  final hasDot = sanitized.contains('.');

  if (hasComma && hasDot) {
    return num.tryParse(
      sanitized.replaceAll('.', '').replaceAll(',', '.'),
    );
  }

  if (hasComma) {
    return num.tryParse(sanitized.replaceAll(',', '.'));
  }

  return num.tryParse(sanitized);
}