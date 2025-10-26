// lib/_widgets/table/magic/magic_adapter.dart
import 'package:siged/_blocs/process/budget/budget_data.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;

class MagicAdapter {
  /// Carrega controller a partir do domínio
  static void loadControllerFromDomain({
    required bc.MagicTableController controller,
    required BudgetData data,
  }) {
    final table = data.toTableData();
    controller.loadFromSnapshot(
      table: table,
      colTypesAsString: data.schema.headerTypes,
      widths: data.schema.headerWidths,
    );
  }

  /// Constrói domínio a partir do controller (mantém parsing legado)
  static BudgetData buildDomainFromController({
    required bc.MagicTableController controller,
  }) {
    final headers = controller.headers;
    final types = controller.colTypesAsString;
    final widths = controller.colWidths;
    final table = controller.tableData;

    return BudgetData.fromLegacy(
      headers: headers,
      colTypes: types,
      colWidths: widths,
      tableData: table,
    );
  }
}
