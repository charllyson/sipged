import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class ApostilleTableSection extends StatelessWidget {
  final void Function(ApostillesData) onTapItem;
  final void Function(ApostillesData item) onDelete;
  final List<ApostillesData> apostilles;
  final bool isLoading;
  final ApostillesData? selectedItem;

  const ApostilleTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.apostilles,
    required this.isLoading,
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

  String _money(double? value) {
    if (value == null) return '-';
    return SipGedFormatMoney.doubleToText(value);
  }

  String _intText(int? value) {
    if (value == null) return '-';
    return value.toString();
  }

  String _itemKey(ApostillesData item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return id;

    return [
      _intText(item.apostilleOrder),
      _txt(item.apostilleNumberProcess),
      _date(item.apostilleData),
      _money(item.apostilleValue),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && apostilles.isEmpty) {
      return const LoadingProgress();
    }

    if (!isLoading && apostilles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhum apostilamento encontrado.'),
      );
    }

    return Stack(
      children: [
        PagedTableChanged<ApostillesData>(
          listData: apostilles,
          getKey: _itemKey,
          selectedKey: selectedItem != null ? _itemKey(selectedItem!) : null,
          keepSelectionInternally: false,
          enableRowTapSelection: true,
          enablePagination: false,
          initialRowsPerPage: 10,
          rowsPerPageOptions: const [10, 25, 50, 100],
          sortColumnIndex: 0,
          sortAscending: true,
          minTableWidth: 706,
          defaultColumnWidth: 150,
          actionsColumnWidth: 56,
          colorHeadTable: const Color(0xFF091D68),
          colorHeadTableText: Colors.white,
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          onTapItem: onTapItem,
          onDelete: onDelete,
          columns: [
            PagedColum<ApostillesData>(
              title: 'ORDEM',
              getter: (a) => _intText(a.apostilleOrder),
              textAlign: TextAlign.center,
              width: 100,
            ),
            PagedColum<ApostillesData>(
              title: 'Nº PROCESSO',
              getter: (a) => _txt(a.apostilleNumberProcess),
              textAlign: TextAlign.center,
              width: 200,
            ),
            PagedColum<ApostillesData>(
              title: 'DATA',
              getter: (a) => _date(a.apostilleData),
              textAlign: TextAlign.center,
              width: 150,
            ),
            PagedColum<ApostillesData>(
              title: 'VALOR',
              getter: (a) => _money(a.apostilleValue),
              textAlign: TextAlign.center,
              width: 200,
            ),
          ],
        ),
        if (isLoading && apostilles.isNotEmpty)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.65),
              alignment: Alignment.center,
              child: const LoadingProgress(),
            ),
          ),
      ],
    );
  }
}