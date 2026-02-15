import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_widgets/charts/pies/donut_chart_changed.dart';

class RevisionMeasurementGraphSection extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final double valorTotal;
  final double totalMedicoes;
  final void Function(int index)? onSelectIndex;

  const RevisionMeasurementGraphSection({
    super.key,
    required this.labels,
    required this.values,
    required this.valorTotal,
    required this.totalMedicoes,
    this.selectedIndex,
    this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = values.isNotEmpty && labels.isNotEmpty;

    // fallback para evitar index error no PieChartChanged e LineChartChanged
    final safeLabels = hasData ? labels : const ['—'];
    final safeValues = hasData ? values : const [0.0];
    final safeSelectedIndex = hasData ? selectedIndex : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          GaugeCircularPercent(
            centerTitle: valorTotal == 0 ? 0 : totalMedicoes / valorTotal,
            headerTitle: 'Execução dos Reajustes',
            radius: 70,
            larguraGrafico: 200,
            values: totalMedicoes.isNaN ? null : [totalMedicoes],
          ),
          const SizedBox(width: 12),
          DonutChartChanged(
            labels: safeLabels,
            values: safeValues,
            selectedIndex: safeSelectedIndex,
            larguraCard: 300,
            larguraGrafico: 240,
            onTouch: (index) {
              if (index != null && index >= 0 && index < safeValues.length && hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
          const SizedBox(width: 12),
          LineChartChanged(
            labels: safeLabels,
            values: safeValues,
            selectedIndex: safeSelectedIndex,
            larguraGrafico: math.max(MediaQuery.of(context).size.width - 300 - 52, 800),
            alturaGrafico: 260,
            onPointTap: (index) {
              if (index >= 0 && index < safeValues.length && hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
        ],
      ),
    );
  }

}
