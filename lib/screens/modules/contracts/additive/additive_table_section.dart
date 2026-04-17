// lib/screens/contracts/additives/additive_table_section.dart
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class AdditiveTableSection extends StatelessWidget {
  final void Function(AdditivesData) onTapItem;
  final void Function(AdditivesData item) onDelete;
  final List<AdditivesData> additives;
  final bool isLoading;
  final AdditivesData? selectedItem;

  const AdditiveTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.additives,
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

  String _itemKey(AdditivesData item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return id;

    return [
      _intText(item.additiveOrder),
      _txt(item.additiveNumberProcess),
      _date(item.additiveDate),
      _money(item.additiveValue),
      _intText(item.additiveValidityContractDays),
      _intText(item.additiveValidityExecutionDays),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && additives.isEmpty) {
      return const LoadingProgress();
    }

    if (!isLoading && additives.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhum aditivo encontrado.'),
      );
    }

    return Stack(
      children: [
        PagedTableChanged<AdditivesData>(
          listData: additives,
          getKey: _itemKey,
          selectedKey: selectedItem != null ? _itemKey(selectedItem!) : null,
          keepSelectionInternally: false,
          enableRowTapSelection: true,
          enablePagination: false,
          initialRowsPerPage: 10,
          rowsPerPageOptions: const [10, 25, 50, 100],
          sortColumnIndex: 0,
          sortAscending: true,
          minTableWidth: 906,
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
            PagedColum<AdditivesData>(
              title: 'ORDEM',
              getter: (a) => _intText(a.additiveOrder),
              textAlign: TextAlign.center,
              width: 100,
            ),
            PagedColum<AdditivesData>(
              title: 'Nº PROCESSO',
              getter: (a) => _txt(a.additiveNumberProcess),
              textAlign: TextAlign.center,
              width: 200,
            ),
            PagedColum<AdditivesData>(
              title: 'DATA DO ADITIVO',
              getter: (a) => _date(a.additiveDate),
              textAlign: TextAlign.center,
              width: 150,
            ),
            PagedColum<AdditivesData>(
              title: 'VALOR DO ADITIVO',
              getter: (a) => _money(a.additiveValue),
              textAlign: TextAlign.center,
              width: 200,
            ),
            PagedColum<AdditivesData>(
              title: 'VALIDADE DO CONTRATO',
              getter: (a) => _intText(a.additiveValidityContractDays),
              textAlign: TextAlign.center,
              width: 150,
            ),
            PagedColum<AdditivesData>(
              title: 'VALIDADE DA EXECUÇÃO',
              getter: (a) => _intText(a.additiveValidityExecutionDays),
              textAlign: TextAlign.center,
              width: 150,
            ),
          ],
        ),

        if (isLoading && additives.isNotEmpty)
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