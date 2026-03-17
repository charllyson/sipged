import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DonutLegendShimmer extends StatelessWidget {
  final bool isDark;
  final int itemCount;
  final double height;
  final double itemMinWidth;
  final double spacing;

  const DonutLegendShimmer({
    super.key,
    required this.isDark,
    this.itemCount = 5,
    this.height = 44,
    this.itemMinWidth = 130,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white10 : Colors.grey.shade100;

    Widget chip({required double width}) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          margin: EdgeInsets.only(right: spacing),
          padding: EdgeInsets.symmetric(
            horizontal: height * 0.20,
            vertical: height * 0.14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: baseColor.withValues(alpha: isDark ? 0.25 : 1.0),
            border: Border.all(color: baseColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: (height * 0.22).clamp(8.0, 11.0),
                height: (height * 0.22).clamp(8.0, 11.0),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(width: (height * 0.16).clamp(6.0, 9.0)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: (height * 0.16).clamp(8.0, 10.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: (height * 0.12).clamp(3.0, 6.0)),
                    Container(
                      height: (height * 0.16).clamp(8.0, 10.0),
                      width: width * 0.55,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: List.generate(itemCount, (i) {
        final width = itemMinWidth + (i % 3) * 16.0;
        return chip(width: width);
      }),
    );
  }
}