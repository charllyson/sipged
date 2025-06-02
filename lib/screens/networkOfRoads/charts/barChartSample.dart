import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartSample extends StatelessWidget {
  const BarChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('S${value.toInt() + 1}'),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 8, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 10, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 14, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 15, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 8, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 10, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 14, color: Colors.indigo, width: 50)
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(
                borderRadius: BorderRadius.circular(2),
                toY: 15, color: Colors.indigo, width: 50)
          ]),
        ],
      ),
    );
  }
}
