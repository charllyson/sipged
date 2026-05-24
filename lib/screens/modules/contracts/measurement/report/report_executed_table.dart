import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_column.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_table.dart';
import 'package:sipged/_widgets/table/paged/paged_summary_item.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class ReportExecutedTable extends StatelessWidget {
  const ReportExecutedTable({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.measurementsData,
    required this.selectedMeasurement,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotal,
    required this.saldo,
    this.payments = const <ReportPaidData>[],
    this.contractData,
  });

  final void Function(ReportExecutedData) onTapItem;
  final void Function(String measurementId) onDelete;

  final List<ReportExecutedData> measurementsData;
  final List<ReportPaidData> payments;

  final ReportExecutedData? selectedMeasurement;
  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  String _txt(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty || text.toLowerCase() == 'null') return '-';

    return text;
  }

  String _date(DateTime? value) {
    if (value == null) return '-';

    return SipGedFormatDates.dateToDdMMyyyy(value);
  }

  double _roundMoney(double value) {
    if (!value.isFinite) return 0.0;

    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded == 0.0) return 0.0;

    return rounded;
  }

  String _money(double? value) {
    if (value == null) return '-';

    return SipGedFormatMoney.doubleToText(_roundMoney(value));
  }

  String _intText(int? value) {
    if (value == null) return '-';

    return value.toString();
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return _roundMoney(v);
  }

  double _retentionsValue(ReportPaidData payment) {
    return _roundMoney(
      _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );
  }

  double _paymentTotalValue(ReportPaidData payment) {
    return _roundMoney(
      _positive(payment.paymentValue) + _retentionsValue(payment),
    );
  }

  String _itemKey(ReportExecutedData item) {
    final id = (item.id ?? '').trim();

    if (id.isNotEmpty) return id;

    return [
      _intText(item.order),
      _txt(item.numberprocess),
      _date(item.date),
      _money(item.value),
    ].join('|');
  }

  List<ReportPaidData> _paymentsForMeasurement(
      ReportExecutedData measurement,
      ) {
    final measurementId = measurement.id?.trim() ?? '';
    final measurementOrder = measurement.order;

    final list = payments.where((payment) {
      final paymentContractId = payment.contractId?.trim() ?? '';
      final measurementContractId = measurement.contractId?.trim() ?? '';

      if (measurementContractId.isNotEmpty &&
          paymentContractId.isNotEmpty &&
          paymentContractId != measurementContractId) {
        return false;
      }

      final paymentMeasurementId = payment.measurementId?.trim() ?? '';

      if (measurementId.isNotEmpty && paymentMeasurementId == measurementId) {
        return true;
      }

      if (paymentMeasurementId.isEmpty &&
          measurementOrder != null &&
          payment.measurementOrder == measurementOrder) {
        return true;
      }

      if (measurementId.isEmpty &&
          measurementOrder != null &&
          payment.measurementOrder == measurementOrder) {
        return true;
      }

      return false;
    }).toList();

    list.sort((a, b) {
      final dateA = a.paymentDate ?? DateTime(1900);
      final dateB = b.paymentDate ?? DateTime(1900);

      final dateCompare = dateA.compareTo(dateB);

      if (dateCompare != 0) return dateCompare;

      final sourceA = a.fundingSourceLabel ?? '';
      final sourceB = b.fundingSourceLabel ?? '';

      return sourceA.toLowerCase().compareTo(sourceB.toLowerCase());
    });

    return list;
  }

  double _totalPaymentsForMeasurement(ReportExecutedData measurement) {
    return _paymentsForMeasurement(measurement).fold<double>(
      0.0,
          (total, payment) {
        return _roundMoney(total + _paymentTotalValue(payment));
      },
    );
  }

  double _totalRetentionsForMeasurement(ReportExecutedData measurement) {
    return _paymentsForMeasurement(measurement).fold<double>(
      0.0,
          (total, payment) {
        return _roundMoney(total + _retentionsValue(payment));
      },
    );
  }

  double _measurementSaldo(ReportExecutedData measurement) {
    final measured = _roundMoney(measurement.value ?? 0.0);
    final paid = _totalPaymentsForMeasurement(measurement);

    return _roundMoney(measured - paid);
  }

  List<PagedSubColumn<ReportPaidData>> _paymentColumns() {
    return [
      PagedSubColumn<ReportPaidData>(
        title: 'FONTE',
        width: 260,
        textAlign: TextAlign.left,
        fontWeight: FontWeight.w700,
        valueBuilder: (payment) => _txt(payment.fundingSourceLabel),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'DATA PAG.',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.paymentDate),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'VALOR PAGO',
        width: 150,
        textAlign: TextAlign.right,
        fontWeight: FontWeight.w900,
        valueBuilder: (payment) => _money(payment.paymentValue),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'DATA INSS',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.inssPaymentDate),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'INSS',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.inssPaymentValue),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'DATA IRPF',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.irpfPaymentDate),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'IRPF',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.irpfPaymentValue),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'DATA ISS',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.issPaymentDate),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'ISS',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.issPaymentValue),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'TOTAL',
        width: 150,
        textAlign: TextAlign.right,
        fontWeight: FontWeight.w900,
        valueBuilder: (payment) => _money(_paymentTotalValue(payment)),
      ),
      PagedSubColumn<ReportPaidData>(
        title: 'OBS.',
        width: 320,
        textAlign: TextAlign.left,
        valueBuilder: (payment) => _txt(payment.note),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalReports = measurementsData.fold<double>(
      0.0,
          (previousTotal, item) {
        return _roundMoney(previousTotal + _positive(item.value));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedTableChanged<ReportExecutedData>(
          listData: measurementsData,
          getKey: _itemKey,
          selectedKey:
          selectedMeasurement != null ? _itemKey(selectedMeasurement!) : null,
          keepSelectionInternally: false,
          enableRowTapSelection: true,
          enablePagination: false,
          initialRowsPerPage: 10,
          rowsPerPageOptions: const <int>[10, 25, 50, 100],
          sortColumnIndex: 0,
          sortAscending: true,
          minTableWidth: 1800,
          defaultColumnWidth: 150,
          actionsColumnWidth: 56,
          colorHeadTable: const Color(0xFF091D68),
          colorHeadTableText: Colors.white,
          headingRowHeight: 40,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 56,
          enableExpandableRows: true,
          expandColumnWidth: 56,
          canExpandRow: (measurement) {
            return _paymentsForMeasurement(measurement).isNotEmpty;
          },
          expandableRowBuilder: (context, measurement) {
            return PagedSubTable<ReportPaidData>(
              items: _paymentsForMeasurement(measurement),
              columns: _paymentColumns(),
              leadingIcon: Icons.payments_outlined,
              leadingWidth: 44,
              primaryColor: const Color(0xFF091D68),
              backgroundColor: const Color(0xFFF7F9FF),
              headerColor: const Color(0x0F091D68),
              borderColor: const Color(0x1F091D68),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
              cellHorizontalPadding: 10,
              bottomRadius: 8,
            );
          },
          onTapItem: onTapItem,
          onDelete: (item) {
            final id = (item.id ?? '').trim();

            if (id.isNotEmpty) {
              onDelete(id);
            }
          },
          columns: [
            PagedColum<ReportExecutedData>(
              title: 'ORDEM',
              getter: (item) => _intText(item.order),
              textAlign: TextAlign.center,
              width: 80,
            ),
            PagedColum<ReportExecutedData>(
              title: 'Nº PROCESSO',
              getter: (item) => _txt(item.numberprocess),
              textAlign: TextAlign.center,
              width: 240,
            ),
            PagedColum<ReportExecutedData>(
              title: 'DATA DA MEDIÇÃO',
              getter: (item) => _date(item.date),
              textAlign: TextAlign.center,
              width: 190,
            ),
            PagedColum<ReportExecutedData>(
              title: 'VALOR DA MEDIÇÃO',
              getter: (item) => _money(item.value),
              textAlign: TextAlign.center,
              width: 210,
            ),
            PagedColum<ReportExecutedData>(
              title: 'RETENÇÕES',
              getter: (item) => _money(_totalRetentionsForMeasurement(item)),
              textAlign: TextAlign.center,
              width: 180,
            ),
            PagedColum<ReportExecutedData>(
              title: 'TOTAL PAGO',
              getter: (item) => _money(_totalPaymentsForMeasurement(item)),
              textAlign: TextAlign.center,
              width: 190,
            ),
            PagedColum<ReportExecutedData>(
              title: 'SALDO',
              getter: (item) => _money(_measurementSaldo(item)),
              textAlign: TextAlign.center,
              width: 190,
            ),
          ],
        ),
        const SizedBox(height: 12),
        PagedSummaryBox(
          items: [
            PagedSummaryItem(
              label: 'TOTAL DOS BOLETINS',
              value: _money(totalReports),
              backgroundColor: Colors.grey.shade200,
              fontWeight: FontWeight.w700,
            ),
            PagedSummaryItem(
              label: 'VALOR CONTRATADO',
              value: _money(valorInicial),
            ),
            PagedSummaryItem(
              label: 'VALOR DOS ADITIVOS',
              value: _money(valorAditivos),
            ),
            PagedSummaryItem(
              label: 'VALOR CONTRATADO + ADITIVOS',
              value: _money(valorTotal),
            ),
            PagedSummaryItem(
              label: 'SALDO DO CONTRATO',
              value: _money(saldo),
              backgroundColor: Colors.blue.shade100,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ],
    );
  }
}