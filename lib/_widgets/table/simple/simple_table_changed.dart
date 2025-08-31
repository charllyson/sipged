import 'package:flutter/material.dart';

class SimpleTableChanged<T> extends StatelessWidget {
  final List<T> listData;
  final BoxConstraints constraints;

  final String? status;
  final int? sortColumnIndex;
  final bool isAscending;
  final String Function(T)? sortField;
  final void Function(int columnIndex, String Function(T) fieldGetter)? onSort;
  final void Function(T item)? onTapItem;
  final void Function(T item)? onDelete;
  final Widget Function(T item)? leadingCell;

  final List<String> columnTitles;
  final List<String Function(T)> columnGetters;
  final String Function(T item)? groupBy;
  final String? leadingCellTitle;
  final String? groupLabel;
  final List<double>? columnWidths;
  final List<TextAlign>? columnTextAligns;

  final Color colorHeadTable;
  final Color colorHeadTableText;

  final List<TableRow>? footerRows;
  final T? selectedItem;

  const SimpleTableChanged({
    super.key,
    required this.listData,
    required this.constraints,
    required this.columnTitles,
    required this.columnGetters,
    this.status,
    this.sortColumnIndex,
    this.isAscending = true,
    this.sortField,
    this.onSort,
    this.onTapItem,
    this.onDelete,
    this.leadingCell,
    this.groupBy,
    this.leadingCellTitle,
    this.groupLabel,
    this.columnWidths,
    this.columnTextAligns,
    this.colorHeadTable = const Color(0xFF091D68),
    this.colorHeadTableText = Colors.white,
    this.footerRows,
    this.selectedItem,
  });

  // ---- helpers de colunas ----
  int get _leadingCols =>
      (leadingCell != null && (leadingCellTitle?.isNotEmpty ?? false)) ? 1 : 0;
  int get _deleteCols => onDelete != null ? 1 : 0;
  int get _totalColumns => _leadingCols + columnTitles.length + _deleteCols;

  @override
  Widget build(BuildContext context) {
    // cópia da lista para ordenação
    List<T> data = List<T>.from(listData);

    if (sortField != null && sortColumnIndex != null) {
      data.sort((a, b) {
        final av = sortField!(a);
        final bv = sortField!(b);
        final r = _smartCompare(av, bv);
        return isAscending ? r : -r;
      });
    }

    final grouped = data.isEmpty ? <String, List<T>>{} : _groupBy(data);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
              child: Text(
                'Nenhum registro encontrado.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (data.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Table(
                  border: TableBorder.all(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  columnWidths: {
                    for (int i = 0; i < _totalColumns; i++)
                      i: FixedColumnWidth(
                        (columnWidths != null && i < columnWidths!.length)
                            ? columnWidths![i]
                            : 150.0,
                      ),
                  },
                  children: [
                    _buildHeaderRow(),
                    ...grouped.entries.expand((entry) {
                      final groupKey = entry.key;
                      final items = entry.value;

                      return [
                        if (groupBy != null && groupLabel != null)
                          _buildGroupRow(groupKey),
                        ...items.map((item) {
                          final isSelected =
                              selectedItem != null && item == selectedItem;
                          return _buildDataRow(context, item, isSelected);
                        }),
                      ];
                    }),
                    ...?footerRows,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Header ----------
  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: colorHeadTable),
      children: [
        if (_leadingCols == 1)
          _buildHeader(leadingCellTitle ?? '', 0, (d) => ''),
        ...List.generate(columnTitles.length, (index) {
          final colIndex = index + _leadingCols;
          return _buildHeader(columnTitles[index], colIndex, columnGetters[index]);
        }),
        if (_deleteCols == 1)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'APAGAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorHeadTableText,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sortIcon(int columnIndex) {
    if (sortColumnIndex == columnIndex) {
      return Icon(
        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 16,
        color: Colors.redAccent,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _headerLabel(String title, int columnIndex) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      alignment: WrapAlignment.center,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorHeadTableText,
          ),
        ),
        _sortIcon(columnIndex),
      ],
    );
  }

  Widget _headerBody(String title, int columnIndex, String Function(T) getter) {
    return InkWell(
      onTap: () => onSort?.call(columnIndex, getter),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _headerLabel(title, columnIndex),
      ),
    );
  }

  Widget _buildHeader(String title, int columnIndex, String Function(T) getter) {
    return Tooltip(
      message: 'Ordenar por $title',
      child: _headerBody(title, columnIndex, getter),
    );
  }

  // ---------- Group Row ----------
  TableRow _buildGroupRow(String groupKey) {
    final List<Widget> cells = [];

    // 1ª célula (label + valor) — independente de leading/delete existir
    cells.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          (groupLabel ?? 'Grupo') + (groupKey.isNotEmpty ? ': $groupKey' : ''),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );

    // Preenche o restante até total de colunas
    while (cells.length < _totalColumns) {
      cells.add(Container());
    }

    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: cells,
    );
  }

  // ---------- Data Row ----------
  TableRow _buildDataRow(BuildContext context, T item, bool isSelected) {
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade100 : Colors.white,
      ),
      children: [
        if (_leadingCols == 1)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: InkWell(
              onTap: () => onTapItem?.call(item),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: leadingCell!(item)),
              ),
            ),
          ),
        ...List.generate(columnGetters.length, (index) {
          return _buildCell(
            columnGetters[index](item),
            item,
            textAlign: (columnTextAligns != null && index < columnTextAligns!.length)
                ? columnTextAligns![index]
                : TextAlign.left,
          );
        }),
        if (_deleteCols == 1)
          TableCell(
            child: IconButton(
              tooltip: 'Apagar',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarExclusao(context, item),
            ),
          ),
      ],
    );
  }

  TableCell _buildCell(String? text, T item, {TextAlign textAlign = TextAlign.left}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: () => onTapItem?.call(item),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: _getAlignment(textAlign),
            child: Semantics(
              button: true,
              label: text ?? '',
              child: Text(
                text ?? '',
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      default:
        return Alignment.centerLeft;
    }
  }

  // ---------- Diálogo de exclusão ----------
  void _confirmarExclusao(BuildContext context, T item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call(item);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------- Agrupamento ----------
  Map<String, List<T>> _groupBy(List<T> data) {
    final Map<String, List<T>> grouped = {};
    for (final item in data) {
      final key = groupBy?.call(item) ?? 'Sem grupo';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  // ---------- Comparador inteligente ----------
  int _smartCompare(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // nulos no fim
    if (b == null) return -1;

    // número (aceita vírgula como decimal)
    final an = num.tryParse(a.replaceAll(',', '.'));
    final bn = num.tryParse(b.replaceAll(',', '.'));
    if (an != null && bn != null) return an.compareTo(bn);

    // data
    DateTime? ad, bd;
    try {
      ad = DateTime.tryParse(a);
    } catch (_) {}
    try {
      bd = DateTime.tryParse(b);
    } catch (_) {}
    if (ad != null && bd != null) return ad.compareTo(bd);

    // string normalizada
    final na = a.toLowerCase();
    final nb = b.toLowerCase();
    return na.compareTo(nb);
  }
}
