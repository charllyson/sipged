// lib/_widgets/table/paged/paged_table_changed.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_pagination_bar.dart';
import 'package:sipged/_widgets/table/paged/paged_row.dart';
import 'package:sipged/_widgets/table/paged/paged_table_metrics.dart';

class PagedTableChanged<T> extends StatefulWidget {
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
    this.rowsPerPageOptions = const <int>[10, 25, 50, 100],
    this.initialRowsPerPage = 25,
    this.enablePagination = true,
    this.onMetricsChanged,

    // EXPANSÃO EM SUB-LINHAS
    this.enableExpandableRows = false,
    this.expandColumnWidth = 56,
    this.expandableRowBuilder,
    this.canExpandRow,
    this.initialExpandedKeys = const <String>{},
    this.onExpandedChanged,

    // DISTRIBUIÇÃO DAS COLUNAS
    this.distributeColumns = true,
  });

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

  final bool enableExpandableRows;
  final double expandColumnWidth;
  final Widget Function(BuildContext context, T item)? expandableRowBuilder;
  final bool Function(T item)? canExpandRow;
  final Set<String> initialExpandedKeys;
  final void Function(T item, bool expanded)? onExpandedChanged;
  final bool distributeColumns;

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

  late Set<String> _expandedKeys;

  late final ScrollController _horizontalCtrl;
  PagedTableMetrics? _lastMetrics;

  @override
  void initState() {
    super.initState();

    _horizontalCtrl = ScrollController(
      keepScrollOffset: false,
    );

    _rowsPerPage = widget.rowsPerPageOptions.contains(widget.initialRowsPerPage)
        ? widget.initialRowsPerPage
        : widget.rowsPerPageOptions.first;

    _currentPage = 1;
    _internalSortColumnIndex = widget.sortColumnIndex;
    _internalSortAscending = widget.sortAscending;
    _expandedKeys = Set<String>.from(widget.initialExpandedKeys);
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

    if (oldWidget.initialExpandedKeys != widget.initialExpandedKeys) {
      _expandedKeys = Set<String>.from(widget.initialExpandedKeys);
    }
  }

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    super.dispose();
  }

  String? _keyOf(T item) {
    final rawKey = widget.getKey?.call(item);
    final key = rawKey?.trim();

    if (key == null || key.isEmpty) return null;

    return key;
  }

  bool _isSelected(T item) {
    final key = _keyOf(item);
    final activeKey = widget.keepSelectionInternally
        ? (_internalSelectedKey ?? widget.selectedKey)
        : widget.selectedKey;

    return key != null && activeKey != null && key == activeKey;
  }

  bool _canExpand(T item) {
    if (!widget.enableExpandableRows) return false;
    if (widget.expandableRowBuilder == null) return false;

    final key = _keyOf(item);
    if (key == null || key.trim().isEmpty) return false;

    final checker = widget.canExpandRow;
    if (checker == null) return true;

    return checker(item);
  }

  bool _isExpanded(T item) {
    final key = _keyOf(item);
    if (key == null || key.trim().isEmpty) return false;

    return _expandedKeys.contains(key);
  }

  void _toggleExpanded(T item) {
    if (!_canExpand(item)) return;

    final key = _keyOf(item);
    if (key == null || key.trim().isEmpty) return;

    final willExpand = !_expandedKeys.contains(key);

    setState(() {
      if (willExpand) {
        _expandedKeys.add(key);
      } else {
        _expandedKeys.remove(key);
      }
    });

    widget.onExpandedChanged?.call(item, willExpand);
  }

  void _handleTap(T item) {
    final key = _keyOf(item);

    if (widget.keepSelectionInternally && key != null) {
      setState(() => _internalSelectedKey = key);
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

    if (!mounted) return;

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

  bool get _showGroups {
    return widget.groupBy != null && widget.groupLabel != null;
  }

  String _resolveGroupKey(T item) {
    final key = widget.groupBy?.call(item).trim() ?? '';

    return key.isEmpty ? 'Sem grupo' : key;
  }

  List<PagedRow<T>> _buildRowChunks(List<T> data) {
    if (!_showGroups) {
      return <PagedRow<T>>[
        PagedRow<T>(
          type: RowType.normal,
          items: data,
        ),
      ];
    }

    final map = <String, List<T>>{};

    for (final item in data) {
      final key = _resolveGroupKey(item);
      map.putIfAbsent(key, () => <T>[]).add(item);
    }

    final chunks = <PagedRow<T>>[];

    for (final entry in map.entries) {
      chunks.add(
        PagedRow<T>(
          type: RowType.groupHeader,
          groupKey: entry.key,
        ),
      );

      chunks.add(
        PagedRow<T>(
          type: RowType.normal,
          items: entry.value,
        ),
      );
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

    final realColumnIndex =
    widget.enableExpandableRows ? sortIndex - 1 : sortIndex;

    if (realColumnIndex < 0 || realColumnIndex >= widget.columns.length) {
      return List<T>.from(source);
    }

    final column = widget.columns[realColumnIndex];
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

    final an = num.tryParse(
      aa
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim(),
    );

    final bn = num.tryParse(
      bb
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim(),
    );

    if (an != null && bn != null) {
      return an.compareTo(bn);
    }

    final ad = DateTime.tryParse(aa);
    final bd = DateTime.tryParse(bb);

    if (ad != null && bd != null) {
      return ad.compareTo(bd);
    }

    return aa.toLowerCase().compareTo(bb.toLowerCase());
  }

  double _baseColumnWidth(PagedColum<T> column) {
    return column.width ?? column.maxWidth ?? widget.defaultColumnWidth;
  }

  double _baseTableWidth(bool hasActions) {
    double total = 0;

    if (widget.enableExpandableRows) {
      total += widget.expandColumnWidth;
    }

    for (final column in widget.columns) {
      total += _baseColumnWidth(column);
    }

    if (hasActions) {
      total += widget.actionsColumnWidth;
    }

    return total;
  }

  double _totalTableWidth(bool hasActions) {
    final total = _baseTableWidth(hasActions);

    return total < widget.minTableWidth ? widget.minTableWidth : total;
  }

  List<double> _resolvedColumnWidths({
    required double tableWidth,
    required bool hasActions,
  }) {
    final baseWidths = widget.columns
        .map((column) => _baseColumnWidth(column))
        .toList(growable: false);

    if (!widget.distributeColumns || baseWidths.isEmpty) {
      return baseWidths;
    }

    final reservedWidth =
        (widget.enableExpandableRows ? widget.expandColumnWidth : 0.0) +
            (hasActions ? widget.actionsColumnWidth : 0.0);

    final availableForDataColumns = tableWidth - reservedWidth;

    final baseDataWidth = baseWidths.fold<double>(
      0.0,
          (previous, value) => previous + value,
    );

    if (availableForDataColumns <= baseDataWidth) {
      return baseWidths;
    }

    final extra = availableForDataColumns - baseDataWidth;
    final extraPerColumn = extra / baseWidths.length;

    return baseWidths
        .map((width) => width + extraPerColumn)
        .toList(growable: false);
  }

  int _visualColumnIndexForDataColumn(int dataColumnIndex) {
    return widget.enableExpandableRows ? dataColumnIndex + 1 : dataColumnIndex;
  }

  @override
  Widget build(BuildContext context) {
    final sortedData = _sortedData(widget.listData);
    final allData = sortedData;
    final visibleData = _visibleData(allData);
    final chunks = _buildRowChunks(visibleData);
    final hasActions = widget.onDelete != null;
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

        final resolvedWidths = _resolvedColumnWidths(
          tableWidth: renderWidth,
          hasActions: hasActions,
        );

        return Column(
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
                  key: ValueKey<String>(
                    'paged_table_horizontal_scroll_${widget.hashCode}',
                  ),
                  controller: _horizontalCtrl,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  restorationId: null,
                  physics: needsHorizontalScroll
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: renderWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderRow(
                          context: context,
                          hasActions: hasActions,
                          tableWidth: renderWidth,
                          resolvedWidths: resolvedWidths,
                        ),
                        ..._buildBodyRows(
                          context: context,
                          chunks: chunks,
                          hasActions: hasActions,
                          tableWidth: renderWidth,
                          resolvedWidths: resolvedWidths,
                        ),
                      ],
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
                  onRowsPerPageChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _rowsPerPage = value;
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
        );
      },
    );
  }

  Widget _buildHeaderRow({
    required BuildContext context,
    required bool hasActions,
    required double tableWidth,
    required List<double> resolvedWidths,
  }) {
    return Container(
      width: tableWidth,
      height: widget.headingRowHeight,
      decoration: BoxDecoration(
        color: widget.colorHeadTable,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          if (widget.enableExpandableRows)
            SizedBox(
              width: widget.expandColumnWidth,
              child: const Center(
                child: Icon(
                  Icons.unfold_more_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          for (var index = 0; index < widget.columns.length; index++)
            _buildHeaderCell(
              context: context,
              dataColumnIndex: index,
              column: widget.columns[index],
              width: resolvedWidths[index],
            ),
          if (hasActions)
            SizedBox(
              width: widget.actionsColumnWidth,
              child: Center(
                child: Text(
                  'Ações',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.colorHeadTableText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell({
    required BuildContext context,
    required int dataColumnIndex,
    required PagedColum<T> column,
    required double width,
  }) {
    final visualColumnIndex = _visualColumnIndexForDataColumn(dataColumnIndex);
    final sortable = column.getter != null;
    final sorted = _internalSortColumnIndex == visualColumnIndex;

    final child = column.headerBuilder != null
        ? column.headerBuilder!(context)
        : Align(
      alignment: _getAlignment(column.textAlign),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              column.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: column.textAlign,
              style: TextStyle(
                color: widget.colorHeadTableText,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: 4),
            Icon(
              sorted
                  ? (_internalSortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: sorted ? 16 : 15,
              color: widget.colorHeadTableText.withValues(
                alpha: sorted ? 1.0 : 0.62,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: sortable
            ? () => _handleSort(
          visualColumnIndex,
          column.getter!,
        )
            : null,
        child: SizedBox(
          width: width,
          height: widget.headingRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBodyRows({
    required BuildContext context,
    required List<PagedRow<T>> chunks,
    required bool hasActions,
    required double tableWidth,
    required List<double> resolvedWidths,
  }) {
    final rows = <Widget>[];

    for (final chunk in chunks) {
      if (chunk.type == RowType.groupHeader) {
        rows.add(
          Container(
            width: tableWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Text(
              '${widget.groupLabel ?? 'Grupo'}: ${chunk.groupKey ?? ''}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

        continue;
      }

      final items = chunk.items ?? <T>[];

      for (final item in items) {
        final selected = _isSelected(item);
        final expanded = _isExpanded(item);
        final canExpand = _canExpand(item);

        rows.add(
          _buildDataRow(
            context: context,
            item: item,
            selected: selected,
            expanded: expanded,
            canExpand: canExpand,
            hasActions: hasActions,
            tableWidth: tableWidth,
            resolvedWidths: resolvedWidths,
          ),
        );

        if (expanded && widget.expandableRowBuilder != null) {
          rows.add(
            _buildExpandedRow(
              context: context,
              item: item,
              tableWidth: tableWidth,
            ),
          );
        }
      }
    }

    return rows;
  }

  Widget _buildDataRow({
    required BuildContext context,
    required T item,
    required bool selected,
    required bool expanded,
    required bool canExpand,
    required bool hasActions,
    required double tableWidth,
    required List<double> resolvedWidths,
  }) {
    final rowColor = selected ? const Color(0xFFE1F5FE) : Colors.white;

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: widget.enableRowTapSelection ? () => _handleTap(item) : null,
        hoverColor: Colors.blue.withValues(alpha: 0.05),
        child: Container(
          width: tableWidth,
          constraints: BoxConstraints(
            minHeight: widget.dataRowMinHeight,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 0.7,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.enableExpandableRows)
                SizedBox(
                  width: widget.expandColumnWidth,
                  child: Center(
                    child: IconButton(
                      tooltip: expanded ? 'Recolher' : 'Expandir',
                      onPressed: canExpand ? () => _toggleExpanded(item) : null,
                      icon: Icon(
                        expanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        color: canExpand
                            ? const Color(0xFF091D68)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              for (var index = 0; index < widget.columns.length; index++)
                _buildDataCell(
                  context: context,
                  item: item,
                  column: widget.columns[index],
                  width: resolvedWidths[index],
                ),
              if (hasActions)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell({
    required BuildContext context,
    required T item,
    required PagedColum<T> column,
    required double width,
  }) {
    Widget child;

    if (column.cellBuilder != null) {
      child = column.cellBuilder!(item);
    } else if (column.getter != null) {
      child = _cellText(
        column.getter!(item),
        context: context,
        align: column.textAlign,
        maxW: column.maxWidth ?? width,
      );
    } else {
      child = const SizedBox.shrink();
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: child,
      ),
    );
  }

  Widget _buildExpandedRow({
    required BuildContext context,
    required T item,
    required double tableWidth,
  }) {
    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.7,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: tableWidth,
        child: widget.expandableRowBuilder!(context, item),
      ),
    );
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
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      overflow: TextOverflow.ellipsis,
    );

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