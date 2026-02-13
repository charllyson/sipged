import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PieChartShimmerWidget extends StatelessWidget {
  final double largura;
  final double altura;

  /// Tema atual
  final bool isDark;

  const PieChartShimmerWidget({
    super.key,
    required this.isDark,
    this.largura = 260,
    this.altura = 260,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final centerBg = isDark ? const Color(0xFF11131E) : Colors.white;

    final double outer = (largura * 0.60).clamp(120.0, largura);
    final double hole = (largura * 0.30).clamp(60.0, outer);

    return SizedBox(
      width: largura,
      height: altura,
      child: Center(
        child: Stack(
          children: [
            Center(
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: outer,
                  height: outer,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Furo central
            Center(
              child: Container(
                width: hole,
                height: hole,
                decoration: BoxDecoration(
                  color: centerBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer da legenda (chips) para ficar no MESMO local/altura da legenda real.
class PieChartLegendShimmerWidget extends StatelessWidget {
  final bool isDark;
  final int itemCount;
  final double height;
  final double itemMinWidth;
  final double spacing;

  const PieChartLegendShimmerWidget({
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
          margin: EdgeInsets.only(right: spacing, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: baseColor.withValues(alpha:isDark ? 0.25 : 1.0),
            border: Border.all(color: baseColor.withValues(alpha:0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: double.infinity,
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
        // pequena variação para parecer mais “natural”
        final w = itemMinWidth + (i % 3) * 18.0;
        return chip(width: w);
      }),
    );
  }
}
