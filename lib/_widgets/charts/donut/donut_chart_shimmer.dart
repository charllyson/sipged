import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DonutChartShimmer extends StatelessWidget {
  final double largura;
  final double altura;
  final bool isDark;

  final double outerScale;
  final double holeScale;

  const DonutChartShimmer({
    super.key,
    required this.isDark,
    this.largura = 260,
    this.altura = 260,
    this.outerScale = 0.72,
    this.holeScale = 0.32,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white10 : Colors.grey.shade100;
    final centerBg = isDark ? const Color(0xFF11131E) : Colors.white;

    final base = largura < altura ? largura : altura;
    final outer = (base * outerScale).clamp(64.0, base);
    final hole = (base * holeScale).clamp(26.0, outer - 18.0);

    return SizedBox(
      width: largura,
      height: altura,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Shimmer.fromColors(
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
            Container(
              width: hole,
              height: hole,
              decoration: BoxDecoration(
                color: centerBg,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}