import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class ReportMeasurementTableSection extends StatelessWidget {
  final void Function(ReportMeasurementData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<ReportMeasurementData> measurementsData;
  final ReportMeasurementData? selectedMeasurement;
  final ProcessData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  const ReportMeasurementTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.measurementsData,
    required this.selectedMeasurement,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotal,
    required this.saldo,
    this.contractData,
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

  String _itemKey(ReportMeasurementData item) {
    final id = (item.id ?? '').trim();
    if (id.isNotEmpty) return id;

    return [
      _intText(item.order),
      _txt(item.numberprocess),
      _date(item.date),
      _money(item.value),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final totalReports = measurementsData.fold<double>(
      0.0,
          (prev, item) => prev + (item.value ?? 0.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedTableChanged<ReportMeasurementData>(
          listData: measurementsData,
          getKey: _itemKey,
          selectedKey:
          selectedMeasurement != null ? _itemKey(selectedMeasurement!) : null,
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
          onDelete: (item) {
            final id = (item.id ?? '').trim();
            if (id.isNotEmpty) {
              onDelete(id);
            }
          },
          columns: [
            PagedColum<ReportMeasurementData>(
              title: 'ORDEM',
              getter: (a) => _intText(a.order),
              textAlign: TextAlign.center,
              width: 100,
            ),
            PagedColum<ReportMeasurementData>(
              title: 'Nº PROCESSO',
              getter: (a) => _txt(a.numberprocess),
              textAlign: TextAlign.center,
              width: 200,
            ),
            PagedColum<ReportMeasurementData>(
              title: 'DATA DA MEDIÇÃO',
              getter: (a) => _date(a.date),
              textAlign: TextAlign.center,
              width: 150,
            ),
            PagedColum<ReportMeasurementData>(
              title: 'VALOR DA MEDIÇÃO',
              getter: (a) => _money(a.value),
              textAlign: TextAlign.center,
              width: 200,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryBox(
          items: [
            _SummaryItem(
              label: 'TOTAL DOS BOLETINS',
              value: totalReports,
              backgroundColor: Colors.grey.shade200,
              fontWeight: FontWeight.w700,
            ),
            _SummaryItem(
              label: 'VALOR CONTRATADO',
              value: valorInicial,
            ),
            _SummaryItem(
              label: 'VALOR DOS ADITIVOS',
              value: valorAditivos,
            ),
            _SummaryItem(
              label: 'VALOR CONTRATADO + ADITIVOS',
              value: valorTotal,
            ),
            _SummaryItem(
              label: 'SALDO DO CONTRATO',
              value: saldo,
              backgroundColor: Colors.blue.shade100,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String label;
  final double value;
  final Color? backgroundColor;
  final FontWeight? fontWeight;

  _SummaryItem({
    required this.label,
    required this.value,
    this.backgroundColor,
    this.fontWeight,
  });
}

class _SummaryBox extends StatelessWidget {
  final List<_SummaryItem> items;

  const _SummaryBox({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (e) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: e.backgroundColor ?? Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  e.label,
                  style: TextStyle(fontWeight: e.fontWeight),
                ),
              ),
              Text(
                SipGedFormatMoney.doubleToText(e.value),
                style: TextStyle(fontWeight: e.fontWeight),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}