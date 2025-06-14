import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

class BarChartSample extends StatelessWidget {
  final List<ApostillesData>? apostilles;
  final List<AdditiveData>? additives;
  final int? selectedIndex;
  final void Function(int)? onBarTap;
  final double larguraGrafico;

  const BarChartSample({
    super.key,
    this.apostilles,
    this.additives,
    this.selectedIndex,
    this.onBarTap,
    required this.larguraGrafico,
  });

  @override
  Widget build(BuildContext context) {
    final isApostille = apostilles != null;
    final list = isApostille ? apostilles! : additives!;
    final values = list.map((e) {
      return isApostille
          ? (e as ApostillesData).apostillevalue ?? 0
          : (e as AdditiveData).additivevalue ?? 0;
    }).toList();

    double maxY = values.fold<double>(0, max) * 1.2;
    maxY = (maxY / 5000000).ceil() * 5000000;

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 210,
          width: larguraGrafico,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                horizontalInterval: 5000000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  tooltipPadding: const EdgeInsets.all(6),
                  tooltipMargin: 4,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      priceToString(rod.toY),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent && response?.spot != null) {
                    onBarTap?.call(response!.spot!.touchedBarGroupIndex);
                  }
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text((value.toInt() + 1).toString());
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 70,
                    getTitlesWidget: (value, meta) {
                      if (value == maxY) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          formatToMillions(value),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: values.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                final isSelected = selectedIndex == index;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: isSelected ? Colors.orange : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                      width: 70,
                    ),
                  ],
                  showingTooltipIndicators: isSelected ? [0] : [],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
