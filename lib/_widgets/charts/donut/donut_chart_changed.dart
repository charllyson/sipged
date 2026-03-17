import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_legend_list.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_metrics.dart';
import 'package:sipged/_widgets/charts/donut/donut_legend_shimmer_list.dart';
import 'package:sipged/_widgets/charts/donut/donut_legend_shimmer.dart';

import 'donut_chart_shimmer.dart';
import 'donut_chart_legend.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

enum ValueFormatType { monetary, decimal, integer }

enum DonutLegendPosition { bottom, right, hidden }

class DonutChartChanged extends StatefulWidget {
  final void Function(int?)? onTouch;
  final int? selectedIndex;

  final double? widthGraphic;
  final double? heightGraphic;

  final bool showPercentageOutside;
  final double minPercentForLabel;

  final Color? colorCard;
  final List<Color>? colorsSlices;

  final void Function(String? label)? onTapLabel;
  final String? selectedLabel;

  final List<String> labels;
  final List<double> values;
  final List<double>? filteredValues;

  final DonutLegendPosition legendPosition;
  final ValueFormatType valueFormatType;

  const DonutChartChanged({
    super.key,
    this.onTouch,
    this.selectedIndex,
    this.onTapLabel,
    this.selectedLabel,
    this.widthGraphic,
    this.heightGraphic,
    this.showPercentageOutside = false,
    this.minPercentForLabel = 6.0,
    this.legendPosition = DonutLegendPosition.bottom,
    this.colorsSlices,
    this.valueFormatType = ValueFormatType.monetary,
    required this.labels,
    required this.values,
    this.filteredValues,
    this.colorCard = Colors.white,
  });

  @override
  State<DonutChartChanged> createState() => _DonutChartChangedState();
}

class _DonutChartChangedState extends State<DonutChartChanged> {
  late List<Color> _cores;
  int? _touchedIndex;

  bool get _useLegend => widget.legendPosition != DonutLegendPosition.hidden;

  @override
  void initState() {
    super.initState();
    _ensureColors(widget.values.length);
  }

  @override
  void didUpdateWidget(covariant DonutChartChanged oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.values.length != oldWidget.values.length ||
        (widget.colorsSlices?.length ?? 0) !=
            (oldWidget.colorsSlices?.length ?? 0)) {
      _ensureColors(widget.values.length);

      if (_touchedIndex != null && _touchedIndex! >= widget.values.length) {
        _touchedIndex = null;
      }
    }
  }

  void _ensureColors(int length) {
    if (length <= 0) {
      _cores = const [];
      return;
    }

    if (widget.colorsSlices != null &&
        widget.colorsSlices!.length >= length) {
      _cores = widget.colorsSlices!.take(length).toList();
      return;
    }

    _cores = List.generate(length, (i) => SipGedTheme.chartPaletteColors(i));
  }

  void _updateSelection(int? index) {
    setState(() => _touchedIndex = index);
    widget.onTouch?.call(index);

    if (index == null) {
      widget.onTapLabel?.call(null);
    } else if (index >= 0 && index < widget.labels.length) {
      widget.onTapLabel?.call(widget.labels[index]);
    }
  }

  bool _isHighlighted(int index, int? safeSelectedIndex) {
    final label = widget.labels[index];

    final isSelectedProp =
        (safeSelectedIndex != null && index == safeSelectedIndex) ||
            (widget.selectedLabel != null &&
                label.toUpperCase() == widget.selectedLabel!.toUpperCase());

    return isSelectedProp || _touchedIndex == index;
  }

  @override
  Widget build(BuildContext context) {
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

    final bool hasBasicsInvalid = widget.labels.isEmpty ||
        widget.values.isEmpty ||
        widget.labels.length != widget.values.length;

    final total = widget.values.fold<double>(0, (sum, e) => sum + e);
    final bool totalZero = total == 0;
    final bool showShimmer = hasBasicsInvalid || totalZero;

    final double resolvedCardHeight = widget.heightGraphic ?? 295.0;
    final double resolvedCardWidth = widget.widthGraphic ?? 280.0;

    return SizedBox(
      width: resolvedCardWidth,
      height: resolvedCardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : resolvedCardWidth;

          final double maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : resolvedCardHeight;

          final metrics = DonutChartMetrics.resolve(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            legendPosition: widget.legendPosition,
            showPercentageOutside: widget.showPercentageOutside,
            hasLegend: _useLegend,
            itemCount: widget.labels.length,
          );

          if (showShimmer) {
            final Widget chartShimmer = SizedBox(
              width: metrics.chartSquareSize,
              height: metrics.chartSquareSize,
              child: Center(
                child: DonutChartShimmer(
                  isDark: isDark,
                  largura: metrics.chartSquareSize,
                  altura: metrics.chartSquareSize,
                  outerScale: metrics.shimmerOuterScale,
                  holeScale: metrics.shimmerHoleScale,
                ),
              ),
            );

            final Widget legendShimmerBottom =
            _useLegend && widget.legendPosition == DonutLegendPosition.bottom
                ? SizedBox(
              height: metrics.legendBottomReservedHeight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        DonutLegendShimmer(
                          isDark: isDark,
                          itemCount: math.max(
                            3,
                            math.min(widget.labels.length, 8),
                          ),
                          height: metrics.legendChipHeight,
                          itemMinWidth: metrics.legendChipMinWidth,
                          spacing: metrics.legendSpacing,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink();

            final Widget legendShimmerRight =
            _useLegend && widget.legendPosition == DonutLegendPosition.right
                ? SizedBox(
              width: metrics.legendRightWidth,
              height: metrics.chartHeight,
              child: Scrollbar(
                thumbVisibility: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: DonutLegendShimmerList(
                      isDark: isDark,
                      itemCount: math.max(
                        4,
                        math.min(widget.labels.length, 10),
                      ),
                      height: metrics.legendListItemHeight,
                      itemWidth: metrics.legendRightWidth - 8,
                      spacing: metrics.legendSpacing,
                    ),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink();

            final content = widget.legendPosition == DonutLegendPosition.right
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: metrics.chartWidth,
                  height: metrics.chartHeight,
                  child: Center(child: chartShimmer),
                ),
                if (_useLegend) SizedBox(width: metrics.legendGap),
                if (_useLegend) legendShimmerRight,
              ],
            )
                : Column(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(child: chartShimmer),
                  ),
                ),
                if (_useLegend) SizedBox(height: metrics.chartLegendGap),
                if (_useLegend) legendShimmerBottom,
              ],
            );

            return BasicCard(
              isDark: isDark,
              width: double.infinity,
              padding: metrics.cardPadding,
              gradient: gradient,
              enableShadow: true,
              child: SizedBox.expand(child: content),
            );
          }

          if (_cores.length != widget.values.length) {
            _ensureColors(widget.values.length);
          }

          final safeSelectedIndex = (widget.selectedIndex != null &&
              widget.selectedIndex! >= 0 &&
              widget.selectedIndex! < widget.values.length)
              ? widget.selectedIndex
              : null;

          final bool hasFilteredSeries =
              widget.filteredValues != null && widget.filteredValues!.isNotEmpty;
          final bool hasAnyFilteredValue =
              hasFilteredSeries && widget.filteredValues!.any((v) => v > 0);

          final chart = SizedBox(
            width: metrics.chartSquareSize,
            height: metrics.chartSquareSize,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                centerSpaceRadius: metrics.centerSpaceRadius,
                sectionsSpace: metrics.sectionsSpace,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is! FlTapUpEvent) return;

                    final touched = response?.touchedSection;
                    if (touched == null) {
                      _updateSelection(null);
                      return;
                    }

                    final index = touched.touchedSectionIndex;
                    if (index < 0 || index >= widget.labels.length) return;

                    if (_touchedIndex == index) {
                      _updateSelection(null);
                    } else {
                      _updateSelection(index);
                    }
                  },
                ),
                sections: List.generate(widget.values.length, (i) {
                  final value = widget.values[i];
                  final isHighlighted = _isHighlighted(i, safeSelectedIndex);

                  double filteredValue;
                  if (widget.filteredValues != null &&
                      i < widget.filteredValues!.length) {
                    filteredValue = widget.filteredValues![i];
                  } else {
                    filteredValue = value;
                  }

                  final bool hasSomeFilter =
                      hasFilteredSeries && hasAnyFilteredValue;
                  final bool isInFilter = filteredValue > 0.0;

                  final percentual = total == 0 ? 0.0 : (value / total) * 100;
                  final showInside = percentual >= widget.minPercentForLabel;

                  final titleText = showInside
                      ? (widget.showPercentageOutside
                      ? '${percentual.toStringAsFixed(1)}%'
                      : '${percentual.toStringAsFixed(0)}%')
                      : '';

                  final Color baseColor = _cores[i];

                  Color color;
                  if (value == 0) {
                    color = baseColor.withValues(alpha: 0.15);
                  } else if (isHighlighted) {
                    color = baseColor;
                  } else if (hasSomeFilter && !isInFilter) {
                    color = baseColor.withValues(alpha: 0.30);
                  } else if (hasSomeFilter && isInFilter) {
                    color = baseColor.withValues(alpha: 0.85);
                  } else {
                    color = baseColor;
                  }

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: titleText,
                    radius: isHighlighted
                        ? metrics.sliceRadiusHi
                        : metrics.sliceRadius,
                    titlePositionPercentageOffset: widget.showPercentageOutside
                        ? metrics.titleOutsideOffset
                        : 0.64,
                    titleStyle: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: isHighlighted
                          ? metrics.sectionTitleFontHighlighted
                          : metrics.sectionTitleFont,
                      height: 1.0,
                    ),
                  );
                }),
              ),
            ),
          );

          final legend = DonutChartLegend(
            labels: widget.labels,
            values: widget.values,
            total: total,
            cores: _cores,
            touchedIndex: _touchedIndex,
            valueFormatType: widget.valueFormatType,
            chipHeight: metrics.legendChipHeight,
            labelFontSize: metrics.legendLabelFontSize,
            valueFontSize: metrics.legendValueFontSize,
            chipMinWidth: metrics.legendChipMinWidth,
            spacing: metrics.legendSpacing,
            onLegendTap: (index) {
              _updateSelection(index);
            },
          );

          final Widget legendBottom = !_useLegend
              ? const SizedBox.shrink()
              : SizedBox(
            height: metrics.legendBottomReservedHeight,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      legend,
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          );

          final Widget legendRight = !_useLegend
              ? const SizedBox.shrink()
              : SizedBox(
            width: metrics.legendRightWidth,
            height: metrics.chartHeight,
            child: Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: DonutChartLegendList(
                    labels: widget.labels,
                    values: widget.values,
                    total: total,
                    cores: _cores,
                    touchedIndex: _touchedIndex,
                    valueFormatType: widget.valueFormatType,
                    itemHeight: metrics.legendListItemHeight,
                    labelFontSize: metrics.legendLabelFontSize,
                    percentFontSize: metrics.legendValueFontSize,
                    spacing: metrics.legendSpacing,
                    onLegendTap: (index) {
                      _updateSelection(index);
                    },
                  ),
                ),
              ),
            ),
          );

          final content = widget.legendPosition == DonutLegendPosition.right
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: metrics.chartWidth,
                height: metrics.chartHeight,
                child: Center(child: chart),
              ),
              if (_useLegend) SizedBox(width: metrics.legendGap),
              if (_useLegend) legendRight,
            ],
          )
              : Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: chart),
                ),
              ),
              if (_useLegend) SizedBox(height: metrics.chartLegendGap),
              if (_useLegend) legendBottom,
            ],
          );

          return BasicCard(
            isDark: isDark,
            width: double.infinity,
            padding: metrics.cardPadding,
            gradient: gradient,
            enableShadow: true,
            child: SizedBox.expand(child: content),
          );
        },
      ),
    );
  }
}