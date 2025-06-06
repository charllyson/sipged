import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_datas/apostilles/apostilles_data.dart';

class BarChartSample extends StatelessWidget {
  final List<ApostillesData>? apostilles;

  const BarChartSample({super.key, this.apostilles});

  @override
  Widget build(BuildContext context) {
    final barGroups = apostilles!
        .where((e) => e.apostilleorder != null && e.apostillevalue != null)
        .map((e) => BarChartGroupData(
      x: e.apostilleorder!,
      barRods: [
        BarChartRodData(
          toY: e.apostillevalue!,
          width: 100,
          borderRadius: BorderRadius.circular(4),
          color: Colors.blue,
        ),
      ],
    ))
        .toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final match = apostilles!.firstWhere(
                      (a) => a.apostilleorder == value.toInt(),
                  //orElse: () => ApostillesData(),
                );
                return Text(
                  match.apostilleorder?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                );
              },
              reservedSize: 28,
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
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final match = apostilles!.firstWhere(
                    (a) => a.apostilleorder == group.x,
                //orElse: () => ApostillesData(),
              );
              return BarTooltipItem(
                priceToString(match.apostillevalue),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}
