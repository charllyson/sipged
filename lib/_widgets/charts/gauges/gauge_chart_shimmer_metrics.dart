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
  });

  static GaugeChartShimmerMetrics resolve({
    required double maxWidth,
    required double maxHeight,
    double? customRadius,
  }) {
    final bool ultraCompact = maxWidth <= 210 || maxHeight <= 180;
    final bool veryCompact = maxWidth <= 250 || maxHeight <= 210;
    final bool compact = maxWidth <= 300 || maxHeight <= 250;

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

    final double reservedHeader = headerHeight * 2 + headerSpacing;
    final double reservedFooter = footerHeight * 2 + footerSpacing;

    final double safeWidth = math.max(100.0, maxWidth);
    final double safeHeight = math.max(110.0, maxHeight);

    final double rawDiameter = math.min(
      safeWidth * 0.82,
      safeHeight - reservedHeader - reservedFooter,
    ).clamp(64.0, 180.0);

    final double autoRadius = rawDiameter / 2.0;
    final double resolvedRadius = customRadius != null
        ? math.min(customRadius, autoRadius)
        : autoRadius;

    final double lineWidth = (resolvedRadius *
        (ultraCompact
            ? 0.16
            : veryCompact
            ? 0.17
            : 0.18))
        .clamp(7.0, 20.0);

    return GaugeChartShimmerMetrics(
      radius: resolvedRadius,
      lineWidth: lineWidth,
      headerHeight: headerHeight,
      footerHeight: footerHeight,
      headerWidth: (safeWidth * 0.42).clamp(70.0, 140.0),
      footerWidth: (safeWidth * 0.36).clamp(60.0, 120.0),
      headerSpacing: headerSpacing,
      footerSpacing: footerSpacing,
      showHeader: true,
      showFooter: true,
    );
  }
}