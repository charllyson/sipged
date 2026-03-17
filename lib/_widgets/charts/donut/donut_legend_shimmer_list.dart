import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DonutLegendShimmerList extends StatelessWidget {
  final bool isDark;
  final int itemCount;
  final double height;
  final double itemWidth;
  final double spacing;

  const DonutLegendShimmerList({
    super.key,
    required this.isDark,
    this.itemCount = 8,
    this.height = 44,
    this.itemWidth = 190,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white10 : Colors.grey.shade100;

    Widget rowItem(int i) {
      final width = itemWidth + (i % 2) * 8.0;

      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          margin: EdgeInsets.only(bottom: i == itemCount - 1 ? 0 : spacing),
          padding: EdgeInsets.symmetric(
            horizontal: height * 0.24,
            vertical: height * 0.18,
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
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: (height * 0.20).clamp(8.0, 10.0)),
              Expanded(
                child: Container(
                  height: (height * 0.18).clamp(8.0, 10.0),
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              SizedBox(width: (height * 0.20).clamp(8.0, 10.0)),
              Container(
                width: 42,
                height: (height * 0.18).clamp(8.0, 10.0),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(itemCount, rowItem),
    );
  }
}