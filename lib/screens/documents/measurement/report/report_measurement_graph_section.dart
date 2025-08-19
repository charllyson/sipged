import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../../_widgets/charts/gauge_circular_percent.dart';
import '../../../../../_widgets/charts/line_chart_changed.dart';
import '../../../../_widgets/charts/pieGraph/pie_chart_changed.dart';

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          GaugeCircularPercent(
            percent: valorTotal == 0 ? 0 : totalMedicoes / valorTotal,
            label: 'Execução dos Reajustes',
            radius: 70,
            larguraGrafico: 200,
            values: totalMedicoes.isNaN ? null : [totalMedicoes],
          ),
          const SizedBox(width: 12),
          PieChartChanged(
            labels: safeLabels,
            values: safeValues,
            selectedIndex: safeSelectedIndex,
            larguraGrafico: 300,
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
