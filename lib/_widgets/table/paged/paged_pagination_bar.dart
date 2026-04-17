import 'package:flutter/material.dart';

class PagedPaginationBar extends StatelessWidget {
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final int currentPage;
  final int totalPages;
  final int visibleRows;
  final int totalRows;
  final bool paging;
  final ValueChanged<int?> onRowsPerPageChanged;
  final VoidCallback? onFirstPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onLastPage;

  const PagedPaginationBar({
    super.key,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.currentPage,
    required this.totalPages,
    required this.visibleRows,
    required this.totalRows,
    required this.paging,
    required this.onRowsPerPageChanged,
    this.onFirstPage,
    this.onPreviousPage,
    this.onNextPage,
    this.onLastPage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTotalRows = totalRows < 0 ? 0 : totalRows;
    final resolvedVisibleRows = visibleRows < 0 ? 0 : visibleRows;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text('Linhas:'),
              DropdownButton<int>(
                underline: Container(),
                value: rowsPerPage,
                items: rowsPerPageOptions
                    .map(
                      (v) => DropdownMenuItem<int>(
                    value: v,
                    child: Text(
                      '$v',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
                    .toList(),
                onChanged: onRowsPerPageChanged,
              ),
              Text(
                '$resolvedVisibleRows de $resolvedTotalRows registros visíveis',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Primeira',
                onPressed: (!paging && currentPage > 1) ? onFirstPage : null,
                icon: const Icon(Icons.first_page),
              ),
              IconButton(
                tooltip: 'Anterior',
                onPressed: (!paging && currentPage > 1) ? onPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$currentPage',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: 'Próxima',
                onPressed:
                (!paging && currentPage < totalPages) ? onNextPage : null,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Última',
                onPressed:
                (!paging && currentPage < totalPages) ? onLastPage : null,
                icon: const Icon(Icons.last_page),
              ),
            ],
          ),
        ],
      ),
    );
  }
}