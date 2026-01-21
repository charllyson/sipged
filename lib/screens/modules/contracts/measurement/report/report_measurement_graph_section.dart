// lib/screens/modules/contracts/measurement/report/report_measurement_graph_section.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:siged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:siged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';

class ReportMeasurementGraphSection extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final double valorTotal;
  final double totalMedicoes;
  final void Function(int index)? onSelectIndex;

  const ReportMeasurementGraphSection({
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

    // largura mínima do gráfico de linha, usando double
    final double availableWidth = math
        .max(
      MediaQuery.of(context).size.width - 300 - 52,
      800,
    )
        .toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          GaugeCircularPercent(
            centerTitle:
            valorTotal == 0 ? 0 : totalMedicoes / valorTotal,
            headerTitle: 'Execução dos Reajustes',
            radius: 70,
            larguraGrafico: 200,
            values: totalMedicoes.isNaN ? null : [totalMedicoes],
          ),
          const SizedBox(width: 12),
          PieChartChanged(
            labels: safeLabels,
            values: safeValues,
            selectedIndex: safeSelectedIndex,
            larguraCard: 300,
            larguraGrafico: 240,
            onTouch: (index) {
              if (index != null &&
                  index >= 0 &&
                  index < safeValues.length &&
                  hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
          const SizedBox(width: 12),
          LineChartChanged(
            labels: safeLabels,
            values: safeValues,
            selectedIndex: safeSelectedIndex,
            larguraGrafico: availableWidth,
            alturaGrafico: 260,
            onPointTap: (index) {
              if (index >= 0 &&
                  index < safeValues.length &&
                  hasData) {
                onSelectIndex?.call(index);
              }
            },
          ),
        ],
      ),
    );
  }
}
