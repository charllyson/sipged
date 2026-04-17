import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class ValidityTableSection extends StatelessWidget {
  final void Function(ValidityData) onTapItem;
  final Future<void> Function(String validityId) onDelete;
  final List<ValidityData> validities;
  final ValidityData? selectedItem;

  const ValidityTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.validities,
    this.selectedItem,
  });

  String _txt(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '-';
    return text;
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
    return SipGedFormatDates.dateToDdMMyyyy(value);
  }

  String _itemKey(ValidityData item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return id;

    return [
      item.orderNumber?.toString() ?? '-',
      _txt(item.ordertype),
      _date(item.orderdate),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    if (validities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('Nenhuma ordem encontrada.'),
      );
    }

    return PagedTableChanged<ValidityData>(
      listData: validities,
      getKey: _itemKey,
      selectedKey: selectedItem != null ? _itemKey(selectedItem!) : null,
      keepSelectionInternally: false,
      enableRowTapSelection: true,
      enablePagination: false,
      initialRowsPerPage: 10,
      rowsPerPageOptions: const [10, 25, 50, 100],
      sortColumnIndex: 0,
      sortAscending: true,
      minTableWidth: 576,
      defaultColumnWidth: 150,
      actionsColumnWidth: 56,
      colorHeadTable: const Color(0xFF091D68),
      colorHeadTableText: Colors.white,
      headingRowHeight: 40,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 56,
      onTapItem: onTapItem,
      onDelete: (item) async {
        final id = (item.id ?? '').trim();
        if (id.isNotEmpty) {
          await onDelete(id);
        }
      },
      columns: [
        PagedColum<ValidityData>(
          title: 'ORDEM',
          getter: (item) => item.orderNumber?.toString() ?? '-',
          textAlign: TextAlign.center,
          width: 80,
        ),
        PagedColum<ValidityData>(
          title: 'TIPO DA ORDEM',
          getter: (item) => _txt(item.ordertype),
          textAlign: TextAlign.left,
          width: 260,
        ),
        PagedColum<ValidityData>(
          title: 'DATA DA ORDEM',
          getter: (item) => _date(item.orderdate),
          textAlign: TextAlign.center,
          width: 180,
        ),
      ],
    );
  }
}