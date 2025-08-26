import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/charts/lines/shimmer_line_chart.dart';
import 'package:sisged/_utils/formats/format_field.dart';


class LineChartChanged extends StatefulWidget {
  final int? selectedIndex;
  final void Function(int index)? onPointTap;
  final List<String> labels;
  final List<double> values;
  final double? larguraGrafico;
  final double? alturaGrafico;
  final String Function(double value)? tooltipFormatter;
  final String? prefix;


  const LineChartChanged({
    super.key,
    required this.labels,
    required this.values,
    this.selectedIndex,
    this.onPointTap,
    this.larguraGrafico,
    this.alturaGrafico = 240,
    this.tooltipFormatter,
    this.prefix,
  });

  @override
  State<LineChartChanged> createState() => _LineChartChangedState();
}

class _LineChartChangedState extends State<LineChartChanged> {
  Widget _noData() {
    final count = widget.labels.isNotEmpty ? widget.labels.length : 12;
    return LineChartShimmerWidget(
      pointsCount: count,
      height: widget.alturaGrafico ?? 240,
      chartTitle: widget.labels.isNotEmpty ? widget.labels[0] : null,
    );
  }

  bool get _semDados {
    if (widget.labels.length != widget.values.length) return true;
    if (widget.values.isEmpty) return true;
    if (widget.values.every((v) => v == null)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_semDados) return _noData();

    final spots = List.generate(widget.values.length, (i) {
      return FlSpot(i.toDouble(), widget.values[i]);
    });

    final larguraMinima = MediaQuery.of(context).size.width;
    final larguraDinamica = max(widget.values.length * 50.0, larguraMinima);

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 18.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: widget.alturaGrafico,
            width: larguraDinamica,
            child: Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.grey.shade800,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            widget.tooltipFormatter?.call(spot.y) ?? priceToString(spot.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent &&
                          response?.lineBarSpots != null &&
                          response!.lineBarSpots!.isNotEmpty) {
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
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= widget.labels.length) return const SizedBox.shrink();
                          return Text('${widget.prefix??''}${widget.labels[index]}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (value, meta) {
                          if (value % 1000000 != 0) return const SizedBox.shrink();
                          final mi = value ~/ 1000000;
                          return Text(
                            '$mi M',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.left,
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: spots,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      gradient: const LinearGradient(
                        colors: [Color.fromARGB(254, 251, 131, 35), Color.fromARGB(254, 251, 131, 35)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(254, 251, 131, 35).withOpacity(0.5),
                            const Color.fromARGB(254, 251, 131, 35).withOpacity(0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isSelected = index == widget.selectedIndex;
                          return FlDotCirclePainter(
                            radius: isSelected ? 7 : 4,
                            color: isSelected ? Colors.blue : Colors.white,
                            strokeWidth: isSelected ? 0 : 2,
                            strokeColor: Color.fromARGB(254, 251, 131, 35),
                          );
                        },
                      ),
                    )
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
