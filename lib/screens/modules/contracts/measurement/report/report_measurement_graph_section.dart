// lib/screens/modules/contracts/measurement/report/report_measurement_graph_section.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_widgets/charts/pies/donut_chart_changed.dart';

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

    // fallback seguro
    final safeLabels = hasData ? labels : const ['—'];
    final safeValues = hasData ? values : const [0.0];
    final safeSelectedIndex = hasData ? selectedIndex : null;

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

          // 🔷 Gauge
          GaugeCircularPercent(
            centerTitle:
            valorTotal == 0 ? 0 : totalMedicoes / valorTotal,
            headerTitle: 'Execução dos Reajustes',
            radius: 70,
            larguraGrafico: 200,
            values: totalMedicoes.isNaN ? null : [totalMedicoes],
          ),

          const SizedBox(width: 12),

          // 🔷 Pizza
          DonutChartChanged(
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

          // 🔷 Linha (agora com SectionTitle embutido)
          LineChartChanged(
            headerTitle: 'Evolução das Medições',
            headerSubtitle: 'Distribuição por período',
            headerIcon: Icons.show_chart_rounded,

            labels: safeLabels,
            values: safeValues,
            selectedIndex: safeSelectedIndex,
            larguraGrafico: availableWidth,
            alturaGrafico: 294,
            onPointTap: (index) {
              if (index >= 0 &&
                  index < safeValues.length &&
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
