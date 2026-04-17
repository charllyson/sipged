import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class BudgetTableSection extends StatelessWidget {
  final List<BudgetData> items;
  final BudgetData? selected;
  final NumberFormat currency;
  final void Function(BudgetData e) onSelect;
  final Future<void> Function(BudgetData e)? onDelete;

  const BudgetTableSection({
    super.key,
    required this.items,
    required this.selected,
    required this.currency,
    required this.onSelect,
    this.onDelete,
  });

  String _s(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return '-';
    return value;
  }

  String _itemKey(BudgetData item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return id;

    return [
      item.year.toString(),
      _s(item.companyLabel),
      _s(item.fundingSourceLabel),
      _s(item.budgetCode),
      _s(item.description),
      currency.format(item.amount),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    return PagedTableChanged<BudgetData>(
      listData: items,
      getKey: _itemKey,
      selectedKey: selected != null ? _itemKey(selected!) : null,
      keepSelectionInternally: false,
      enableRowTapSelection: true,
      enablePagination: false,
      initialRowsPerPage: 10,
      rowsPerPageOptions: const [10, 25, 50, 100],
      sortColumnIndex: 0,
      sortAscending: true,
      minTableWidth: 1366,
      defaultColumnWidth: 160,
      actionsColumnWidth: onDelete != null ? 56 : 0,
      colorHeadTable: const Color(0xFF091D68),
      colorHeadTableText: Colors.white,
      headingRowHeight: 40,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 56,
      onTapItem: onSelect,
      onDelete: onDelete == null ? null : (e) => onDelete!(e),
      columns: [
        PagedColum<BudgetData>(
          title: 'EXERCÍCIO',
          getter: (e) => e.year.toString(),
          textAlign: TextAlign.center,
          width: 110,
        ),
        PagedColum<BudgetData>(
          title: 'CONTRATANTE',
          getter: (e) => _s(e.companyLabel),
          textAlign: TextAlign.center,
          width: 260,
        ),
        PagedColum<BudgetData>(
          title: 'FONTE',
          getter: (e) => _s(e.fundingSourceLabel),
          textAlign: TextAlign.center,
          width: 220,
        ),
        PagedColum<BudgetData>(
          title: 'CÓDIGO',
          getter: (e) => _s(e.budgetCode),
          textAlign: TextAlign.center,
          width: 160,
        ),
        PagedColum<BudgetData>(
          title: 'DESCRIÇÃO',
          getter: (e) => _s(e.description),
          textAlign: TextAlign.left,
          width: 420,
        ),
        PagedColum<BudgetData>(
          title: 'VALOR',
          getter: (e) => currency.format(e.amount),
          textAlign: TextAlign.right,
          width: 140,
        ),
      ],
    );
  }
}