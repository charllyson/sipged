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

  /// Valor total contratado/base.
  final double valorTotal;

  /// Valor consumido por medições.
  final double totalMedicoes;

  final double? totalPagamentos;

  final void Function(int index)? onSelectIndex;

  static const Color _measurementColor = Color(0xFFFB8323);
  static const Color _measurementTrackColor = Color(0xFFFFEDD5);
  static const Color _paymentColor = Color(0xFF206AF5);
  static const Color _paymentTrackColor = Color(0xFFEFF6FF);

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) {
      return 0.0;
    }

    return v;
  }

  double _safeTotal(double value) {
    if (!value.isFinite || value <= 0) {
      return 0.0;
    }

    return value;
  }

  double _safePercent({
    required double value,
    required double total,
  }) {
    if (!value.isFinite || !total.isFinite || total <= 0) {
      return 0.0;
    }

    return (value / total).clamp(0.0, 1.0).toDouble();
  }

  double _paymentTotalValue(ReportPaidData payment) {
    return _positive(payment.paymentValue) +
        _positive(payment.inssPaymentValue) +
        _positive(payment.irpfPaymentValue) +
        _positive(payment.issPaymentValue);
  }

  List<double> _valuesNormalized(
      List<double> source,
      int length, {
        bool onlyPositive = true,
      }) {
    return List<double>.generate(length, (index) {
      if (index >= source.length) {
        return 0.0;
      }

      final value = source[index];

      if (!value.isFinite) {
        return 0.0;
      }

      if (onlyPositive && value <= 0) {
        return 0.0;
      }

      return value;
    });
  }

  List<double> _buildPaymentValuesFromPayments(int length) {
    if (payments.isEmpty || length <= 0) {
      return List<double>.filled(length, 0.0);
    }

    final totalsByMeasurementId = <String, double>{};
    final totalsByMeasurementOrder = <int, double>{};

    for (final payment in payments) {
      final value = _paymentTotalValue(payment);

      if (value <= 0) {
        continue;
      }

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

        if (measurementId.isNotEmpty) {
          final valueById = totalsByMeasurementId[measurementId];

          if (valueById != null && valueById > 0) {
            return valueById;
          }
        }
      }

      if (index < measurementOrders.length) {
        final order = measurementOrders[index];

        if (order != null) {
          final valueByOrder = totalsByMeasurementOrder[order];

          if (valueByOrder != null && valueByOrder > 0) {
            return valueByOrder;
          }
        }
      }

      return 0.0;
    });
  }

  List<double> _resolvePaymentValues(int length) {
    if (length <= 0) {
      return const <double>[];
    }

    /// Preferencialmente, envie paymentValues já calculado pela Page/Cubit.
    /// Assim o gráfico apenas renderiza e não precisa reagrupar pagamentos.
    if (paymentValues.isNotEmpty) {
      return _valuesNormalized(paymentValues, length);
    }

    if (payments.isNotEmpty) {
      return _buildPaymentValuesFromPayments(length);
    }

    return List<double>.filled(length, 0.0);
  }

  bool _isValidIndex({
    required int? index,
    required int length,
    required bool hasData,
  }) {
    if (!hasData || index == null) {
      return false;
    }

    return index >= 0 && index < length;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = labels.isNotEmpty && values.isNotEmpty;

    final safeLabels = hasData ? labels : const <String>['—'];

    final safeMeasurementValues = hasData
        ? _valuesNormalized(values, safeLabels.length)
        : const <double>[0.0];

    final safePaymentValues = hasData
        ? _resolvePaymentValues(safeLabels.length)
        : const <double>[0.0];

    final safeSelectedIndex = _isValidIndex(
      index: selectedIndex,
      length: safeLabels.length,
      hasData: hasData,
    )
        ? selectedIndex
        : null;

    final totalContrato = _safeTotal(valorTotal);
    final totalMedido = _safeTotal(totalMedicoes);

    final totalPagoEfetivo = totalPagamentos != null
        ? _safeTotal(totalPagamentos!)
        : safePaymentValues.fold<double>(
      0.0,
          (total, value) => total + _positive(value),
    );

    final percentualMedido = _safePercent(
      value: totalMedido,
      total: totalContrato,
    );

    final percentualPago = _safePercent(
      value: totalPagoEfetivo,
      total: totalContrato,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;

        final availableWidth = math
            .max(
          screenWidth - 300 - 52,
          800,
        )
            .toDouble();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),

              RepaintBoundary(
                child: GaugeChartChange(
                  headerLabel: 'Execução Financeira',
                  footerLabel:
                  'Contratado: ${SipGedFormatMoney.doubleToText(totalContrato)}',
                  widthGraphic: 260,
                  radius: 78,
                  centerMode: GaugeTextMode.percent,
                  centerSeriesId: 'measurements',
                  showSeriesValuesInside: true,
                  seriesCenterTextScale: 1.22,
                  showLegend: true,
                  legendValueMode: GaugeLegendValueMode.value,
                  compactLegendValue: false,
                  series: [
                    GaugeChartSeries(
                      id: 'measurements',
                      label: 'Medido',
                      percent: percentualMedido,
                      value: totalMedido,
                      color: _measurementColor,
                      trackColor: _measurementTrackColor,
                    ),
                    GaugeChartSeries(
                      id: 'payments',
                      label: 'Pago',
                      percent: percentualPago,
                      value: totalPagoEfetivo,
                      color: _paymentColor,
                      trackColor: _paymentTrackColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              RepaintBoundary(
                child: DonutChartChanged(
                  labels: safeLabels,
                  values: safeMeasurementValues,
                  selectedIndex: safeSelectedIndex,
                  widthGraphic: 300,
                  onTouch: (index) {
                    if (_isValidIndex(
                      index: index,
                      length: safeMeasurementValues.length,
                      hasData: hasData,
                    )) {
                      onSelectIndex?.call(index!);
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),

              RepaintBoundary(
                child: LineChartChanged(
                  headerTitle: 'Medições x Pagamentos',
                  headerIcon: Icons.show_chart_rounded,
                  labels: safeLabels,
                  values: safeMeasurementValues,
                  selectedIndex: safeSelectedIndex,
                  larguraGrafico: availableWidth,
                  showLegend: true,
                  series: [
                    LineSeries(
                      id: 'measurements',
                      name:
                      'Medido: ${SipGedFormatMoney.doubleToText(totalMedido)}',
                      values: safeMeasurementValues,
                      labels: safeLabels,
                      color: _measurementColor,
                      showArea: true,
                    ),
                    LineSeries(
                      id: 'payments',
                      name:
                      'Pago: ${SipGedFormatMoney.doubleToText(totalPagoEfetivo)}',
                      values: safePaymentValues,
                      labels: safeLabels,
                      color: _paymentColor,
                      showArea: true,
                    ),
                  ],
                  onPointTap: (index) {
                    if (_isValidIndex(
                      index: index,
                      length: safeMeasurementValues.length,
                      hasData: hasData,
                    )) {
                      onSelectIndex?.call(index);
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }
}