import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/charts/gauges/gauge_chart_change.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';

class AdjustmentMeasurementGraphSection extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;

  /// Base total disponível.
  ///
  /// Neste caso: soma de todos os apostilamentos do contrato.
  final double valorTotal;

  /// Valor consumido.
  ///
  /// Neste caso: soma de todos os reajustes cadastrados/pagos.
  final double totalMedicoes;

  final void Function(int index)? onSelectIndex;

  const AdjustmentMeasurementGraphSection({
    super.key,
    required this.labels,
    required this.values,
    required this.valorTotal,
    required this.totalMedicoes,
    this.selectedIndex,
    this.onSelectIndex,
  });

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

  double _resolveGaugePercent() {
    if (!valorTotal.isFinite || valorTotal <= 0) return 0.0;
    if (!totalMedicoes.isFinite || totalMedicoes <= 0) return 0.0;

    return (totalMedicoes / valorTotal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = values.isNotEmpty && labels.isNotEmpty;

    final List<String> safeLabels = hasData ? labels : const <String>['—'];
    final List<double> safeValues = hasData ? values : const <double>[0.0];

    final List<double> safeAdjustmentValues = _valuesNormalized(
      safeValues,
      safeLabels.length,
    );

    final int? safeSelectedIndex = hasData ? selectedIndex : null;

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
            centerLabel: _resolveGaugePercent(),
            headerLabel: 'Consumo dos Apostilamentos',
            radius: 70,
            widthGraphic: 200,
            values: totalMedicoes.isFinite
                ? <double>[totalMedicoes]
                : const <double>[0.0],
          ),
          const SizedBox(width: 12),
          DonutChartChanged(
            labels: safeLabels,
            values: safeAdjustmentValues,
            selectedIndex: safeSelectedIndex,
            widthGraphic: 300,
            onTouch: (index) {
              if (index != null &&
                  index >= 0 &&
                  index < safeAdjustmentValues.length &&
                  hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
          const SizedBox(width: 12),
          LineChartChanged(
            labels: safeLabels,
            values: safeAdjustmentValues,
            selectedIndex: safeSelectedIndex,
            larguraGrafico: availableWidth,
            onPointTap: (index) {
              if (index >= 0 &&
                  index < safeAdjustmentValues.length &&
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