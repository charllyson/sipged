import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/cards/basic/basic_card.dart';

import 'bar_chart_shimmer_widget.dart';

/// Tipos de ordenação do gráfico de barras
enum BarChartSortType {
  none,
  ascending,
  descending,
  labelAZ,
  labelZA,
}

class BarChartChanged extends StatefulWidget {
  final int? selectedIndex;
  final List<int>? highlightedIndexes;
  final void Function(String label)? onBarTap;
  final double? widthBar;
  final double? widthTitleBar;
  final double? heightGraphic;
  final List<String> labels;
  final List<double?> values;
  final List<double?>? filteredValues;
  final List<Color>? barColors;
  final String Function(double)? valueFormatter;
  final String? chartTitle;
  final Color? colorCard;
  final bool expandToMaxWidth;
  final BarChartSortType sortType;

  /// ✅ Quantidade de barras do shimmer quando não há labels/valores ainda.
  /// Se null, usa (labels.length se > 0) senão 8.
  final int? shimmerBarsCount;

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
    this.filteredValues,
    this.barColors,
    this.valueFormatter,
    this.chartTitle,
    this.colorCard = Colors.white,
    this.expandToMaxWidth = false,
    this.sortType = BarChartSortType.none,
    this.shimmerBarsCount,
  });

  @override
  State<BarChartChanged> createState() => _BarChartChangedState();
}

class _BarChartChangedState extends State<BarChartChanged> {
  /// ✅ GAP mínimo absoluto entre barras (mobile estreito)
  static const double _minGroupsSpace = 12.0;

  /// Limite superior para evitar barras gigantes em telas muito largas
  static const double _maxBarWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    final hasLengthMismatch = widget.labels.length != widget.values.length;
    final allNull =
        widget.values.isEmpty || widget.values.every((v) => v == null);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Gradient? gradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF101018),
        Color(0xFF171924),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Color(0xFFF5F7FB),
      ],
    );

    final double height = widget.heightGraphic ?? 220;

    // ============================
    // CASO 1: Shimmer (sem dados)
    // ============================
    if (hasLengthMismatch || allNull) {
      final int count = widget.labels.isNotEmpty
          ? widget.labels.length
          : (widget.shimmerBarsCount ?? 8);

      return BasicCard(
        isDark: isDark,
        width: widget.expandToMaxWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        gradient: gradient,
        enableShadow: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double baseBarWidth = widget.widthBar ?? 60;
            double barWidth = baseBarWidth;
            double groupsSpace = _minGroupsSpace; // ✅ mínimo

            double minWidthNeeded =
                count * (barWidth + groupsSpace) + groupsSpace;

            double chartWidth;

            if (widget.expandToMaxWidth &&
                constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0) {
              final double viewWidth = constraints.maxWidth;

              if (viewWidth > minWidthNeeded && count > 0) {
                final double scale = viewWidth / minWidthNeeded;

                barWidth = (barWidth * scale).clamp(4.0, _maxBarWidth);
                // ✅ nunca deixa o gap ficar menor que 12
                groupsSpace = math.max(_minGroupsSpace, groupsSpace * scale);

                minWidthNeeded =
                    count * (barWidth + groupsSpace) + groupsSpace;

                chartWidth = viewWidth;
              } else {
                chartWidth = minWidthNeeded;
              }
            } else {
              chartWidth = minWidthNeeded;
            }

            return BarChartShimmerWidget(
              barsCount: count,
              isDark: isDark,
              barWidth: barWidth,
              titleWidth: widget.widthTitleBar ?? 100,
              height: height,
              spacing: groupsSpace, // ✅ já vem com >= 12
              chartWidth: chartWidth,
              chartTitle: widget.chartTitle,
              labels: widget.labels,
            );
          },
        ),
      );
    }

    // ============================
    // CASO 2: Gráfico com dados
    // ============================
    final totalBars = widget.values.length;

    // 1) Índices + ordenação
    final List<int> indices = List.generate(totalBars, (i) => i);

    int _compareValues(int a, int b) {
      final va = widget.values[a] ?? 0.0;
      final vb = widget.values[b] ?? 0.0;
      return va.compareTo(vb);
    }

    int _compareLabels(int a, int b) {
      final la = widget.labels[a];
      final lb = widget.labels[b];
      return la.toUpperCase().compareTo(lb.toUpperCase());
    }

    switch (widget.sortType) {
      case BarChartSortType.ascending:
        indices.sort(_compareValues);
        break;
      case BarChartSortType.descending:
        indices.sort((a, b) => _compareValues(b, a));
        break;
      case BarChartSortType.labelAZ:
        indices.sort(_compareLabels);
        break;
      case BarChartSortType.labelZA:
        indices.sort((a, b) => _compareLabels(b, a));
        break;
      case BarChartSortType.none:
        break;
    }

    final Map<int, int> origToSorted = {
      for (int pos = 0; pos < indices.length; pos++) indices[pos]: pos,
    };

    final List<String> labelsSorted = [
      for (final i in indices) widget.labels[i],
    ];
    final List<double?> valuesSorted = [
      for (final i in indices) widget.values[i],
    ];
    final List<double?>? filteredSorted = widget.filteredValues == null
        ? null
        : [
      for (final i in indices)
        (i < widget.filteredValues!.length
            ? widget.filteredValues![i]
            : null),
    ];
    final List<Color>? colorsSorted = widget.barColors == null
        ? null
        : [
      for (final i in indices)
        (i < widget.barColors!.length ? widget.barColors![i] : Colors.cyan),
    ];

    final nonNullValues = valuesSorted.whereType<double>().toList();
    if (nonNullValues.isEmpty) {
      final int count =
      totalBars > 0 ? totalBars : (widget.shimmerBarsCount ?? 8);

      return BasicCard(
        isDark: isDark,
        width: widget.expandToMaxWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        gradient: gradient,
        enableShadow: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double baseBarWidth = widget.widthBar ?? 60;
            double barWidth = baseBarWidth;
            double groupsSpace = _minGroupsSpace; // ✅ mínimo

            double minWidthNeeded =
                count * (barWidth + groupsSpace) + groupsSpace;

            double chartWidth;

            if (widget.expandToMaxWidth &&
                constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0) {
              final double viewWidth = constraints.maxWidth;

              if (viewWidth > minWidthNeeded && count > 0) {
                final double scale = viewWidth / minWidthNeeded;

                barWidth = (barWidth * scale).clamp(4.0, _maxBarWidth);
                // ✅ nunca deixa o gap ficar menor que 12
                groupsSpace = math.max(_minGroupsSpace, groupsSpace * scale);

                minWidthNeeded =
                    count * (barWidth + groupsSpace) + groupsSpace;

                chartWidth = viewWidth;
              } else {
                chartWidth = minWidthNeeded;
              }
            } else {
              chartWidth = minWidthNeeded;
            }

            return BarChartShimmerWidget(
              barsCount: count,
              isDark: isDark,
              barWidth: barWidth,
              titleWidth: widget.widthTitleBar ?? 100,
              height: height,
              spacing: groupsSpace, // ✅ já vem com >= 12
              chartWidth: chartWidth,
              chartTitle: widget.chartTitle,
              labels: widget.labels,
            );
          },
        ),
      );
    }

    final bool hasFilteredSeries =
        filteredSorted != null && filteredSorted.isNotEmpty;
    final bool hasAnyFilteredValue =
        hasFilteredSeries && filteredSorted.whereType<double>().any((v) => v > 0);

    final int? externalSelectedOriginal = widget.selectedIndex;
    int? effectiveSelectedSorted;

    if (externalSelectedOriginal != null) {
      effectiveSelectedSorted = origToSorted[externalSelectedOriginal];
    }

    final List<int>? highlightedSorted =
    widget.highlightedIndexes == null || widget.highlightedIndexes!.isEmpty
        ? null
        : widget.highlightedIndexes!
        .map((orig) => origToSorted[orig])
        .whereType<int>()
        .toList();

    final bool hasSelection = effectiveSelectedSorted != null;

    final String Function(double) fmt = widget.valueFormatter ?? priceToString;

    final double maxCalculado =
    (nonNullValues.reduce(math.max) * 1.2).ceilToDouble();
    final double maxY = math.max(maxCalculado, 10);

    return BasicCard(
      isDark: isDark,
      width: widget.expandToMaxWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      gradient: gradient,
      enableShadow: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double baseBarWidth = widget.widthBar ?? 60;
          double barWidth = baseBarWidth;
          double groupsSpace = _minGroupsSpace; // ✅ mínimo

          double minWidthNeeded =
              totalBars * (barWidth + groupsSpace) + groupsSpace;

          double chartWidth;

          if (widget.expandToMaxWidth &&
              constraints.maxWidth.isFinite &&
              constraints.maxWidth > 0) {
            final double viewWidth = constraints.maxWidth;

            if (viewWidth > minWidthNeeded && totalBars > 0) {
              final double scale = viewWidth / minWidthNeeded;

              barWidth = (barWidth * scale).clamp(4.0, _maxBarWidth);
              // ✅ nunca deixa o gap ficar menor que 12
              groupsSpace = math.max(_minGroupsSpace, groupsSpace * scale);

              minWidthNeeded =
                  totalBars * (barWidth + groupsSpace) + groupsSpace;

              chartWidth = viewWidth;
            } else {
              chartWidth = minWidthNeeded;
            }
          } else {
            chartWidth = minWidthNeeded;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.chartTitle != null) ...[
                Center(
                  child: Text(
                    widget.chartTitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: height,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        groupsSpace: groupsSpace, // ✅ >= 12 sempre
                        alignment: totalBars == 1
                            ? BarChartAlignment.center
                            : BarChartAlignment.spaceEvenly,
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
                            tooltipPadding: const EdgeInsets.all(6),
                            tooltipMargin: 2,
                            fitInsideVertically: true,
                            fitInsideHorizontally: true,
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) {
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
                              if (index >= 0 && index < labelsSorted.length) {
                                widget.onBarTap?.call(labelsSorted[index]);
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
                                if (idx < 0 || idx >= labelsSorted.length) {
                                  return const SizedBox();
                                }
                                final label = labelsSorted[idx];
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
                              reservedSize: 70,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  (widget.valueFormatter ?? formatToMillions)(
                                      value),
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
                        barGroups: valuesSorted.asMap().entries.map((entry) {
                          final sortedIndex = entry.key;
                          final totalValue = entry.value;

                          final double toY = totalValue ?? 0.0;

                          double? filteredValue;
                          if (filteredSorted != null &&
                              sortedIndex < filteredSorted.length) {
                            filteredValue = filteredSorted[sortedIndex];
                          } else {
                            filteredValue = totalValue;
                          }

                          final bool isSelected =
                              effectiveSelectedSorted == sortedIndex;
                          final bool isHighlighted =
                              highlightedSorted?.contains(sortedIndex) ?? false;

                          final Color baseColor =
                          (colorsSorted != null &&
                              sortedIndex < colorsSorted.length)
                              ? colorsSorted[sortedIndex]
                              : Colors.cyan;

                          final bool hasSomeFilter =
                              hasFilteredSeries && hasAnyFilteredValue;
                          final bool isInFilter = (filteredValue ?? 0.0) > 0.0;

                          Color color;
                          if (toY == 0) {
                            color = baseColor.withOpacity(0.20);
                          } else if (isSelected) {
                            color = Colors.orange;
                          } else if (hasSomeFilter && !isInFilter) {
                            color = baseColor.withOpacity(0.20);
                          } else if (hasSelection) {
                            color = baseColor.withOpacity(0.1);
                          } else if (isHighlighted) {
                            color = baseColor;
                          } else {
                            color = baseColor;
                          }

                          return BarChartGroupData(
                            x: sortedIndex,
                            barRods: [
                              BarChartRodData(
                                toY: toY,
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                                width: barWidth,
                              ),
                            ],
                            showingTooltipIndicators: isSelected ? [0] : [],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
