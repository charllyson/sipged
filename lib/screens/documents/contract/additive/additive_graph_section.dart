import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';

class AdditiveGraphSection extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final void Function(int index)? onSelectIndex;

  const AdditiveGraphSection({
    super.key,
    required this.labels,
    required this.values,
    this.selectedIndex,
    this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    math.max(MediaQuery.of(context).size.width - 300 - 52, 800);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Pie Chart
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
          // Bar Chart
          BarChartChanged(
            heightGraphic: 260,
            labels: labels,
            values: values,
            selectedIndex: selectedIndex,
            onBarTap: (label) {
              final index = labels.indexOf(label);
              if (index != -1) {
                onSelectIndex?.call(index);
              }
            },
          ),
        ],
      ),
    );
  }
}
