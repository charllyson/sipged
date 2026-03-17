import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BarChartShimmerWidget extends StatelessWidget {
  final int barsCount;
  final double barWidth;
  final double titleWidth;
  final double height;
  final double spacing;
  final double? chartWidth;

  final String? chartTitle;
  final List<String>? labels;
  final bool isDark;

  final double titleHeight;
  final double titleBottomGap;
  final double leftReservedSize;
  final double axisTickWidth;
  final double axisGap;
  final double labelHeight;
  final double barRadius;
  final double titleFontSize;

  const BarChartShimmerWidget({
    super.key,
    required this.barsCount,
    required this.isDark,
    this.barWidth = 60,
    this.titleWidth = 100,
    this.height = 260,
    this.spacing = 24,
    this.chartWidth,
    this.chartTitle,
    this.labels,
    this.titleHeight = 22,
    this.titleBottomGap = 10,
    this.leftReservedSize = 70,
    this.axisTickWidth = 34,
    this.axisGap = 8,
    this.labelHeight = 8,
    this.barRadius = 2,
    this.titleFontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final base = isDark ? Colors.white24 : Colors.grey.shade300;
    final highlight = isDark ? Colors.white10 : Colors.grey.shade100;

    final double safeSpacing = max(4.0, spacing);
    final rnd = Random(7);

    final fakeHeights = List<double>.generate(
      barsCount,
          (_) => (0.22 + rnd.nextDouble() * 0.73) * max(60.0, height - 70.0),
    );

    final double itemWidth = max(barWidth, titleWidth);
    final double barsArea = (barsCount * itemWidth) +
        (barsCount > 0 ? (barsCount - 1) * safeSpacing : 0);

    final double contentWidth = leftReservedSize + barsArea;
    final double safeWidth = max(chartWidth ?? 0, contentWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chartTitle != null) ...[
          SizedBox(
            height: titleHeight,
            child: Center(
              child: Container(
                height: max(14.0, titleFontSize),
                width: min(180.0, safeWidth * 0.34),
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: titleBottomGap),
        ],
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: safeWidth,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                            (_) => Container(height: 1, color: gridColor),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftReservedSize,
                        child: Padding(
                          padding: EdgeInsets.only(right: axisGap),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(
                              5,
                                  (_) => Container(
                                height: 10,
                                width: axisTickWidth,
                                decoration: BoxDecoration(
                                  color: base,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: base,
                          highlightColor: highlight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(barsCount, (i) {
                              return SizedBox(
                                width: itemWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: fakeHeights[i],
                                      width: barWidth,
                                      decoration: BoxDecoration(
                                        color: base,
                                        borderRadius:
                                        BorderRadius.circular(barRadius),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: labelHeight,
                                      width: titleWidth * .9,
                                      decoration: BoxDecoration(
                                        color: base,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: labelHeight,
                                      width: titleWidth * .7,
                                      decoration: BoxDecoration(
                                        color: base,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}