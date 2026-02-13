// lib/screens/commons/timeline/timeline_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TimelineShimmer extends StatelessWidget {
  final double height;
  final int itemCount;

  const TimelineShimmer({
    super.key,
    this.height = 130,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseColor =
    theme.colorScheme.surfaceVariant.withValues(alpha: 0.4);
    final highlightColor =
    theme.colorScheme.surfaceVariant.withValues(alpha: 0.8);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(itemCount, (index) {
              return Row(
                children: [
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Column(
                      children: [
                        // bolinha (CircleAvatar fake)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // título
                        Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // data
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // texto extra (status / faltam / vencido)
                        Container(
                          height: 12,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < itemCount - 1)
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.white,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
