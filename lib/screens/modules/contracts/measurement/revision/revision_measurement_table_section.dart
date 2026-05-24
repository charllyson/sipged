// lib/screens/modules/contracts/measurement/revision/revision_measurement_table_section.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_column.dart';
import 'package:sipged/_widgets/table/paged/paged_sub_table.dart';
import 'package:sipged/_widgets/table/paged/paged_summary_item.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class RevisionMeasurementTableSection extends StatelessWidget {
  const RevisionMeasurementTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.revisionMeasurementsData,
    required this.selectedRevisionMeasurement,
    required this.valorTotal,
    required this.balance,
    this.payments = const <RevisionPaidData>[],
    this.valorInicial = 0.0,
    this.valorAditivos = 0.0,
    this.contractData,
  });

  final void Function(RevisionMeasurementData) onTapItem;
  final void Function(String revisionId) onDelete;

  final List<RevisionMeasurementData> revisionMeasurementsData;
  final List<RevisionPaidData> payments;

  final RevisionMeasurementData? selectedRevisionMeasurement;
  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
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

  double _retentionsValue(RevisionPaidData payment) {
    return _roundMoney(
      _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );
  }

  double _paymentTotalValue(RevisionPaidData payment) {
    return _roundMoney(
      _positive(payment.paymentValue) + _retentionsValue(payment),
    );
  }

  String _itemKey(RevisionMeasurementData item) {
    final id = (item.id ?? '').trim();

    if (id.isNotEmpty) return id;

    return [
      _intText(item.order),
      _txt(item.numberprocess),
      _date(item.date),
      _money(item.value),
    ].join('|');
  }

  List<RevisionPaidData> _paymentsForRevision(
      RevisionMeasurementData revision,
      ) {
    final revisionId = revision.id?.trim() ?? '';
    final revisionOrder = revision.order;

    final list = payments.where((payment) {
      final paymentContractId = payment.contractId?.trim() ?? '';
      final revisionContractId = revision.contractId?.trim() ?? '';

      if (revisionContractId.isNotEmpty &&
          paymentContractId.isNotEmpty &&
          paymentContractId != revisionContractId) {
        return false;
      }

      final paymentRevisionId = payment.revisionId?.trim() ?? '';

      if (revisionId.isNotEmpty && paymentRevisionId == revisionId) {
        return true;
      }

      if (paymentRevisionId.isEmpty &&
          revisionOrder != null &&
          payment.revisionOrder == revisionOrder) {
        return true;
      }

      if (revisionId.isEmpty &&
          revisionOrder != null &&
          payment.revisionOrder == revisionOrder) {
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

  double _totalPaymentsForRevision(RevisionMeasurementData revision) {
    return _paymentsForRevision(revision).fold<double>(
      0.0,
          (total, payment) {
        return _roundMoney(total + _paymentTotalValue(payment));
      },
    );
  }

  double _totalRetentionsForRevision(RevisionMeasurementData revision) {
    return _paymentsForRevision(revision).fold<double>(
      0.0,
          (total, payment) {
        return _roundMoney(total + _retentionsValue(payment));
      },
    );
  }

  double _revisionSaldo(RevisionMeasurementData revision) {
    final revised = _roundMoney(revision.value ?? 0.0);
    final paid = _totalPaymentsForRevision(revision);

    return _roundMoney(revised - paid);
  }

  List<PagedSubColumn<RevisionPaidData>> _paymentColumns() {
    return [
      PagedSubColumn<RevisionPaidData>(
        title: 'FONTE',
        width: 260,
        textAlign: TextAlign.left,
        fontWeight: FontWeight.w700,
        valueBuilder: (payment) => _txt(payment.fundingSourceLabel),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'DATA PAG.',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.paymentDate),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'VALOR PAGO',
        width: 150,
        textAlign: TextAlign.right,
        fontWeight: FontWeight.w900,
        valueBuilder: (payment) => _money(payment.paymentValue),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'DATA INSS',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.inssPaymentDate),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'INSS',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.inssPaymentValue),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'DATA IRPF',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.irpfPaymentDate),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'IRPF',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.irpfPaymentValue),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'DATA ISS',
        width: 120,
        textAlign: TextAlign.center,
        valueBuilder: (payment) => _date(payment.issPaymentDate),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'ISS',
        width: 130,
        textAlign: TextAlign.right,
        valueBuilder: (payment) => _money(payment.issPaymentValue),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'TOTAL',
        width: 150,
        textAlign: TextAlign.right,
        fontWeight: FontWeight.w900,
        valueBuilder: (payment) => _money(_paymentTotalValue(payment)),
      ),
      PagedSubColumn<RevisionPaidData>(
        title: 'OBS.',
        width: 320,
        textAlign: TextAlign.left,
        valueBuilder: (payment) => _txt(payment.note),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalRevisions = revisionMeasurementsData.fold<double>(
      0.0,
          (previousTotal, item) {
        return _roundMoney(previousTotal + _positive(item.value));
      },
    );

    final totalPayments = revisionMeasurementsData.fold<double>(
      0.0,
          (previousTotal, item) {
        return _roundMoney(previousTotal + _totalPaymentsForRevision(item));
      },
    );

    final totalRetentions = revisionMeasurementsData.fold<double>(
      0.0,
          (previousTotal, item) {
        return _roundMoney(previousTotal + _totalRetentionsForRevision(item));
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PagedTableChanged<RevisionMeasurementData>(
          listData: revisionMeasurementsData,
          getKey: _itemKey,
          selectedKey: selectedRevisionMeasurement != null
              ? _itemKey(selectedRevisionMeasurement!)
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
          canExpandRow: (revision) {
            return _paymentsForRevision(revision).isNotEmpty;
          },
          expandableRowBuilder: (context, revision) {
            return PagedSubTable<RevisionPaidData>(
              items: _paymentsForRevision(revision),
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
            PagedColum<RevisionMeasurementData>(
              title: 'ORDEM',
              getter: (item) => _intText(item.order),
              textAlign: TextAlign.center,
              width: 80,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'Nº PROCESSO',
              getter: (item) => _txt(item.numberprocess),
              textAlign: TextAlign.center,
              width: 240,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'DATA DA REVISÃO',
              getter: (item) => _date(item.date),
              textAlign: TextAlign.center,
              width: 190,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'VALOR DA REVISÃO',
              getter: (item) => _money(item.value),
              textAlign: TextAlign.center,
              width: 210,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'RETENÇÕES',
              getter: (item) => _money(_totalRetentionsForRevision(item)),
              textAlign: TextAlign.center,
              width: 180,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'TOTAL PAGO',
              getter: (item) => _money(_totalPaymentsForRevision(item)),
              textAlign: TextAlign.center,
              width: 190,
            ),
            PagedColum<RevisionMeasurementData>(
              title: 'SALDO',
              getter: (item) => _money(_revisionSaldo(item)),
              textAlign: TextAlign.center,
              width: 190,
            ),
          ],
        ),
        const SizedBox(height: 12),
        PagedSummaryBox(
          items: [
            PagedSummaryItem(
              label: 'TOTAL DAS REVISÕES',
              value: _money(totalRevisions),
              backgroundColor: Colors.grey.shade200,
              fontWeight: FontWeight.w700,
            ),
            PagedSummaryItem(
              label: 'TOTAL PAGO',
              value: _money(totalPayments),
            ),
            PagedSummaryItem(
              label: 'TOTAL DE RETENÇÕES',
              value: _money(totalRetentions),
            ),
            PagedSummaryItem(
              label: 'VALOR BASE DISPONÍVEL',
              value: _money(valorTotal),
            ),
            PagedSummaryItem(
              label: 'SALDO',
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