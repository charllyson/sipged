import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_metrics.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_shimmer_widget.dart';

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

  final double? widthGraphic;
  final double? heightGraphic;

  final double? widthBar;
  final double? widthTitleBar;

  final List<String> labels;
  final List<double?> values;
  final List<double?>? filteredValues;

  final List<Color>? barColors;
  final String Function(double)? valueFormatter;
  final String? chartTitle;
  final Color? colorCard;

  final bool expandToMaxWidth;
  final BarChartSortType sortType;

  final int? shimmerBarsCount;

  const BarChartChanged({
    super.key,
    this.selectedIndex,
    this.highlightedIndexes,
    this.onBarTap,
    this.widthGraphic,
    this.heightGraphic,
    this.widthBar = 60,
    this.widthTitleBar = 100,
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
  @override
  Widget build(BuildContext context) {
    final hasLengthMismatch = widget.labels.length != widget.values.length;
    final allNull =
        widget.values.isEmpty || widget.values.every((v) => v == null);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Gradient gradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF101018), Color(0xFF171924)],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFF5F7FB)],
    );

    final double resolvedCardWidth = widget.widthGraphic ?? double.infinity;
    final double resolvedCardHeight = widget.heightGraphic ?? 280.0;

    return SizedBox(
      width: resolvedCardWidth,
      height: resolvedCardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (widget.widthGraphic ?? 320.0);

          final double maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (widget.heightGraphic ?? 280.0);

          final int barsCount = widget.labels.isNotEmpty
              ? widget.labels.length
              : (widget.shimmerBarsCount ?? 8);

          final metrics = BarChartMetrics.resolve(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            hasTitle: (widget.chartTitle?.trim().isNotEmpty ?? false),
            barsCount: barsCount,
            expandToMaxWidth: widget.expandToMaxWidth,
            baseBarWidth: widget.widthBar ?? 60,
            baseTitleWidth: widget.widthTitleBar ?? 100,
          );

          final double chartWidth = metrics.computeChartWidth(
            count: barsCount,
            availableInnerWidth: metrics.innerWidth,
            leftReservedSize: metrics.leftReservedSize,
          );

          if (hasLengthMismatch || allNull) {
            final int count = widget.labels.isNotEmpty
                ? widget.labels.length
                : (widget.shimmerBarsCount ?? 8);

            return BasicCard(
              isDark: isDark,
              width: double.infinity,
              padding: metrics.cardPadding,
              gradient: gradient,
              enableShadow: true,
              child: SizedBox.expand(
                child: BarChartShimmerWidget(
                  barsCount: count,
                  isDark: isDark,
                  barWidth: metrics.barWidth,
                  titleWidth: metrics.titleWidth,
                  height: metrics.chartHeight,
                  spacing: metrics.groupsSpace,
                  chartWidth: chartWidth,
                  chartTitle: widget.chartTitle,
                  labels: widget.labels,
                  titleHeight: metrics.titleHeight,
                  titleBottomGap: metrics.titleBottomGap,
                  leftReservedSize: metrics.leftReservedSize,
                  axisTickWidth: metrics.axisTickWidth,
                  axisGap: metrics.axisGap,
                  labelHeight: metrics.shimmerLabelHeight,
                  barRadius: metrics.barRadius,
                  titleFontSize: metrics.titleFontSize,
                ),
              ),
            );
          }

          final totalBars = widget.values.length;
          final List<int> indices = List.generate(totalBars, (i) => i);

          int compareValues(int a, int b) {
            final va = widget.values[a] ?? 0.0;
            final vb = widget.values[b] ?? 0.0;
            return va.compareTo(vb);
          }

          int compareLabels(int a, int b) {
            final la = widget.labels[a];
            final lb = widget.labels[b];
            return la.toUpperCase().compareTo(lb.toUpperCase());
          }

          switch (widget.sortType) {
            case BarChartSortType.ascending:
              indices.sort(compareValues);
              break;
            case BarChartSortType.descending:
              indices.sort((a, b) => compareValues(b, a));
              break;
            case BarChartSortType.labelAZ:
              indices.sort(compareLabels);
              break;
            case BarChartSortType.labelZA:
              indices.sort((a, b) => compareLabels(b, a));
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
              (i < widget.barColors!.length
                  ? widget.barColors![i]
                  : Colors.cyan),
          ];

          final nonNullValues = valuesSorted.whereType<double>().toList();

          if (nonNullValues.isEmpty) {
            final int count =
            totalBars > 0 ? totalBars : (widget.shimmerBarsCount ?? 8);

            return BasicCard(
              isDark: isDark,
              width: double.infinity,
              padding: metrics.cardPadding,
              gradient: gradient,
              enableShadow: true,
              child: SizedBox.expand(
                child: BarChartShimmerWidget(
                  barsCount: count,
                  isDark: isDark,
                  barWidth: metrics.barWidth,
                  titleWidth: metrics.titleWidth,
                  height: metrics.chartHeight,
                  spacing: metrics.groupsSpace,
                  chartWidth: chartWidth,
                  chartTitle: widget.chartTitle,
                  labels: widget.labels,
                  titleHeight: metrics.titleHeight,
                  titleBottomGap: metrics.titleBottomGap,
                  leftReservedSize: metrics.leftReservedSize,
                  axisTickWidth: metrics.axisTickWidth,
                  axisGap: metrics.axisGap,
                  labelHeight: metrics.shimmerLabelHeight,
                  barRadius: metrics.barRadius,
                  titleFontSize: metrics.titleFontSize,
                ),
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

          final String Function(double) fmt =
              widget.valueFormatter ?? SipGedFormatMoney.doubleToText;

          final double maxCalculado =
          (nonNullValues.reduce(math.max) * 1.2).ceilToDouble();
          final double maxY = math.max(maxCalculado, 10);

          return BasicCard(
            isDark: isDark,
            width: double.infinity,
            padding: metrics.cardPadding,
            gradient: gradient,
            enableShadow: true,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.chartTitle != null) ...[
                    SizedBox(
                      height: metrics.titleHeight,
                      child: Center(
                        child: Text(
                          widget.chartTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: metrics.titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.titleBottomGap),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: metrics.chartHeight,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            groupsSpace: metrics.groupsSpace,
                            alignment: totalBars == 1
                                ? BarChartAlignment.center
                                : BarChartAlignment.spaceEvenly,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              drawHorizontalLine: true,
                              horizontalInterval: math.max(1, (maxY / 5)).toDouble(),
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.grey.shade300,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.12),
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
                                  reservedSize: metrics.bottomReservedSize,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= labelsSorted.length) {
                                      return const SizedBox.shrink();
                                    }

                                    return SizedBox(
                                      width: metrics.titleWidth,
                                      child: Text(
                                        labelsSorted[idx],
                                        textAlign: TextAlign.center,
                                        maxLines: metrics.bottomLabelMaxLines,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: metrics.bottomLabelFontSize,
                                          color: isDark ? Colors.white : Colors.black,
                                          height: 1.05,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: metrics.leftReservedSize,
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: EdgeInsets.only(right: metrics.axisGap),
                                    child: Text(
                                      widget.valueFormatter != null
                                          ? widget.valueFormatter!(value)
                                          : SipGedFormatMoney.compactSimple(value),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: metrics.leftLabelFontSize,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
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
                                color = baseColor.withValues(alpha: 0.20);
                              } else if (isSelected) {
                                color = Colors.orange;
                              } else if (hasSomeFilter && !isInFilter) {
                                color = baseColor.withValues(alpha: 0.20);
                              } else if (hasSelection) {
                                color = baseColor.withValues(alpha: 0.10);
                              } else if (isHighlighted) {
                                color = baseColor;
                              } else {
                                color = baseColor;
                              }

                              return BarChartGroupData(
                                x: sortedIndex,
                                barsSpace: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: toY,
                                    color: color,
                                    borderRadius:
                                    BorderRadius.circular(metrics.barRadius),
                                    width: metrics.barWidth,
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
              ),
            ),
          );
        },
      ),
    );
  }
}