import 'package:flutter/material.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

class SimpleTableVirtualized<T> extends StatelessWidget {
  const SimpleTableVirtualized({
    super.key,
    // dados/colunas
    required this.listData,
    required this.constraints,
    required this.columnTitles,
    required this.columnGetters,
    this.groupBy,
    this.leadingCellTitle,
    this.leadingCell,
    // largura/alinhamento
    this.columnWidths,
    this.columnTextAligns,
    this.deleteColWidth = 56.0,
    // estilo
    this.colorHeadTable = const Color(0xFF091D68),
    this.colorHeadTableText = Colors.white,
    this.headerPadding = const EdgeInsets.all(8),
    this.rowPadding = const EdgeInsets.all(8),
    // ordenação
    this.sortColumnIndex,
    this.isAscending = true,
    this.onSort,
    // interações
    this.onTapItem,
    this.onDelete,
    this.selectedItem,
    // layout
    this.bodyHeight = 480,
    this.footerRows,
  }) : assert(
  columnTitles.length == columnGetters.length,
  'columnTitles e columnGetters precisam ter o mesmo tamanho.',
  );

  // base
  final List<T> listData;
  final BoxConstraints constraints;

  // colunas
  final List<String> columnTitles;
  final List<String Function(T)> columnGetters;
  final List<double>? columnWidths;
  final List<TextAlign>? columnTextAligns;
  final double deleteColWidth;

  // grupo/leading
  final String Function(T item)? groupBy; // opcional
  final String? leadingCellTitle;
  final Widget Function(T item)? leadingCell;

  // ordenação
  final int? sortColumnIndex;
  final bool isAscending;
  final void Function(int columnIndex, String Function(T) fieldGetter)? onSort;

  // interações
  final void Function(T item)? onTapItem;
  final void Function(T item)? onDelete;
  final T? selectedItem;

  // estilo
  final Color colorHeadTable;
  final Color colorHeadTableText;
  final EdgeInsets headerPadding;
  final EdgeInsets rowPadding;

  // layout extra
  final double bodyHeight;
  final List<TableRow>? footerRows;

  // ---- helpers de colunas ----
  int get _leadingCols =>
      (leadingCell != null && (leadingCellTitle?.isNotEmpty ?? false)) ? 1 : 0;
  int get _deleteCols => onDelete != null ? 1 : 0;
  int get _totalColumns => _leadingCols + columnTitles.length + _deleteCols;

  List<double> get _colWidths {
    if (columnWidths != null && columnWidths!.length == _totalColumns) {
      return columnWidths!;
    }
    final List<double> w = [];
    if (_leadingCols == 1) w.add(150.0);
    for (var i = 0; i < columnTitles.length; i++) {
      w.add(150.0);
    }
    if (_deleteCols == 1) w.add(deleteColWidth);
    return w;
  }

  List<TextAlign> get _colAligns {
    final n = columnTitles.length;
    final a = columnTextAligns;

    if (a == null) {
      return List<TextAlign>.filled(n, TextAlign.left, growable: false);
    }
    if (a.length == n) return a;
    if (a.length > n) return a.sublist(0, n);
    final filler = a.isEmpty ? TextAlign.left : a.last;
    return List<TextAlign>.from(a)..addAll(List.filled(n - a.length, filler));
  }

  @override
  Widget build(BuildContext context) {
    // valida columnWidths (em runtime para evitar const issues)
    assert(() {
      final expected = columnTitles.length + _leadingCols + _deleteCols;
      if (columnWidths != null && columnWidths!.length != expected) {
        throw FlutterError(
          'columnWidths deve conter largura para TODAS as colunas '
              '(incluindo leading/delete se existirem): '
              'esperado $expected, recebido ${columnWidths!.length}.',
        );
      }
      return true;
    }());

    // dados achatados (se houver agrupamento)
    final grouped = _groupBy(listData);
    final flat = grouped.entries.expand<T>((e) => e.value).toList(growable: false);

    // medidas
    final widths = _colWidths;
    final totalWidth = widths.fold<double>(0, (s, w) => s + w);
    final parentWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : MediaQuery.of(context).size.width;
    final needsScroll = totalWidth > parentWidth;

    // cabeçalho pronto
    final header = _buildHeaderStrip();

    // conteúdo da tabela (reutilizado nos dois ramos)
    Widget content() {
      final aligns = _colAligns;

      return Column(
        children: [
          header,
          const Divider(height: 1),
          SizedBox(
            height: bodyHeight,
            child: ListView.builder(
              itemCount: flat.length,
              itemBuilder: (context, index) {
                final item = flat[index];
                final cells = List.generate(
                  columnGetters.length,
                      (i) {
                    try {
                      return columnGetters[i](item);
                    } catch (_) {
                      return '-';
                    }
                  },
                  growable: false,
                );

                final isSelected = selectedItem != null && item == selectedItem;

                return InkWell(
                  onTap: () => onTapItem?.call(item),
                  child: Container(
                    color: isSelected ? const Color(0xFFE1F5FE) : Colors.white,
                    child: Row(
                      children: [
                        if (_leadingCols == 1)
                          SizedBox(
                            width: widths[0],
                            child: Padding(
                              padding: rowPadding,
                              child: Center(child: leadingCell!(item)),
                            ),
                          ),
                        for (var c = 0; c < columnGetters.length; c++)
                          SizedBox(
                            width: widths[c + _leadingCols],
                            child: Padding(
                              padding: rowPadding,
                              child: Align(
                                alignment: _toAlignment(aligns[c]),
                                child: Text(
                                  cells[c],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: aligns[c],
                                ),
                              ),
                            ),
                          ),
                        if (_deleteCols == 1)
                          SizedBox(
                            width: widths.last,
                            child: IconButton(
                              tooltip: 'Apagar',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmarExclusao(context, item),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (footerRows != null && footerRows!.isNotEmpty)
            SizedBox(
              width: totalWidth,
              child: Table(
                columnWidths: {
                  for (int i = 0; i < _totalColumns; i++)
                    i: FixedColumnWidth(widths[i]),
                },
                children: footerRows!,
              ),
            ),
        ],
      );
    }

    // evita BoxConstraints inválidos e centraliza
    return SizedBox(
      width: parentWidth,
      child: needsScroll
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(
          child: SizedBox(width: totalWidth, child: content()),
        ),
      )
          : Center(
        child: SizedBox(width: totalWidth, child: content()),
      ),
    );
  }

  // ----------------- header -----------------
  Widget _buildHeaderStrip() {
    final widths = _colWidths;
    final children = <Widget>[];

    if (_leadingCols == 1) {
      children.add(
        Container(
          width: widths[0],
          color: colorHeadTable,
          child: Padding(
            padding: headerPadding,
            child: Center(
              child: Text(
                leadingCellTitle ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorHeadTableText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < columnTitles.length; i++) {
      final colIndex = i + _leadingCols;
      children.add(
        InkWell(
          onTap: () => onSort?.call(colIndex, columnGetters[i]),
          child: Container(
            width: widths[colIndex],
            color: colorHeadTable,
            child: Padding(
              padding: headerPadding,
              child: Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      columnTitles[i],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorHeadTableText,
                      ),
                    ),
                    _sortIcon(colIndex),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_deleteCols == 1) {
      children.add(
        Container(
          width: _colWidths.last,
          color: colorHeadTable,
          child: Padding(
            padding: headerPadding,
            child: Center(
              child: Text(
                'APAGAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorHeadTableText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: children);
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

  // ----------------- utils -----------------
  Map<String, List<T>> _groupBy(List<T> list) {
    if (groupBy == null) {
      return {'': list};
    }
    final Map<String, List<T>> grouped = {};
    for (final item in list) {
      final key = groupBy!(item);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  Alignment _toAlignment(TextAlign align) {
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

  Future<void> _confirmarExclusao(BuildContext context, T item) async {
    final confirmed = await showWindowDialogMac<bool>(
      context: context,
      title: 'Confirmar exclusão',
      width: 420,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Deseja realmente excluir este item?',
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text(
                        'Excluir',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      onDelete?.call(item);
    }
  }
}
