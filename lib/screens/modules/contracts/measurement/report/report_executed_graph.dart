// lib/screens/modules/contracts/measurement/report/report_executed_graph.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_change.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';

class ReportExecutedGraph extends StatelessWidget {
  const ReportExecutedGraph({
    super.key,
    required this.labels,
    required this.values,
    required this.valorTotal,
    required this.totalMedicoes,
    this.measurementIds = const <String>[],
    this.measurementOrders = const <int?>[],
    this.payments = const <ReportPaidData>[],
    this.paymentValues = const <double>[],
    this.totalPagamentos,
    this.selectedIndex,
    this.onSelectIndex,
  });

  final List<String> labels;
  final List<double> values;

  final List<String> measurementIds;
  final List<int?> measurementOrders;

  final List<ReportPaidData> payments;
  final List<double> paymentValues;

  final int? selectedIndex;
  final double valorTotal;
  final double totalMedicoes;

  final double? totalPagamentos;

  final void Function(int index)? onSelectIndex;

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return v;
  }

  double _paymentTotalValue(ReportPaidData payment) {
    return _positive(payment.paymentValue) +
        _positive(payment.inssPaymentValue) +
        _positive(payment.irpfPaymentValue) +
        _positive(payment.issPaymentValue);
  }

  List<double> _valuesNormalized(List<double> source, int length) {
    return List<double>.generate(length, (index) {
      if (index < source.length) {
        final value = source[index];

        if (value.isFinite) return value;

        return 0.0;
      }

      return 0.0;
    });
  }

  List<double> _buildPaymentValuesFromPayments(int length) {
    final totalsByMeasurementId = <String, double>{};
    final totalsByMeasurementOrder = <int, double>{};

    for (final payment in payments) {
      final value = _paymentTotalValue(payment);

      if (!value.isFinite || value <= 0) continue;

      final measurementId = payment.measurementId?.trim() ?? '';

      if (measurementId.isNotEmpty) {
        totalsByMeasurementId[measurementId] =
            (totalsByMeasurementId[measurementId] ?? 0.0) + value;
      }

      final order = payment.measurementOrder;

      if (order != null) {
        totalsByMeasurementOrder[order] =
            (totalsByMeasurementOrder[order] ?? 0.0) + value;
      }
    }

    return List<double>.generate(length, (index) {
      if (index < measurementIds.length) {
        final measurementId = measurementIds[index].trim();

        if (measurementId.isNotEmpty &&
            totalsByMeasurementId.containsKey(measurementId)) {
          return totalsByMeasurementId[measurementId] ?? 0.0;
        }
      }

      if (index < measurementOrders.length) {
        final order = measurementOrders[index];

        if (order != null && totalsByMeasurementOrder.containsKey(order)) {
          return totalsByMeasurementOrder[order] ?? 0.0;
        }
      }

      return 0.0;
    });
  }

  List<double> _resolvePaymentValues(int length) {
    if (paymentValues.isNotEmpty) {
      return _valuesNormalized(paymentValues, length);
    }

    if (payments.isNotEmpty) {
      return _buildPaymentValuesFromPayments(length);
    }

    return List<double>.filled(length, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = values.isNotEmpty && labels.isNotEmpty;

    final safeLabels = hasData ? labels : const <String>['—'];
    final safeValues = hasData ? values : const <double>[0.0];

    final safeMeasurementValues = _valuesNormalized(
      safeValues,
      safeLabels.length,
    );

    final safePaymentValues = hasData
        ? _resolvePaymentValues(safeLabels.length)
        : const <double>[0.0];

    final safeSelectedIndex = hasData ? selectedIndex : null;

    final totalPagoEfetivo = totalPagamentos ??
        safePaymentValues.fold<double>(
          0.0,
              (total, value) => total + value,
        );

    final double availableWidth = math
        .max(
      MediaQuery.of(context).size.width - 300 - 52,
      800,
    )
        .toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          GaugeChartChange(
            centerLabel: valorTotal == 0 ? 0 : totalMedicoes / valorTotal,
            headerLabel: 'Execução das Medições',
            radius: 70,
            widthGraphic: 200,
            values: totalMedicoes.isNaN ? null : <double>[totalMedicoes],
          ),
          const SizedBox(width: 12),
          DonutChartChanged(
            labels: safeLabels,
            values: safeMeasurementValues,
            selectedIndex: safeSelectedIndex,
            widthGraphic: 300,
            onTouch: (index) {
              if (index != null &&
                  index >= 0 &&
                  index < safeMeasurementValues.length &&
                  hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
          const SizedBox(width: 12),
          LineChartChanged(
            headerTitle: 'Medições x Pagamentos',
            headerSubtitle:
            'Medido: ${SipGedFormatMoney.doubleToText(totalMedicoes)} | Pago: ${SipGedFormatMoney.doubleToText(totalPagoEfetivo)}',
            headerIcon: Icons.show_chart_rounded,
            labels: safeLabels,
            values: safeMeasurementValues,
            selectedIndex: safeSelectedIndex,
            larguraGrafico: availableWidth,
            alturaGrafico: 294,
            showLegend: true,
            series: [
              LineSeries(
                id: 'measurements',
                name: 'Medições',
                values: safeMeasurementValues,
                labels: safeLabels,
                color: const Color(0xFFFB8323),
                showArea: true,
              ),
              LineSeries(
                id: 'payments',
                name: 'Pagamentos',
                values: safePaymentValues,
                labels: safeLabels,
                color: const Color(0xFF206AF5),
                showArea: true,
              ),
            ],
            onPointTap: (index) {
              if (index >= 0 &&
                  index < safeMeasurementValues.length &&
                  hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}