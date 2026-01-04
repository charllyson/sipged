import 'package:flutter/material.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

/// ===== Especificação de coluna =====
class PagedColumnSpec<T> {
  final String title;
  final String Function(T item)? getter;
  final Widget Function(T item)? cellBuilder;
  final TextAlign textAlign;
  final double? maxWidth;

  const PagedColumnSpec({
    required this.title,
    this.getter,
    this.cellBuilder,
    this.textAlign = TextAlign.left,
    this.maxWidth,
  });
}

/// ===== Tabela paginada genérica =====
class PagedTableChanged<T> extends StatefulWidget {
  final List<T> listData;

  final String Function(T item)? getKey;
  final String? selectedKey;
  final bool keepSelectionInternally;
  final void Function(T item)? onTapItem;
  final void Function(T item)? onDelete;

  final List<PagedColumnSpec<T>> columns;
  final Widget Function(T item)? leadingCell;
  final String? leadingTitle;

  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending, String Function(T) getter)? onSort;

  final String Function(T item)? groupBy;
  final String? groupLabel;

  final int currentPage;
  final int totalPages;
  final Future<void> Function(int page) onPageChange;

  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;
  final EdgeInsetsGeometry cardMargin;
  final double elevation;
  final bool showCheckboxColumn;
  final Color colorHeadTable;
  final Color colorHeadTableText;
  final String? statusLabel;

  const PagedTableChanged({
    super.key,
    required this.listData,
    required this.columns,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
    this.getKey,
    this.selectedKey,
    this.keepSelectionInternally = true,
    this.onTapItem,
    this.onDelete,
    this.leadingCell,
    this.leadingTitle,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.groupBy,
    this.groupLabel,
    this.headingRowHeight = 44,
    this.dataRowMinHeight = 40,
    this.dataRowMaxHeight = 60,
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.elevation = 0,
    this.showCheckboxColumn = false,
    this.colorHeadTable = const Color(0xFF091D68),
    this.colorHeadTableText = Colors.white,
    this.statusLabel,
  });

  @override
  State<PagedTableChanged<T>> createState() => _PagedTableChangedState<T>();
}

class _PagedTableChangedState<T> extends State<PagedTableChanged<T>> {
  String? _internalSelectedKey;
  bool _paging = false;

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
    final shouldDelete = await showWindowDialogMac<bool>(
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

  Future<void> _goTo(int page) async {
    if (_paging || page == widget.currentPage) return;
    setState(() => _paging = true);
    try {
      await widget.onPageChange(page);
    } finally {
      if (mounted) setState(() => _paging = false);
    }
  }

  List<_RowChunk<T>> _buildRowChunks(List<T> data) {
    if (widget.groupBy == null) {
      return [
        _RowChunk(type: _RowChunkType.normal, items: data),
      ];
    }
    final map = <String, List<T>>{};
    for (final item in data) {
      final key = widget.groupBy!(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    final chunks = <_RowChunk<T>>[];
    for (final entry in map.entries) {
      chunks.add(
        _RowChunk(type: _RowChunkType.groupHeader, groupKey: entry.key),
      );
      chunks.add(
        _RowChunk(type: _RowChunkType.normal, items: entry.value),
      );
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.listData;
    final chunks = _buildRowChunks(data);

    final hasLeading = widget.leadingCell != null;
    final hasActions = widget.onDelete != null || widget.onTapItem != null;
    final totalColumns =
        (hasLeading ? 1 : 0) + widget.columns.length + (hasActions ? 1 : 0);
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      elevation: widget.elevation,
      margin: widget.cardMargin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, cons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.statusLabel != null)
                Padding(
                  padding:
                  const EdgeInsets.only(top: 12, left: 12, right: 12),
                  child: Text(
                    '${widget.statusLabel} - (${data.length}) registros',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              if (data.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Text(
                    'Nenhum registro encontrado.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (data.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: cons.maxWidth),
                    child: DataTableTheme(
                      data: DataTableThemeData(
                        headingRowColor:
                        MaterialStateProperty.all(widget.colorHeadTable),
                        headingTextStyle: TextStyle(
                          color: widget.colorHeadTableText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        dataRowColor: MaterialStateProperty.resolveWith(
                              (states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.blue.withOpacity(0.05);
                            }
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xFFE1F5FE);
                            }
                            return Colors.white;
                          },
                        ),
                        dataTextStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      child: DataTable(
                        showCheckboxColumn: widget.showCheckboxColumn,
                        headingRowHeight: widget.headingRowHeight,
                        dataRowMinHeight: widget.dataRowMinHeight,
                        dataRowMaxHeight: widget.dataRowMaxHeight,
                        sortColumnIndex: widget.sortColumnIndex,
                        sortAscending: widget.sortAscending,
                        columns: _buildColumns(hasLeading, hasActions),
                        rows: chunks.expand((chunk) {
                          if (chunk.type == _RowChunkType.groupHeader) {
                            return [
                              DataRow(
                                color: MaterialStateProperty.all(
                                  Colors.grey.shade200,
                                ),
                                cells: List.generate(totalColumns, (i) {
                                  if (i == 0) {
                                    return DataCell(
                                      Text(
                                        '${widget.groupLabel ?? ''}: ${chunk.groupKey ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  return const DataCell(SizedBox.shrink());
                                }),
                              ),
                            ];
                          } else {
                            return chunk.items!.map((item) {
                              final isSelected = _isSelected(item);
                              final cells = <DataCell>[];

                              if (hasLeading) {
                                cells.add(
                                  DataCell(widget.leadingCell!(item)),
                                );
                              }

                              // --- Renderiza cada coluna ---
                              for (final c in widget.columns) {
                                if (c.cellBuilder != null) {
                                  cells.add(
                                    DataCell(c.cellBuilder!(item)),
                                  );
                                } else if (c.getter != null) {
                                  cells.add(
                                    DataCell(
                                      _cellText(
                                        c.getter!(item),
                                        context: context,
                                        align: c.textAlign,
                                        maxW: c.maxWidth,
                                      ),
                                    ),
                                  );
                                } else {
                                  cells.add(const DataCell(Text('')));
                                }
                              }

                              if (hasActions) {
                                cells.add(
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.onTapItem != null)
                                          IconButton(
                                            tooltip: 'Selecionar',
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                            ),
                                            onPressed: () =>
                                                _handleTap(item),
                                          ),
                                        if (widget.onDelete != null)
                                          IconButton(
                                            tooltip: 'Excluir',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () =>
                                                _confirmarExclusao(
                                                  context,
                                                  item,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: (_) => _handleTap(item),
                                cells: cells,
                              );
                            });
                          }
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _buildPagination(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text('Página ${widget.currentPage} de ${widget.totalPages}'),
          const Spacer(),
          IconButton(
            tooltip: 'Primeira',
            onPressed: (!_paging && widget.currentPage > 1)
                ? () => _goTo(1)
                : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Anterior',
            onPressed: (!_paging && widget.currentPage > 1)
                ? () => _goTo(widget.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Próxima',
            onPressed: (!_paging && widget.currentPage < widget.totalPages)
                ? () => _goTo(widget.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Última',
            onPressed: (!_paging && widget.currentPage < widget.totalPages)
                ? () => _goTo(widget.totalPages)
                : null,
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns(bool hasLeading, bool hasActions) {
    final cols = <DataColumn>[];
    if (hasLeading) {
      cols.add(
        DataColumn(
          label: Center(
            child: Text(widget.leadingTitle ?? ''),
          ),
        ),
      );
    }
    for (var i = 0; i < widget.columns.length; i++) {
      final c = widget.columns[i];
      cols.add(
        DataColumn(
          label: Center(child: Text(c.title)),
          onSort: (widget.onSort == null || c.getter == null)
              ? null
              : (columnIndex, ascending) {
            widget.onSort!.call(columnIndex, ascending, c.getter!);
          },
        ),
      );
    }
    if (hasActions) {
      cols.add(
        const DataColumn(
          label: Center(child: Text('Ações')),
        ),
      );
    }
    return cols;
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
    final inner = Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: style,
    );
    return maxW != null
        ? ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: inner,
    )
        : inner;
  }
}

/// Suporte interno para grupos
enum _RowChunkType { groupHeader, normal }

class _RowChunk<T> {
  final _RowChunkType type;
  final String? groupKey;
  final List<T>? items;

  _RowChunk({
    required this.type,
    this.groupKey,
    this.items,
  });
}
