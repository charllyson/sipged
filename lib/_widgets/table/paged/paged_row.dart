import 'package:sipged/_widgets/table/paged/paged_table_metrics.dart';

class PagedRow<T> {
  final RowType type;
  final String? groupKey;
  final List<T>? items;

  PagedRow({
    required this.type,
    this.groupKey,
    this.items,
  });
}