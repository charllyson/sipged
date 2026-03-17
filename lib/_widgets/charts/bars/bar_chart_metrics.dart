import 'dart:math' as math;
import 'package:flutter/material.dart';

class BarChartMetrics {
  final EdgeInsets cardPadding;

  final double innerWidth;
  final double innerHeight;

  final double titleHeight;
  final double titleFontSize;
  final double titleBottomGap;

  final double chartHeight;

  final double barWidth;
  final double titleWidth;
  final double groupsSpace;
  final double barRadius;

  final double leftReservedSize;
  final double leftLabelFontSize;
  final double axisTickWidth;
  final double axisGap;

  final double bottomReservedSize;
  final double bottomLabelFontSize;
  final int bottomLabelMaxLines;

  final double shimmerLabelHeight;

  const BarChartMetrics({
    required this.cardPadding,
    required this.innerWidth,
    required this.innerHeight,
    required this.titleHeight,
    required this.titleFontSize,
    required this.titleBottomGap,
    required this.chartHeight,
    required this.barWidth,
    required this.titleWidth,
    required this.groupsSpace,
    required this.barRadius,
    required this.leftReservedSize,
    required this.leftLabelFontSize,
    required this.axisTickWidth,
    required this.axisGap,
    required this.bottomReservedSize,
    required this.bottomLabelFontSize,
    required this.bottomLabelMaxLines,
    required this.shimmerLabelHeight,
  });

  static const double _minGroupsSpace = 4.0;
  static const double _maxGroupsSpace = 14.0;

  static const double _minBarWidth = 16.0;
  static const double _maxBarWidth = 120.0;

  static BarChartMetrics resolve({
    required double maxWidth,
    required double maxHeight,
    required bool hasTitle,
    required int barsCount,
    required bool expandToMaxWidth,
    required double baseBarWidth,
    required double baseTitleWidth,
  }) {
    final bool ultraCompact = maxWidth <= 240 || maxHeight <= 210;
    final bool veryCompact = maxWidth <= 300 || maxHeight <= 240;
    final bool compact = maxWidth <= 380 || maxHeight <= 300;
    final bool medium = maxWidth <= 520 || maxHeight <= 380;

    final EdgeInsets cardPadding = ultraCompact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : veryCompact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 14);

    final double innerWidth = math.max(120.0, maxWidth - cardPadding.horizontal);
    final double innerHeight = math.max(120.0, maxHeight - cardPadding.vertical);

    final double titleHeight = hasTitle
        ? (ultraCompact
        ? 18.0
        : veryCompact
        ? 20.0
        : compact
        ? 22.0
        : 24.0)
        : 0.0;

    final double titleFontSize = ultraCompact
        ? 12.0
        : veryCompact
        ? 13.0
        : compact
        ? 14.0
        : 16.0;

    final double titleBottomGap = hasTitle
        ? (ultraCompact
        ? 6.0
        : veryCompact
        ? 8.0
        : 10.0)
        : 0.0;

    final double bottomReservedSize = ultraCompact
        ? 36.0
        : veryCompact
        ? 42.0
        : compact
        ? 48.0
        : 56.0;

    final double leftReservedSize = ultraCompact
        ? 42.0
        : veryCompact
        ? 50.0
        : compact
        ? 58.0
        : 66.0;

    final double leftLabelFontSize = ultraCompact
        ? 8.5
        : veryCompact
        ? 9.5
        : compact
        ? 10.0
        : 11.0;

    final double bottomLabelFontSize = ultraCompact
        ? 8.0
        : veryCompact
        ? 8.5
        : compact
        ? 9.0
        : 10.0;

    final int bottomLabelMaxLines = ultraCompact ? 1 : 2;

    final double axisTickWidth = ultraCompact
        ? 24.0
        : veryCompact
        ? 26.0
        : compact
        ? 28.0
        : 32.0;

    final double axisGap = ultraCompact
        ? 3.0
        : veryCompact
        ? 5.0
        : 6.0;

    final double availableChartHeight = math.max(
      90.0,
      innerHeight - titleHeight - titleBottomGap,
    );

    final double groupsSpace = (() {
      final double base = ultraCompact
          ? 4.0
          : veryCompact
          ? 5.0
          : compact
          ? 6.0
          : medium
          ? 7.0
          : 8.0;

      return base.clamp(_minGroupsSpace, _maxGroupsSpace).toDouble();
    })();

    final double dynamicBarWidth = (() {
      if (barsCount <= 0) {
        return baseBarWidth.clamp(_minBarWidth, _maxBarWidth).toDouble();
      }

      final double usableWidth =
      math.max(40.0, innerWidth - leftReservedSize);

      final double totalGap = math.max(0.0, (barsCount - 1) * groupsSpace);

      final double widthPerBarSlot =
      math.max(8.0, (usableWidth - totalGap) / barsCount);

      final double fillFactor = ultraCompact
          ? 0.72
          : veryCompact
          ? 0.76
          : compact
          ? 0.80
          : medium
          ? 0.84
          : 0.88;

      final double calculated = widthPerBarSlot * fillFactor;

      final double softenedBase = ultraCompact
          ? baseBarWidth * 0.65
          : veryCompact
          ? baseBarWidth * 0.78
          : compact
          ? baseBarWidth * 0.90
          : baseBarWidth;

      return math.max(softenedBase, calculated)
          .clamp(_minBarWidth, _maxBarWidth)
          .toDouble();
    })();

    final double titleWidth = (() {
      final double minFromBar = dynamicBarWidth * 1.10;
      final double preferred = math.max(baseTitleWidth * 0.55, minFromBar);

      final double maxAllowed = ultraCompact
          ? 72.0
          : veryCompact
          ? 82.0
          : compact
          ? 94.0
          : 110.0;

      return preferred.clamp(34.0, maxAllowed).toDouble();
    })();

    final double barRadius = ultraCompact
        ? 2.0
        : veryCompact
        ? 2.0
        : compact
        ? 3.0
        : 4.0;

    final double shimmerLabelHeight = ultraCompact
        ? 6.0
        : veryCompact
        ? 7.0
        : 8.0;

    return BarChartMetrics(
      cardPadding: cardPadding,
      innerWidth: innerWidth,
      innerHeight: innerHeight,
      titleHeight: titleHeight,
      titleFontSize: titleFontSize,
      titleBottomGap: titleBottomGap,
      chartHeight: availableChartHeight,
      barWidth: dynamicBarWidth,
      titleWidth: titleWidth,
      groupsSpace: groupsSpace,
      barRadius: barRadius,
      leftReservedSize: leftReservedSize,
      leftLabelFontSize: leftLabelFontSize,
      axisTickWidth: axisTickWidth,
      axisGap: axisGap,
      bottomReservedSize: bottomReservedSize,
      bottomLabelFontSize: bottomLabelFontSize,
      bottomLabelMaxLines: bottomLabelMaxLines,
      shimmerLabelHeight: shimmerLabelHeight,
    );
  }

  double computeChartWidth({
    required int count,
    required double availableInnerWidth,
    required double leftReservedSize,
  }) {
    final double slotWidth = math.max(barWidth, titleWidth);

    final double minWidthNeeded = count <= 0
        ? leftReservedSize
        : leftReservedSize + (count * slotWidth) + ((count - 1) * groupsSpace);

    return math.max(availableInnerWidth, minWidthNeeded);
  }
}