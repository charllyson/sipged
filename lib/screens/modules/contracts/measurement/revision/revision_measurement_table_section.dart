import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class RevisionMeasurementTableSection extends StatelessWidget {
  const RevisionMeasurementTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,

    /// Padrão novo.
    this.revisionMeasurementsData,
    this.selectedRevisionMeasurement,

    /// Compatibilidade com padrão antigo.
    this.measurementsData,
    this.selectedMeasurement,

    required this.valorTotal,
    this.balance,

    /// Compatibilidade com padrão antigo.
    this.saldo,

    /// Mantidos somente para compatibilidade visual/cálculo antigo.
    this.valorInicial = 0.0,
    this.valorAditivos = 0.0,
    this.contractData,
  });

  final void Function(RevisionMeasurementData) onTapItem;
  final void Function(String revisionId) onDelete;

  /// Padrão novo.
  final List<RevisionMeasurementData>? revisionMeasurementsData;
  final RevisionMeasurementData? selectedRevisionMeasurement;

  /// Compatibilidade com padrão antigo.
  final List<RevisionMeasurementData>? measurementsData;
  final RevisionMeasurementData? selectedMeasurement;

  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;

  /// Padrão novo.
  final double? balance;

  /// Compatibilidade com padrão antigo.
  final double? saldo;

  List<RevisionMeasurementData> get _data {
    return revisionMeasurementsData ?? measurementsData ?? <RevisionMeasurementData>[];
  }

  RevisionMeasurementData? get _selected {
    return selectedRevisionMeasurement ?? selectedMeasurement;
  }

  double get _balance {
    return balance ?? saldo ?? 0.0;
  }

  String _txt(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '-';
    }

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

  String _itemKey(RevisionMeasurementData item) {
    final id = (item.id ?? '').trim();

    if (id.isNotEmpty) return id;

    return <String>[
      _intText(item.order),
      _txt(item.numberprocess),
      _date(item.date),
      _money(item.value),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final revisions = _data;
    final selected = _selected;

    final totalRevisions = revisions.fold<double>(
      0.0,
          (previousTotal, item) {
        return previousTotal + (item.value ?? 0.0);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedTableChanged<RevisionMeasurementData>(
          listData: revisions,
          getKey: _itemKey,
          selectedKey: selected != null ? _itemKey(selected) : null,
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
            PagedColum<RevisionMeasurementData>(
              title: 'ORDEM',
              getter: (item) => _intText(item.order),
              textAlign: TextAlign.center,
              width: 100,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'Nº PROCESSO',
              getter: (item) => _txt(item.numberprocess),
              textAlign: TextAlign.center,
              width: 200,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'DATA DA REVISÃO',
              getter: (item) => _date(item.date),
              textAlign: TextAlign.center,
              width: 150,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'VALOR DA REVISÃO',
              getter: (item) => _money(item.value),
              textAlign: TextAlign.center,
              width: 200,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryBox(
          items: [
            _SummaryItem(
              label: 'TOTAL DAS REVISÕES',
              value: totalRevisions,
              backgroundColor: Colors.grey.shade200,
              fontWeight: FontWeight.w700,
            ),
            _SummaryItem(
              label: 'VALOR BASE DISPONÍVEL',
              value: valorTotal,
            ),
            _SummaryItem(
              label: 'SALDO',
              value: _balance,
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
  const _SummaryItem({
    required this.label,
    required this.value,
    this.backgroundColor,
    this.fontWeight,
  });

  final String label;
  final double value;
  final Color? backgroundColor;
  final FontWeight? fontWeight;
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.items,
  });

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: item.backgroundColor ?? Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: item.fontWeight,
                  ),
                ),
              ),
              Text(
                SipGedFormatMoney.doubleToText(item.value),
                style: TextStyle(
                  fontWeight: item.fontWeight,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}