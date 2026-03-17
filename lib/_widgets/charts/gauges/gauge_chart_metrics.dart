import 'dart:math' as math;
import 'package:flutter/material.dart';

class GaugeChartMetrics {
  final EdgeInsets cardPadding;

  final double radius;
  final double lineWidth;

  final double centerFontSize;
  final double footerFontSize;
  final double headerFontSize;

  final double headerSpacing;
  final double footerSpacing;

  final double innerTextBoxSize;
  final double centerHorizontalPadding;

  final double availableContentWidth;
  final double availableContentHeight;

  const GaugeChartMetrics({
    required this.cardPadding,
    required this.radius,
    required this.lineWidth,
    required this.centerFontSize,
    required this.footerFontSize,
    required this.headerFontSize,
    required this.headerSpacing,
    required this.footerSpacing,
    required this.innerTextBoxSize,
    required this.centerHorizontalPadding,
    required this.availableContentWidth,
    required this.availableContentHeight,
  });

  static GaugeChartMetrics resolve({
    required double maxWidth,
    required double maxHeight,
    double? customRadius,
    double? customCenterFontSize,
    double? customFooterFontSize,
    required String centerText,
    required String footerText,
    required String headerText,
  }) {
    final bool ultraCompact = maxWidth <= 210 || maxHeight <= 180;
    final bool veryCompact = maxWidth <= 250 || maxHeight <= 210;
    final bool compact = maxWidth <= 300 || maxHeight <= 250;

    final bool hasHeader = headerText.trim().isNotEmpty;
    final bool hasFooter = footerText.trim().isNotEmpty;

    // =========================================================
    // PADDING DINÂMICO E RESPONSIVO
    // =========================================================
    final double horizontalPadding = (maxWidth * 0.028).clamp(2.0, 14.0);

    double verticalPadding = (maxHeight * 0.055).clamp(4.0, 24.0);

    if (hasHeader) {
      verticalPadding += 1.5;
    }

    if (hasFooter) {
      verticalPadding += 2.0;
    }

    if (ultraCompact) {
      verticalPadding = math.min(verticalPadding, 10.0);
    } else if (veryCompact) {
      verticalPadding = math.min(verticalPadding, 14.0);
    }

    final EdgeInsets cardPadding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );

    final double innerWidth = math.max(100.0, maxWidth - cardPadding.horizontal);
    final double innerHeight = math.max(110.0, maxHeight - cardPadding.vertical);

    final double headerFontSize = (math.min(innerWidth, innerHeight) * 0.055)
        .clamp(9.5, 13.0);

    final double footerBaseFontSize = (math.min(innerWidth, innerHeight) * 0.050)
        .clamp(9.0, 12.5);

    final double resolvedFooterFontSize = customFooterFontSize != null
        ? customFooterFontSize.clamp(8.0, 18.0).toDouble()
        : footerBaseFontSize;

    final double headerSpacing = hasHeader
        ? (maxHeight * 0.012).clamp(2.0, 8.0)
        : 0.0;

    final double footerSpacing = hasFooter
        ? (maxHeight * 0.014).clamp(2.0, 10.0)
        : 0.0;

    final double reservedHeaderHeight = hasHeader
        ? headerFontSize * 1.15
        : 0.0;

    final double reservedFooterHeight = hasFooter
        ? resolvedFooterFontSize * 1.20
        : 0.0;

    final double circleAreaHeight = math.max(
      70.0,
      innerHeight -
          reservedHeaderHeight -
          reservedFooterHeight -
          headerSpacing -
          footerSpacing,
    );

    final double circleAreaWidth = innerWidth;

    final double rawDiameter = math.min(circleAreaWidth, circleAreaHeight);

    final double diameterScale = ultraCompact
        ? 0.92
        : veryCompact
        ? 0.94
        : compact
        ? 0.96
        : 0.975;

    final double resolvedDiameter =
    (rawDiameter * diameterScale).clamp(64.0, rawDiameter);

    final double autoRadius = resolvedDiameter / 2.0;

    final double resolvedRadius = customRadius != null
        ? math.min(customRadius, autoRadius)
        : autoRadius;

    final double lineWidth = (resolvedRadius *
        (ultraCompact
            ? 0.15
            : veryCompact
            ? 0.16
            : 0.17))
        .clamp(7.0, 20.0);

    final double innerDiameter = math.max(
      24.0,
      (resolvedRadius * 2) - (lineWidth * 2) - 4.0,
    );

    final double autoCenterFont = (innerDiameter *
        (ultraCompact
            ? 0.31
            : veryCompact
            ? 0.34
            : compact
            ? 0.37
            : 0.40))
        .clamp(9.0, 34.0);

    final double resolvedCenterFont = customCenterFontSize != null
        ? math.min(customCenterFontSize, autoCenterFont)
        : autoCenterFont;

    const double centerHorizontalPadding = 0.0;

    return GaugeChartMetrics(
      cardPadding: cardPadding,
      radius: resolvedRadius,
      lineWidth: lineWidth,
      centerFontSize: resolvedCenterFont,
      footerFontSize: resolvedFooterFontSize,
      headerFontSize: headerFontSize,
      headerSpacing: headerSpacing,
      footerSpacing: footerSpacing,
      innerTextBoxSize: innerDiameter,
      centerHorizontalPadding: centerHorizontalPadding,
      availableContentWidth: innerWidth,
      availableContentHeight: innerHeight,
    );
  }
}