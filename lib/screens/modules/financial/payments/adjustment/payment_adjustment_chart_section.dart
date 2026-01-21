import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:siged/_widgets/charts/gauges/gauge_circular_percent.dart';

class PaymentsAdjustmentChartsSection extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final double valorTotal;
  final double totalMedicoes;
  final void Function(int index)? onSelectIndex;

  const PaymentsAdjustmentChartsSection({
    super.key,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.labels,
    required this.values,
    required this.valorTotal,
    required this.totalMedicoes,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          GaugeCircularPercent(
            centerTitle: valorTotal == 0 ? 0 : totalMedicoes / valorTotal,
            headerTitle: 'Execução dos reajustamentos',
            radius: 70,
            larguraGrafico: 200,
            values: totalMedicoes.isNaN ? null : [totalMedicoes],
          ),
          const SizedBox(width: 12),
          PieChartChanged(
            labels: labels,
            values: values,
            selectedIndex: selectedIndex,
            larguraGrafico: 300,
            onTouch: (index) {
              if (index != null && index >= 0 && index < values.length) {
                onSelectIndex?.call(index);
              }
            },
          ),
          const SizedBox(width: 12),
          LineChartChanged(
            labels: labels,
            values: values,
            selectedIndex: selectedIndex,
            larguraGrafico:
            math.max(MediaQuery.of(context).size.width - 300 - 52, 800),
            alturaGrafico: 260,
            onPointTap: (index) {
              if (index >= 0 && index < values.length) {
                onSelectIndex?.call(index);
              }
            },
          ),
        ],
      ),
    );
  }
}
