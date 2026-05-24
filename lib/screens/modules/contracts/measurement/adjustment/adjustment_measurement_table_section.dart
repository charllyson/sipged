// lib/screens/modules/contracts/measurement/adjustment/adjustment_measurement_table_section.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_column.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_table.dart';
import 'package:sipged/_widgets/table/paged/paged_summary_item.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class AdjustmentMeasurementTableSection extends StatelessWidget {
  const AdjustmentMeasurementTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.adjustmentMeasurementsData,
    required this.selectedAdjustmentMeasurement,
    required this.valueApostilles,
    required this.valueRevisions,
    required this.valorTotal,
    required this.balance,
    this.payments = const <AdjustmentPaidData>[],
    this.contractData,
  });

  final void Function(AdjustmentMeasurementData) onTapItem;
  final void Function(String adjustmentId) onDelete;

  final List<AdjustmentMeasurementData> adjustmentMeasurementsData;
  final List<AdjustmentPaidData> payments;

  final AdjustmentMeasurementData? selectedAdjustmentMeasurement;
  final ContractData? contractData;

  final double valueApostilles;
  final double valueRevisions;
  final double valorTotal;
  final double balance;

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

  double _retentionsValue(AdjustmentPaidData payment) {
    return _roundMoney(
      _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );
  }

  double _paymentTotalValue(AdjustmentPaidData payment) {
    return _roundMoney(
      _positive(payment.paymentValue) + _retentionsValue(payment),
    );
  }

  String _itemKey(AdjustmentMeasurementData item) {
    final id = (item.id ?? '').trim();

    if (id.isNotEmpty) return id;

    return [
      _intText(item.order),
      _txt(item.numberprocess),
      _date(item.date),
      _money(item.value),
    ].join('|');
  }

  List<AdjustmentPaidData> _paymentsForAdjustment(
      AdjustmentMeasurementData adjustment,
      ) {
    final adjustmentId = adjustment.id?.trim() ?? '';
    final adjustmentOrder = adjustment.order;

    final list = payments.where((payment) {
      final paymentContractId = payment.contractId?.trim() ?? '';
      final adjustmentContractId = adjustment.contractId?.trim() ?? '';

      if (adjustmentContractId.isNotEmpty &&
          paymentContractId.isNotEmpty &&
          paymentContractId != adjustmentContractId) {
        return false;
      }

      final paymentAdjustmentId = payment.adjustmentId?.trim() ?? '';

      if (adjustmentId.isNotEmpty && paymentAdjustmentId == adjustmentId) {
        return true;
      }

      if (paymentAdjustmentId.isEmpty &&
          adjustmentOrder != null &&
          payment.adjustmentOrder == adjustmentOrder) {
        return true;
      }

      if (adjustmentId.isEmpty &&
          adjustmentOrder != null &&
          payment.adjustmentOrder == adjustmentOrder) {
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

  double _totalPaymentsForAdjustment(AdjustmentMeasurementData adjustment) {
    return _paymentsForAdjustment(adjustment).fold<double>(
      0.0,
          (total, payment) {
        return _roundMoney(total + _paymentTotalValue(payment));
      },
    );
  }

  double _totalRetentionsForAdjustment(AdjustmentMeasurementData adjustment) {
    return _paymentsForAdjustment(adjustment).fold<double>(
      0.0,
          (total, payment) {
        return _roundMoney(total + _retentionsValue(payment));
      },
    );
  }

  double _adjustmentSaldo(AdjustmentMeasurementData adjustment) {
    final adjusted = _roundMoney(adjustment.value ?? 0.0);
    final paid = _totalPaymentsForAdjustment(adjustment);

    return _roundMoney(adjusted - paid);
  }

  List<PagedSubColumn<AdjustmentPaidData>> _paymentColumns() {
    return [
      PagedSubColumn<AdjustmentPaidData>(
        title: 'FONTE',
        width: 260,
        textAlign: TextAlign.left,
        fontWeight: FontWeight.w700,
        valueBuilder: (payment) => _txt(payment.fundingSourceLabel),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'DATA PAG.',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.paymentDate),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'VALOR PAGO',
        width: 150,
        textAlign: TextAlign.right,
        fontWeight: FontWeight.w900,
        valueBuilder: (payment) => _money(payment.paymentValue),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'DATA INSS',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.inssPaymentDate),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'INSS',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.inssPaymentValue),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'DATA IRPF',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.irpfPaymentDate),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'IRPF',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.irpfPaymentValue),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'DATA ISS',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.issPaymentDate),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'ISS',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.issPaymentValue),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'TOTAL',
        width: 150,
        textAlign: TextAlign.right,
        fontWeight: FontWeight.w900,
        valueBuilder: (payment) => _money(_paymentTotalValue(payment)),
      ),
      PagedSubColumn<AdjustmentPaidData>(
        title: 'OBS.',
        width: 320,
        textAlign: TextAlign.left,
        valueBuilder: (payment) => _txt(payment.note),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalAdjustments = adjustmentMeasurementsData.fold<double>(
      0.0,
          (previousTotal, item) {
        return _roundMoney(previousTotal + _positive(item.value));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedTableChanged<AdjustmentMeasurementData>(
          listData: adjustmentMeasurementsData,
          getKey: _itemKey,
          selectedKey: selectedAdjustmentMeasurement != null
              ? _itemKey(selectedAdjustmentMeasurement!)
              : null,
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
          canExpandRow: (adjustment) {
            return _paymentsForAdjustment(adjustment).isNotEmpty;
          },
          expandableRowBuilder: (context, adjustment) {
            return PagedSubTable<AdjustmentPaidData>(
              items: _paymentsForAdjustment(adjustment),
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
            PagedColum<AdjustmentMeasurementData>(
              title: 'ORDEM',
              getter: (item) => _intText(item.order),
              textAlign: TextAlign.center,
              width: 80,
            ),
            PagedColum<AdjustmentMeasurementData>(
              title: 'Nº PROCESSO',
              getter: (item) => _txt(item.numberprocess),
              textAlign: TextAlign.center,
              width: 240,
            ),
            PagedColum<AdjustmentMeasurementData>(
              title: 'DATA DO REAJUSTE',
              getter: (item) => _date(item.date),
              textAlign: TextAlign.center,
              width: 190,
            ),
            PagedColum<AdjustmentMeasurementData>(
              title: 'VALOR DO REAJUSTE',
              getter: (item) => _money(item.value),
              textAlign: TextAlign.center,
              width: 210,
            ),
            PagedColum<AdjustmentMeasurementData>(
              title: 'RETENÇÕES',
              getter: (item) => _money(_totalRetentionsForAdjustment(item)),
              textAlign: TextAlign.center,
              width: 180,
            ),
            PagedColum<AdjustmentMeasurementData>(
              title: 'TOTAL PAGO',
              getter: (item) => _money(_totalPaymentsForAdjustment(item)),
              textAlign: TextAlign.center,
              width: 190,
            ),
            PagedColum<AdjustmentMeasurementData>(
              title: 'SALDO',
              getter: (item) => _money(_adjustmentSaldo(item)),
              textAlign: TextAlign.center,
              width: 190,
            ),
          ],
        ),
        const SizedBox(height: 12),
        PagedSummaryBox(
          items: [
            PagedSummaryItem(
              label: 'TOTAL DOS REAJUSTES',
              value: _money(totalAdjustments),
              backgroundColor: Colors.grey.shade200,
              fontWeight: FontWeight.w700,
            ),
            PagedSummaryItem(
              label: 'VALOR DOS APOSTILAMENTOS',
              value: _money(valueApostilles),
            ),
            PagedSummaryItem(
              label: 'VALOR DAS REVISÕES DE APOSTILAMENTO',
              value: _money(valueRevisions),
            ),
            PagedSummaryItem(
              label: 'VALOR DISPONÍVEL PARA REAJUSTES',
              value: _money(valorTotal),
            ),
            PagedSummaryItem(
              label: 'SALDO DO APOSTILAMENTO',
              value: _money(balance),
              backgroundColor: Colors.blue.shade100,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ],
    );
  }
}