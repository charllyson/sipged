import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_data.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class EmpenhoTableSection extends StatelessWidget {
  final List<EmpenhoData> items;
  final EmpenhoData? selected;
  final NumberFormat currency;
  final void Function(EmpenhoData e) onSelect;
  final Future<void> Function(EmpenhoData e)? onDelete;

  const EmpenhoTableSection({
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

  String _itemKey(EmpenhoData item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return id;

    return [
      _s(item.numero),
      _s(item.demandLabel),
      _s(item.companyLabel),
      _s(item.fundingSourceLabel),
      DateFormat('dd/MM/yyyy').format(item.date),
      currency.format(item.empenhadoTotal),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    return PagedTableChanged<EmpenhoData>(
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
      minTableWidth: 1316,
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
        PagedColum<EmpenhoData>(
          title: 'NÚMERO',
          getter: (e) => _s(e.numero),
          textAlign: TextAlign.center,
          width: 140,
        ),
        PagedColum<EmpenhoData>(
          title: 'CREDITADO EM',
          getter: (e) => _s(e.demandLabel),
          textAlign: TextAlign.left,
          width: 360,
        ),
        PagedColum<EmpenhoData>(
          title: 'CONTRATANTE',
          getter: (e) => _s(e.companyLabel),
          textAlign: TextAlign.center,
          width: 220,
        ),
        PagedColum<EmpenhoData>(
          title: 'FONTE',
          getter: (e) => _s(e.fundingSourceLabel),
          textAlign: TextAlign.center,
          width: 220,
        ),
        PagedColum<EmpenhoData>(
          title: 'DATA',
          getter: (e) => DateFormat('dd/MM/yyyy').format(e.date),
          textAlign: TextAlign.center,
          width: 120,
        ),
        PagedColum<EmpenhoData>(
          title: 'VALOR',
          getter: (e) => currency.format(e.empenhadoTotal),
          textAlign: TextAlign.right,
          width: 140,
        ),
      ],
    );
  }
}