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

  @override
  Widget build(BuildContext context) {
    List<T> data = List.from(listData);
    if (sortField != null && sortColumnIndex != null) {
      data.sort((a, b) {
        final aValue = sortField!(a).toLowerCase();
        final bValue = sortField!(b).toLowerCase();
        return isAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      });
    }

    final grouped = listData.isEmpty ? <String, List<T>>{} : _groupBy(data);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null || listData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '$status - (${listData.length}) registros',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          if (listData.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                'Nenhum registro encontrado.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (listData.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth - 24),
                child: Table(
                  border: TableBorder.all(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  columnWidths: {
                    for (int i = 0;
                    i <
                        columnTitles.length +
                            (leadingCell != null && (leadingCellTitle?.isNotEmpty ?? false) ? 2 : 1);
                    i++)
                      i: FixedColumnWidth(
                          (columnWidths != null && i < columnWidths!.length)
                              ? columnWidths![i]
                              : 150.0),
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
                          final isSelected = selectedItem != null && item == selectedItem;
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

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: colorHeadTable),
      children: [
        if (leadingCell != null && (leadingCellTitle?.isNotEmpty ?? false))
          _buildHeader(leadingCellTitle!, 0, (d) => ''),
        ...List.generate(columnTitles.length, (index) {
          final adjustedIndex = (leadingCell != null && (leadingCellTitle?.isNotEmpty ?? false)) ? index + 1 : index;
          return _buildHeader(columnTitles[index], adjustedIndex, columnGetters[index]);
        }),
        if (onDelete != null)
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

  TableRow _buildGroupRow(String groupKey) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            groupLabel!,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            groupKey,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        ...List.generate(columnTitles.length - 1, (_) => Container()),
        if (onDelete != null) Container(),
      ],
    );
  }

  TableRow _buildDataRow(BuildContext context, T item, bool isSelected) {
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade100 : Colors.white,
      ),
      children: [
        if (leadingCell != null && (leadingCellTitle?.isNotEmpty ?? false))
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
        ...List.generate(columnGetters.length, (index) => _buildCell(
          columnGetters[index](item),
          item,
          textAlign: (columnTextAligns != null && index < columnTextAligns!.length)
              ? columnTextAligns![index]
              : TextAlign.left,
        )),
        if (onDelete != null)
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
            child: Text(
              text ?? '',
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              maxLines: 2,
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

  Widget _buildHeader(String title, int columnIndex, String Function(T) getter) {
    return Tooltip(
      message: 'Ordenar por $title',
      child: InkWell(
        onTap: () => onSort?.call(columnIndex, getter),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
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
              if (sortColumnIndex == columnIndex)
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.redAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, T item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
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

  Map<String, List<T>> _groupBy(List<T> data) {
    final Map<String, List<T>> grouped = {};
    for (final item in data) {
      final key = groupBy?.call(item) ?? 'Sem grupo';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }
}
