import 'package:flutter/material.dart';
enum RowType { groupHeader, normal }

@immutable
class PagedTableMetrics {
  final int totalRows;
  final int visibleRows;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;

  const PagedTableMetrics({
    required this.totalRows,
    required this.visibleRows,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
  });

  @override
  bool operator ==(Object other) {
    return other is PagedTableMetrics &&
        other.totalRows == totalRows &&
        other.visibleRows == visibleRows &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.rowsPerPage == rowsPerPage;
  }

  @override
  int get hashCode => Object.hash(
    totalRows,
    visibleRows,
    currentPage,
    totalPages,
    rowsPerPage,
  );
}
