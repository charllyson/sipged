import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_utils/formats/format_field.dart';

import 'bar_chart_shimmer_widget.dart';

class BarChartChanged extends StatefulWidget {
  final int? selectedIndex;
  final List<int>? highlightedIndexes;
  final void Function(String label)? onBarTap;

  final double? widthBar;
  final double? widthTitleBar;
  final double? heightGraphic;

  final List<String> labels;
  final List<double?> values;
  final List<Color>? barColors;

  final String Function(double)? valueFormatter;
  final String? chartTitle;
  final Color? colorCard;

  /// Quando `true`, o gráfico tenta ocupar toda a largura disponível,
  /// ajustando automaticamente a largura de cada barra.
  /// Quando `false` (default), a largura é calculada por barra + espaçamento,
  /// e o gráfico pode exigir scroll horizontal.
  final bool expandToMaxWidth;

  const BarChartChanged({
    super.key,
    this.selectedIndex,
    this.highlightedIndexes,
    this.onBarTap,
    this.widthBar = 60,
    this.widthTitleBar = 100,
    this.heightGraphic = 220,
    required this.labels,
    required this.values,
    this.barColors,
    this.valueFormatter,
    this.chartTitle,
    this.colorCard = Colors.white,
    this.expandToMaxWidth = false,
  });

  @override
  State<BarChartChanged> createState() => _BarChartChangedState();
}

class _BarChartChangedState extends State<BarChartChanged> {
  Widget _noData() {
    final count = (widget.labels.isNotEmpty ? widget.labels.length : 8);
    return BarChartShimmerWidget(
      barsCount: count,
      barWidth: widget.widthBar ?? 60,
      titleWidth: widget.widthTitleBar ?? 100,
      chartTitle: widget.chartTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLengthMismatch = widget.labels.length != widget.values.length;
    final allNull = widget.values.isEmpty || widget.values.every((v) => v == null);

    if (hasLengthMismatch || allNull) {
      return _noData();
    }

    // valores não-nulos para cálculo de escala
    final nonNullValues = widget.values.whereType<double>().toList();
    if (nonNullValues.isEmpty) return _noData();

    final totalBars = widget.values.length;
    const spacingExtra = 24.0;

    // Usamos LayoutBuilder pra pegar a largura disponível quando expandToMaxWidth=true
    return Card(
      color: widget.colorCard,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double chartWidth;
            double? computedBarWidth = widget.widthBar;

            if (widget.expandToMaxWidth) {
              chartWidth = constraints.maxWidth;
              // espaço restante para as barras depois de descontar o espaçamento entre elas
              final available = chartWidth - (spacingExtra * totalBars);
              computedBarWidth = max(2.0, available / totalBars); // evita barras zeradas/negativas
            } else {
              chartWidth =
                  totalBars * ((widget.widthBar ?? 60) + spacingExtra).toDouble();
            }

            final String Function(double) fmt = widget.valueFormatter ?? priceToString;
            final double maxCalculado = (nonNullValues.reduce(max) * 1.2).ceilToDouble();
            final double maxY = max(maxCalculado, 10);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.chartTitle != null) ...[
                  Center(
                    child: Text(
                      widget.chartTitle!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // mesmo com expandToMaxWidth, manter o scroll aqui não atrapalha:
                  // quando expand=true, chartWidth == maxWidth e não haverá rolagem;
                  // quando expand=false, rola normalmente.
                  child: SizedBox(
                    height: widget.heightGraphic,
                    width: chartWidth,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.spaceBetween,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          drawHorizontalLine: true,
                          horizontalInterval: (maxY / 5).ceilToDouble(),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            tooltipPadding: const EdgeInsets.all(6),
                            tooltipMargin: 2,
                            fitInsideVertically: true,
                            fitInsideHorizontally: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                fmt(rod.toY),
                                const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          touchCallback: (event, response) {
                            if (event is FlTapUpEvent && response?.spot != null) {
                              final index = response!.spot!.touchedBarGroupIndex;
                              if (index >= 0 && index < widget.labels.length) {
                                widget.onBarTap?.call(widget.labels[index]);
                              }
                            }
                          },
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= widget.labels.length) {
                                  return const SizedBox();
                                }
                                final label = widget.labels[idx];
                                return SizedBox(
                                  width: widget.widthTitleBar,
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 70, // largura pros números da escala
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  (widget.valueFormatter ?? formatToMillions)(value),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: widget.values.asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value; // pode ser null
                          final isSelected = widget.selectedIndex == index;
                          final isHighlighted =
                              widget.highlightedIndexes?.contains(index) ?? false;

                          // se for null, desenha 0, mas com cor "neutra"
                          final double toY = value ?? 0.0;
                          final Color baseColor =
                              widget.barColors?[index] ?? Colors.cyan;
                          final Color color = value == null
                              ? Colors.grey.shade300
                              : (isSelected
                              ? Colors.orange
                              : (isHighlighted ? Colors.amber : baseColor));

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: toY,
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                                width: computedBarWidth,
                              ),
                            ],
                            showingTooltipIndicators: isSelected ? [0] : [],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
