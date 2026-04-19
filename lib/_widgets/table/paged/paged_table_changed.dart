import 'package:flutter/material.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_pagination_bar.dart';
import 'package:sipged/_widgets/table/paged/paged_row.dart';
import 'package:sipged/_widgets/table/paged/paged_table_metrics.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

class PagedTableChanged<T> extends StatefulWidget {
  final List<T> listData;

  final String Function(T item)? getKey;
  final String? selectedKey;
  final bool keepSelectionInternally;
  final bool enableRowTapSelection;
  final void Function(T item)? onTapItem;
  final void Function(T item)? onDelete;

  final List<PagedColum<T>> columns;

  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(
      int columnIndex,
      bool ascending,
      String Function(T) getter,
      )? onSort;

  final String Function(T item)? groupBy;
  final String? groupLabel;

  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;
  final EdgeInsetsGeometry cardMargin;
  final double elevation;
  final Color colorHeadTable;
  final Color colorHeadTableText;
  final String? statusLabel;
  final double minTableWidth;
  final double defaultColumnWidth;
  final double actionsColumnWidth;

  final List<int> rowsPerPageOptions;
  final int initialRowsPerPage;

  final bool enablePagination;
  final ValueChanged<PagedTableMetrics>? onMetricsChanged;

  const PagedTableChanged({
    super.key,
    required this.listData,
    required this.columns,
    this.getKey,
    this.selectedKey,
    this.keepSelectionInternally = true,
    this.enableRowTapSelection = true,
    this.onTapItem,
    this.onDelete,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.groupBy,
    this.groupLabel,
    this.headingRowHeight = 44,
    this.dataRowMinHeight = 40,
    this.dataRowMaxHeight = 60,
    this.cardMargin = EdgeInsets.zero,
    this.elevation = 0,
    this.colorHeadTable = const Color(0xFF091D68),
    this.colorHeadTableText = Colors.white,
    this.statusLabel,
    this.minTableWidth = 800,
    this.defaultColumnWidth = 160,
    this.actionsColumnWidth = 96,
    this.rowsPerPageOptions = const [10, 25, 50, 100],
    this.initialRowsPerPage = 25,
    this.enablePagination = true,
    this.onMetricsChanged,
  });

  @override
  State<PagedTableChanged<T>> createState() => _PagedTableChangedState<T>();
}

class _PagedTableChangedState<T> extends State<PagedTableChanged<T>> {
  String? _internalSelectedKey;
  bool _paging = false;

  late int _currentPage;
  late int _rowsPerPage;

  int? _internalSortColumnIndex;
  bool _internalSortAscending = false;

  final ScrollController _horizontalCtrl = ScrollController();
  PagedTableMetrics? _lastMetrics;

  @override
  void initState() {
    super.initState();

    _rowsPerPage = widget.rowsPerPageOptions.contains(widget.initialRowsPerPage)
        ? widget.initialRowsPerPage
        : widget.rowsPerPageOptions.first;

    _currentPage = 1;
    _internalSortColumnIndex = widget.sortColumnIndex;
    _internalSortAscending = widget.sortAscending;
  }

  @override
  void didUpdateWidget(covariant PagedTableChanged<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sortColumnIndex != widget.sortColumnIndex) {
      _internalSortColumnIndex = widget.sortColumnIndex;
    }
    if (oldWidget.sortAscending != widget.sortAscending) {
      _internalSortAscending = widget.sortAscending;
    }

    final totalPages = _calculateTotalPages(widget.listData.length);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
  }

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    super.dispose();
  }

  String? _keyOf(T item) => widget.getKey?.call(item);

  bool _isSelected(T item) {
    final k = _keyOf(item);
    final activeKey = widget.keepSelectionInternally
        ? (_internalSelectedKey ?? widget.selectedKey)
        : widget.selectedKey;

    return k != null && activeKey != null && k == activeKey;
  }

  void _handleTap(T item) {
    final k = _keyOf(item);

    if (widget.keepSelectionInternally && k != null) {
      setState(() => _internalSelectedKey = k);
    }

    widget.onTapItem?.call(item);
  }

  Future<void> _confirmarExclusao(BuildContext context, T item) async {
    final shouldDelete = await showWindowDialog<bool>(
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
                const Text('Deseja realmente excluir este item?'),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (shouldDelete == true) {
      widget.onDelete?.call(item);
    }
  }

  int _calculateTotalPages(int totalItems) {
    if (!widget.enablePagination) return 1;
    final totalPages = (totalItems / _rowsPerPage).ceil();
    return totalPages <= 0 ? 1 : totalPages;
  }

  Future<void> _goTo(int page) async {
    if (!widget.enablePagination) return;

    final totalPages = _calculateTotalPages(widget.listData.length);
    if (_paging || page == _currentPage || page < 1 || page > totalPages) {
      return;
    }

    setState(() => _paging = true);
    try {
      setState(() => _currentPage = page);
    } finally {
      if (mounted) {
        setState(() => _paging = false);
      }
    }
  }

  List<T> _visibleData(List<T> data) {
    if (!widget.enablePagination) {
      return List<T>.from(data);
    }

    final total = data.length;
    final totalPages = _calculateTotalPages(total);

    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, total);

    if (start >= total || start < 0) {
      return <T>[];
    }

    return data.sublist(start, end);
  }

  bool get _showGroups => widget.groupBy != null && widget.groupLabel != null;

  String _resolveGroupKey(T item) {
    final key = widget.groupBy?.call(item).trim() ?? '';
    return key.isEmpty ? 'Sem grupo' : key;
  }

  List<PagedRow<T>> _buildRowChunks(List<T> data) {
    if (!_showGroups) {
      return <PagedRow<T>>[
        PagedRow<T>(type: RowType.normal, items: data),
      ];
    }

    final map = <String, List<T>>{};
    for (final item in data) {
      final key = _resolveGroupKey(item);
      map.putIfAbsent(key, () => <T>[]).add(item);
    }

    final chunks = <PagedRow<T>>[];
    for (final entry in map.entries) {
      chunks.add(PagedRow<T>(type: RowType.groupHeader, groupKey: entry.key));
      chunks.add(PagedRow<T>(type: RowType.normal, items: entry.value));
    }

    return chunks;
  }

  void _emitMetrics({
    required int totalRows,
    required int visibleRows,
    required int totalPages,
  }) {
    if (widget.onMetricsChanged == null) return;

    final metrics = PagedTableMetrics(
      totalRows: totalRows,
      visibleRows: visibleRows,
      currentPage: widget.enablePagination ? _currentPage : 1,
      totalPages: widget.enablePagination ? totalPages : 1,
      rowsPerPage: widget.enablePagination ? _rowsPerPage : totalRows,
    );

    if (_lastMetrics == metrics) return;
    _lastMetrics = metrics;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onMetricsChanged?.call(metrics);
    });
  }

  void _handleSort(int columnIndex, String Function(T) getter) {
    bool nextAscending;

    if (_internalSortColumnIndex == columnIndex) {
      nextAscending = !_internalSortAscending;
    } else {
      nextAscending = true;
    }

    setState(() {
      _internalSortColumnIndex = columnIndex;
      _internalSortAscending = nextAscending;
      _currentPage = 1;
    });

    widget.onSort?.call(columnIndex, nextAscending, getter);
  }

  List<T> _sortedData(List<T> source) {
    final sortIndex = _internalSortColumnIndex;
    if (sortIndex == null) return List<T>.from(source);
    if (sortIndex < 0 || sortIndex >= widget.columns.length) {
      return List<T>.from(source);
    }

    final column = widget.columns[sortIndex];
    final getter = column.getter;
    if (getter == null) return List<T>.from(source);

    final data = List<T>.from(source);

    data.sort((a, b) {
      final av = getter(a).trim();
      final bv = getter(b).trim();
      final result = _smartCompare(av, bv);
      return _internalSortAscending ? result : -result;
    });

    return data;
  }

  int _smartCompare(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    final aa = a.trim();
    final bb = b.trim();

    final an = num.tryParse(aa.replaceAll(',', '.'));
    final bn = num.tryParse(bb.replaceAll(',', '.'));
    if (an != null && bn != null) {
      return an.compareTo(bn);
    }

    DateTime? ad;
    DateTime? bd;

    try {
      ad = DateTime.tryParse(aa);
    } catch (_) {}

    try {
      bd = DateTime.tryParse(bb);
    } catch (_) {}

    if (ad != null && bd != null) {
      return ad.compareTo(bd);
    }

    return aa.toLowerCase().compareTo(bb.toLowerCase());
  }

  double _columnWidth(PagedColum<T> column) {
    return column.width ?? column.maxWidth ?? widget.defaultColumnWidth;
  }

  double _totalTableWidth(bool hasActions) {
    double total = 0;
    for (final column in widget.columns) {
      total += _columnWidth(column);
    }
    if (hasActions) {
      total += widget.actionsColumnWidth;
    }
    return total < widget.minTableWidth ? widget.minTableWidth : total;
  }

  @override
  Widget build(BuildContext context) {
    final sortedData = _sortedData(widget.listData);
    final allData = sortedData;
    final visibleData = _visibleData(allData);
    final chunks = _buildRowChunks(visibleData);
    final hasActions = widget.onDelete != null;
    final totalColumns = widget.columns.length + (hasActions ? 1 : 0);
    final totalPages = _calculateTotalPages(allData.length);

    _emitMetrics(
      totalRows: allData.length,
      visibleRows: visibleData.length,
      totalPages: totalPages,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final realTableWidth = _totalTableWidth(hasActions);
        final needsHorizontalScroll = realTableWidth > parentWidth;
        final renderWidth = needsHorizontalScroll ? realTableWidth : parentWidth;

        final builtColumns = _buildColumns(hasActions, context);

        final builtRows = chunks.expand((chunk) {
          if (chunk.type == RowType.groupHeader) {
            return <DataRow>[
              DataRow(
                color: WidgetStateProperty.all(
                  Colors.grey.shade200,
                ),
                cells: List<DataCell>.generate(
                  totalColumns,
                      (i) {
                    if (i == 0) {
                      final label = widget.groupLabel ?? 'Grupo';
                      final key = chunk.groupKey ?? '';
                      return DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            key.isNotEmpty ? '$label: $key' : label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return const DataCell(SizedBox.shrink());
                  },
                ),
              ),
            ];
          }

          return chunk.items!.map((item) {
            final isSelected = _isSelected(item);
            final cells = <DataCell>[];

            for (final c in widget.columns) {
              final width = _columnWidth(c);

              if (c.cellBuilder != null) {
                cells.add(
                  DataCell(
                    SizedBox(
                      width: width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: c.cellBuilder!(item),
                      ),
                    ),
                  ),
                );
              } else if (c.getter != null) {
                final value = c.getter!(item);
                cells.add(
                  DataCell(
                    SizedBox(
                      width: width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: _cellText(
                          value,
                          context: context,
                          align: c.textAlign,
                          maxW: c.maxWidth ?? width,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                cells.add(
                  DataCell(
                    SizedBox(width: width),
                  ),
                );
              }
            }

            if (hasActions) {
              cells.add(
                DataCell(
                  SizedBox(
                    width: widget.actionsColumnWidth,
                    child: Center(
                      child: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmarExclusao(context, item),
                      ),
                    ),
                  ),
                ),
              );
            }

            return DataRow(
              selected: isSelected,
              onSelectChanged:
              widget.enableRowTapSelection ? (_) => _handleTap(item) : null,
              cells: cells,
            );
          });
        }).toList();

        return Container(
          margin: widget.cardMargin,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.96),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allData.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Text(
                    'Nenhum registro encontrado.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (allData.isNotEmpty)
                Scrollbar(
                  controller: _horizontalCtrl,
                  thumbVisibility: needsHorizontalScroll,
                  child: SingleChildScrollView(
                    controller: _horizontalCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: needsHorizontalScroll
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: renderWidth,
                      child: DataTableTheme(
                        data: DataTableThemeData(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          headingRowColor: WidgetStateProperty.all(
                            widget.colorHeadTable,
                          ),
                          headingTextStyle: TextStyle(
                            color: widget.colorHeadTableText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          dataRowColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFFE1F5FE);
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.blue.withValues(alpha:0.05);
                            }
                            return Colors.white;
                          }),
                          dividerThickness: 1,
                          dataTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        child: DataTable(
                          showCheckboxColumn: false,
                          headingRowHeight: widget.headingRowHeight,
                          dataRowMinHeight: widget.dataRowMinHeight,
                          dataRowMaxHeight: widget.dataRowMaxHeight,
                          horizontalMargin: 0,
                          columnSpacing: 0,
                          sortColumnIndex: _internalSortColumnIndex,
                          sortAscending: _internalSortAscending,
                          columns: builtColumns,
                          rows: builtRows,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.enablePagination)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: PagedPaginationBar(
                    rowsPerPage: _rowsPerPage,
                    rowsPerPageOptions: widget.rowsPerPageOptions,
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    visibleRows: visibleData.length,
                    totalRows: allData.length,
                    paging: _paging,
                    onRowsPerPageChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _rowsPerPage = v;
                        _currentPage = 1;
                      });
                    },
                    onFirstPage: () => _goTo(1),
                    onPreviousPage: () => _goTo(_currentPage - 1),
                    onNextPage: () => _goTo(_currentPage + 1),
                    onLastPage: () => _goTo(totalPages),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<DataColumn> _buildColumns(bool hasActions, BuildContext context) {
    final cols = <DataColumn>[];

    for (var i = 0; i < widget.columns.length; i++) {
      final c = widget.columns[i];
      final width = _columnWidth(c);

      cols.add(
        DataColumn(
          label: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: c.headerBuilder != null
                  ? c.headerBuilder!(context)
                  : Align(
                alignment: _getAlignment(c.textAlign),
                child: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: c.textAlign,
                ),
              ),
            ),
          ),
          onSort: c.getter == null
              ? null
              : (columnIndex, ascending) {
            _handleSort(columnIndex, c.getter!);
          },
        ),
      );
    }

    if (hasActions) {
      cols.add(
        DataColumn(
          label: SizedBox(
            width: widget.actionsColumnWidth,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Center(
                child: Text(
                  'Ações',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return cols;
  }

  static Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return Alignment.centerLeft;
    }
  }

  static Widget _cellText(
      String text, {
        required BuildContext context,
        TextAlign align = TextAlign.left,
        double? maxW,
        int maxLines = 2,
      }) {
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(overflow: TextOverflow.ellipsis);

    final inner = Align(
      alignment: _getAlignment(align),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      ),
    );

    return maxW != null
        ? ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: inner,
    )
        : inner;
  }
}