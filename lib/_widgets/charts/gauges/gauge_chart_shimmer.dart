import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:sipged/_widgets/charts/gauges/gauge_chart_painter.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_shimmer_metrics.dart';

class GaugeCircularPercentShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double? customRadius;

  final bool hasHeader;
  final bool hasFooter;

  const GaugeCircularPercentShimmer({
    super.key,
    required this.width,
    required this.height,
    this.customRadius,
    this.hasHeader = true,
    this.hasFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color base = Colors.grey.shade300;
    final Color highlight = Colors.grey.shade100;

    final metrics = GaugeChartShimmerMetrics.resolve(
      maxWidth: width,
      maxHeight: height,
      customRadius: customRadius,
      hasHeader: hasHeader,
      hasFooter: hasFooter,
    );

    final double circleSize = metrics.radius * 2 + metrics.lineWidth;

    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (metrics.showHeader)
              Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                child: Container(
                  height: metrics.headerHeight,
                  width: metrics.headerWidth,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            if (metrics.showHeader) SizedBox(height: metrics.headerSpacing),
            Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: SizedBox(
                width: circleSize,
                height: circleSize,
                child: CustomPaint(
                  painter: GaugeChartPainter(
                    trackColor: base,
                    strokeWidth: metrics.lineWidth,
                  ),
                ),
              ),
            ),
            if (metrics.showFooter) SizedBox(height: metrics.footerSpacing),
            if (metrics.showFooter)
              Shimmer.fromColors(
                baseColor: base,
                highlightColor: highlight,
                child: Container(
                  height: metrics.footerHeight,
                  width: metrics.footerWidth,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}