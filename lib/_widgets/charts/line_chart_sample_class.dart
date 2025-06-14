import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/measurement/measurement_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

class LineChartSample extends StatefulWidget {
  final int? selectedIndex;
  final void Function(int index)? onPointTap;
  final List<MeasurementData> measurements;
  final double? larguraGraficoLinha;

  const LineChartSample({
    super.key,
    required this.measurements,
    this.selectedIndex,
    this.onPointTap,
    this.larguraGraficoLinha,
  });

  @override
  State<LineChartSample> createState() => _LineChartSampleState();
}

class _LineChartSampleState extends State<LineChartSample> {
  @override
  Widget build(BuildContext context) {
    final spots = widget.measurements
        .where((e) => e.measurementorder != null && e.measurementinitialvalue != null)
        .map((e) => FlSpot(
      e.measurementorder!.toDouble(),
      e.measurementinitialvalue!,
    ))
        .toList();

    return SizedBox(
      width: widget.larguraGraficoLinha,
      child: Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RepaintBoundary(
            child: SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.grey.shade800,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            priceToString(spot.y),
                            const TextStyle(
                              color: Colors.white, // 👈 Altere a cor do texto aqui
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent && response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                        final index = response.lineBarSpots!.first.spotIndex;
                        widget.onPointTap?.call(index);
                      }
                    },
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
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isSelected = index == widget.selectedIndex;
                          return FlDotCirclePainter(
                            radius: isSelected ? 6 : 6,
                            color: isSelected ? Colors.red : Colors.blue,
                            strokeWidth: isSelected ? 2 : 0,
                            strokeColor: Colors.black,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

