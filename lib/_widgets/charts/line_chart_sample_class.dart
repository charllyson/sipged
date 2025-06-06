import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../_datas/measurement/measurement_data.dart';

class LineChartSample extends StatelessWidget {
  final List<MeasurementData> measurements;

  const LineChartSample({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    final spots = measurements
        .where((e) => e.measurementorder != null && e.measurementinitialvalue != null)
        .map((e) => FlSpot(
      e.measurementorder!.toDouble(),
      e.measurementinitialvalue!,
    ))
        .toList();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  priceToString(spot.y),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) {
                if (value % 1000000 != 0) return const SizedBox.shrink(); // Oculta valores fora do milhão
                final mi = value ~/ 1000000;
                return Text(
                  '$mi M',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: spots,
            barWidth: 3,
            color: Colors.blue,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

