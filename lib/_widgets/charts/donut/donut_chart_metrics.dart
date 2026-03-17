import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';

class DonutChartMetrics {
  final EdgeInsets cardPadding;

  final double chartHeight;
  final double chartWidth;
  final double chartSquareSize;

  final double sliceRadius;
  final double sliceRadiusHi;
  final double centerSpaceRadius;
  final double sectionsSpace;
  final double titleOutsideOffset;

  final double sectionTitleFont;
  final double sectionTitleFontHighlighted;

  final double chartLegendGap;
  final double legendGap;

  final double legendBottomReservedHeight;
  final double legendChipHeight;
  final double legendChipMinWidth;
  final double legendListItemHeight;
  final double legendLabelFontSize;
  final double legendValueFontSize;
  final double legendSpacing;
  final double legendRightWidth;

  final double shimmerOuterScale;
  final double shimmerHoleScale;

  const DonutChartMetrics({
    required this.cardPadding,
    required this.chartHeight,
    required this.chartWidth,
    required this.chartSquareSize,
    required this.sliceRadius,
    required this.sliceRadiusHi,
    required this.centerSpaceRadius,
    required this.sectionsSpace,
    required this.titleOutsideOffset,
    required this.sectionTitleFont,
    required this.sectionTitleFontHighlighted,
    required this.chartLegendGap,
    required this.legendGap,
    required this.legendBottomReservedHeight,
    required this.legendChipHeight,
    required this.legendChipMinWidth,
    required this.legendListItemHeight,
    required this.legendLabelFontSize,
    required this.legendValueFontSize,
    required this.legendSpacing,
    required this.legendRightWidth,
    required this.shimmerOuterScale,
    required this.shimmerHoleScale,
  });

  static DonutChartMetrics resolve({
    required double maxWidth,
    required double maxHeight,
    required DonutLegendPosition legendPosition,
    required bool showPercentageOutside,
    required bool hasLegend,
    required int itemCount,
  }) {
    final bool ultraCompact = maxWidth <= 240 || maxHeight <= 210;
    final bool veryCompact = maxWidth <= 280 || maxHeight <= 240;
    final bool compact = maxWidth <= 340 || maxHeight <= 280;
    final bool medium = maxWidth <= 420 || maxHeight <= 340;

    final EdgeInsets cardPadding = ultraCompact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : veryCompact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 14);

    final double innerHeight = math.max(80.0, maxHeight - cardPadding.vertical);
    final double innerWidth = math.max(120.0, maxWidth - cardPadding.horizontal);

    final double chartLegendGap = hasLegend
        ? (ultraCompact
        ? 4.0
        : veryCompact
        ? 5.0
        : compact
        ? 6.0
        : 8.0)
        : 0.0;

    final double legendGap = hasLegend
        ? (ultraCompact
        ? 6.0
        : veryCompact
        ? 8.0
        : 10.0)
        : 0.0;

    final double legendChipHeight = ultraCompact
        ? 32.0
        : veryCompact
        ? 34.0
        : compact
        ? 38.0
        : medium
        ? 42.0
        : 46.0;

    final double legendChipMinWidth = ultraCompact
        ? 86.0
        : veryCompact
        ? 96.0
        : compact
        ? 108.0
        : medium
        ? 120.0
        : 132.0;

    final double legendListItemHeight = ultraCompact
        ? 32.0
        : veryCompact
        ? 34.0
        : compact
        ? 38.0
        : medium
        ? 42.0
        : 46.0;

    final double legendLabelFontSize = ultraCompact
        ? 9.5
        : veryCompact
        ? 10.0
        : compact
        ? 11.0
        : 12.0;

    final double legendValueFontSize = ultraCompact
        ? 9.0
        : veryCompact
        ? 9.5
        : compact
        ? 10.5
        : 11.5;

    final double legendSpacing = ultraCompact
        ? 5.0
        : veryCompact
        ? 6.0
        : compact
        ? 7.0
        : 8.0;

    double resolvedLegendRightWidth = 0.0;
    if (legendPosition == DonutLegendPosition.right && hasLegend) {
      final double target = innerWidth *
          (ultraCompact
              ? 0.44
              : veryCompact
              ? 0.41
              : compact
              ? 0.38
              : 0.34);

      final double minAllowed = ultraCompact
          ? 110.0
          : veryCompact
          ? 120.0
          : 132.0;

      final double maxAllowed = math.max(
        minAllowed,
        innerWidth *
            (ultraCompact
                ? 0.50
                : veryCompact
                ? 0.46
                : compact
                ? 0.42
                : 0.38),
      );

      resolvedLegendRightWidth =
          target.clamp(minAllowed, maxAllowed).toDouble();
    }

    final double legendBottomReservedHeight =
    legendPosition == DonutLegendPosition.bottom && hasLegend
        ? legendChipHeight +
        (ultraCompact
            ? 8.0
            : veryCompact
            ? 9.0
            : 10.0)
        : 0.0;

    final double availableChartHeight =
    legendPosition == DonutLegendPosition.bottom
        ? math.max(
      90.0,
      innerHeight - legendBottomReservedHeight - chartLegendGap,
    )
        : innerHeight;

    final double availableChartWidth =
    legendPosition == DonutLegendPosition.right
        ? math.max(
      100.0,
      innerWidth - resolvedLegendRightWidth - legendGap,
    )
        : innerWidth;

    final double rawSquare = math.min(availableChartWidth, availableChartHeight);

    final double squareScale = ultraCompact
        ? 0.78
        : veryCompact
        ? 0.82
        : compact
        ? 0.88
        : 0.92;

    final double chartSquareSize =
    (rawSquare * squareScale).clamp(80.0, rawSquare);

    final double chartWidth = legendPosition == DonutLegendPosition.right
        ? availableChartWidth
        : innerWidth;

    final double chartHeight = availableChartHeight;

    final double outerSafety = showPercentageOutside
        ? (ultraCompact
        ? 20.0
        : veryCompact
        ? 22.0
        : 24.0)
        : (ultraCompact
        ? 12.0
        : veryCompact
        ? 14.0
        : 16.0);

    final double maxOuterRadius =
    ((chartSquareSize / 2) - outerSafety).clamp(18.0, 220.0).toDouble();

    double sliceRadius = (maxOuterRadius * 0.96).clamp(16.0, maxOuterRadius);

    if (showPercentageOutside) {
      sliceRadius = (sliceRadius * 0.88).clamp(16.0, maxOuterRadius);
    }

    final double sliceRadiusHi = (sliceRadius +
        (ultraCompact
            ? 2.0
            : veryCompact
            ? 3.0
            : 4.0))
        .clamp(sliceRadius, maxOuterRadius);

    final double centerSpaceRadius = (sliceRadius *
        (ultraCompact
            ? 0.34
            : veryCompact
            ? 0.36
            : compact
            ? 0.39
            : 0.42))
        .clamp(10.0, sliceRadius - 8.0);

    final double sectionsSpace = ultraCompact
        ? 0.8
        : veryCompact
        ? 1.0
        : compact
        ? 1.4
        : 2.0;

    final double titleOutsideOffset = ultraCompact
        ? 1.18
        : veryCompact
        ? 1.24
        : compact
        ? 1.30
        : 1.38;

    final double sectionTitleFont =
    (sliceRadius * (ultraCompact ? 0.12 : 0.14)).clamp(7.0, 14.0);

    final double sectionTitleFontHighlighted =
    (sectionTitleFont + 1.0).clamp(8.0, 15.0);

    final double shimmerOuterScale =
        (sliceRadius * 2) / math.max(1.0, chartSquareSize);

    final double shimmerHoleScale =
        (centerSpaceRadius * 2) / math.max(1.0, chartSquareSize);

    return DonutChartMetrics(
      cardPadding: cardPadding,
      chartHeight: chartHeight,
      chartWidth: chartWidth,
      chartSquareSize: chartSquareSize,
      sliceRadius: sliceRadius,
      sliceRadiusHi: sliceRadiusHi,
      centerSpaceRadius: centerSpaceRadius,
      sectionsSpace: sectionsSpace,
      titleOutsideOffset: titleOutsideOffset,
      sectionTitleFont: sectionTitleFont,
      sectionTitleFontHighlighted: sectionTitleFontHighlighted,
      chartLegendGap: chartLegendGap,
      legendGap: legendGap,
      legendBottomReservedHeight: legendBottomReservedHeight,
      legendChipHeight: legendChipHeight,
      legendChipMinWidth: legendChipMinWidth,
      legendListItemHeight: legendListItemHeight,
      legendLabelFontSize: legendLabelFontSize,
      legendValueFontSize: legendValueFontSize,
      legendSpacing: legendSpacing,
      legendRightWidth: resolvedLegendRightWidth,
      shimmerOuterScale: shimmerOuterScale.clamp(0.35, 0.95),
      shimmerHoleScale: shimmerHoleScale.clamp(0.14, 0.60),
    );
  }
}