
class GeoWorkspaceDataTable {
  final String? title;
  final List<String> columns;
  final List<Map<String, String>> rows;

  const GeoWorkspaceDataTable({
    this.title,
    this.columns = const [],
    this.rows = const [],
  });

  bool get hasData => columns.isNotEmpty && rows.isNotEmpty;
}