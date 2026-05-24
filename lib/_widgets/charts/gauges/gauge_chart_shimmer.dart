// lib/_widgets/charts/gauges/gauge_chart_shimmer.dart

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

  /// Quantidade de anéis simulados no shimmer.
  final int ringsCount;

  /// Mesmo multiplicador usado no GaugeChartChange.
  final double strokeScale;

  /// Raio já resolvido pelo GaugeChartMetrics.
  ///
  /// Quando informado, o shimmer usa exatamente o mesmo tamanho do gauge real.
  final double? resolvedRadius;

  /// Espessura já resolvida pelo GaugeChartChange.
  ///
  /// Quando informado, o shimmer usa exatamente a mesma espessura do gauge real.
  final double? resolvedLineWidth;

  const GaugeCircularPercentShimmer({
    super.key,
    required this.width,
    required this.height,
    this.customRadius,
    this.hasHeader = true,
    this.hasFooter = true,
    this.ringsCount = 1,
    this.strokeScale = 1.0,
    this.resolvedRadius,
    this.resolvedLineWidth,
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
      ringsCount: ringsCount,
      strokeScale: strokeScale,
      resolvedRadius: resolvedRadius,
      resolvedLineWidth: resolvedLineWidth,
    );

    final double circleSize = (metrics.radius * 2) + metrics.lineWidth + 6.0;

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
                    ringsCount: metrics.ringsCount,
                    ringGap: metrics.ringGap,
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