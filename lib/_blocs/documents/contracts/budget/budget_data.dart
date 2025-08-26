
class BudgetData {
  final List<List<String>> tableData;
  final List<String> colTypes;
  final List<double> colWidths;

  const BudgetData({
    required this.tableData,
    required this.colTypes,
    required this.colWidths,
  });

  bool get isEmpty => tableData.isEmpty;

  factory BudgetData.empty() =>
      const BudgetData(tableData: [], colTypes: [], colWidths: []);
}
