// lib/_widgets/charts/gauges/gauge_chart_shimmer_metrics.dart

import 'dart:math' as math;

class GaugeChartShimmerMetrics {
  final double radius;
  final double lineWidth;

  final double headerHeight;
  final double footerHeight;

  final double headerWidth;
  final double footerWidth;

  final double headerSpacing;
  final double footerSpacing;

  final bool showHeader;
  final bool showFooter;

  final int ringsCount;
  final double ringGap;

  const GaugeChartShimmerMetrics({
    required this.radius,
    required this.lineWidth,
    required this.headerHeight,
    required this.footerHeight,
    required this.headerWidth,
    required this.footerWidth,
    required this.headerSpacing,
    required this.footerSpacing,
    required this.showHeader,
    required this.showFooter,
    required this.ringsCount,
    required this.ringGap,
  });

  static GaugeChartShimmerMetrics resolve({
    required double maxWidth,
    required double maxHeight,
    double? customRadius,
    bool hasHeader = true,
    bool hasFooter = true,
    int ringsCount = 1,
    double strokeScale = 1.0,

    /// Valores vindos diretamente do GaugeChartMetrics/GaugeChartChange.
    ///
    /// Quando informados, têm prioridade sobre o cálculo automático.
    double? resolvedRadius,
    double? resolvedLineWidth,
  }) {
    final int safeRingsCount = ringsCount.clamp(1, 6);

    final bool ultraCompact = maxWidth <= 210 || maxHeight <= 180;
    final bool veryCompact = maxWidth <= 250 || maxHeight <= 210;

    final double headerHeight = ultraCompact
        ? 10.0
        : veryCompact
        ? 11.0
        : 12.0;

    final double footerHeight = ultraCompact
        ? 10.0
        : veryCompact
        ? 11.0
        : 12.0;

    final double headerSpacing = ultraCompact
        ? 4.0
        : veryCompact
        ? 5.0
        : 6.0;

    final double footerSpacing = ultraCompact
        ? 4.0
        : veryCompact
        ? 5.0
        : 6.0;

    final double reservedHeader =
    hasHeader ? headerHeight + headerSpacing : 0.0;

    final double reservedFooter =
    hasFooter ? footerHeight + footerSpacing : 0.0;

    final double safeWidth = math.max(100.0, maxWidth);
    final double safeHeight = math.max(110.0, maxHeight);

    final double rawDiameter = math
        .min(
      safeWidth * 0.82,
      safeHeight - reservedHeader - reservedFooter,
    )
        .clamp(64.0, 180.0);

    final double autoRadius = rawDiameter / 2.0;

    final double radiusByAuto = customRadius != null
        ? math.min(customRadius, autoRadius)
        : autoRadius;

    final double radius = resolvedRadius != null && resolvedRadius.isFinite
        ? resolvedRadius
        : radiusByAuto;

    final double baseLineWidth = (radius *
        (ultraCompact
            ? 0.16
            : veryCompact
            ? 0.17
            : 0.18))
        .clamp(7.0, 20.0);

    final double lineWidthByAuto = (baseLineWidth * strokeScale).clamp(
      7.0,
      28.0,
    );

    final double lineWidth =
    resolvedLineWidth != null && resolvedLineWidth.isFinite
        ? resolvedLineWidth
        : lineWidthByAuto;

    final double ringGap = safeRingsCount <= 2 ? 7.0 : 5.0;

    return GaugeChartShimmerMetrics(
      radius: radius,
      lineWidth: lineWidth,
      headerHeight: headerHeight,
      footerHeight: footerHeight,
      headerWidth: (safeWidth * 0.42).clamp(70.0, 140.0),
      footerWidth: (safeWidth * 0.36).clamp(60.0, 120.0),
      headerSpacing: headerSpacing,
      footerSpacing: footerSpacing,
      showHeader: hasHeader,
      showFooter: hasFooter,
      ringsCount: safeRingsCount,
      ringGap: ringGap,
    );
  }
}