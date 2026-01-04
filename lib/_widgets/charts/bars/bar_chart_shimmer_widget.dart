import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BarChartShimmerWidget extends StatelessWidget {
  final int barsCount;
  final double barWidth;
  final double titleWidth;
  final double height;
  final double spacing;

  /// Largura final do chart (opcional). Se vier menor que o conteúdo,
  /// usamos a largura do conteúdo para não dar overflow.
  final double? chartWidth;

  final String? chartTitle;
  final List<String>? labels;

  final bool isDark;

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
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final base = isDark ? Colors.white24 : Colors.grey.shade300;
    final highlight = isDark ? Colors.white10 : Colors.grey.shade100;

    // ✅ gap mínimo garantido
    final double safeSpacing = max(12.0, spacing);

    // alturas falsas de barra (reprodutíveis)
    final rnd = Random(7);
    final fakeHeights = List<double>.generate(
      barsCount,
          (_) => (0.2 + rnd.nextDouble() * 0.75) * (height - 70),
    );

    // ====== LARGURA REAL DO CONTEÚDO (para não estourar no final) ======
    const double yAxisTickWidth = 34; // width das “marcas” do eixo Y
    const double yAxisGap = 8; // padding right do eixo Y
    final double yAxisArea = yAxisTickWidth + yAxisGap;

    final double itemWidth = max(barWidth, titleWidth);
    final double barsArea = (barsCount * itemWidth) +
        (barsCount > 0 ? (barsCount - 1) * safeSpacing : 0);

    final double contentWidth = yAxisArea + barsArea;

    // Se chartWidth vier menor que contentWidth, usamos contentWidth para evitar overflow.
    final double safeWidth = max(chartWidth ?? 0, contentWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chartTitle != null) ...[
          Center(
            child: Container(
              height: 18,
              width: 160,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: safeWidth,
            height: height,
            child: Stack(
              children: [
                // linhas do grid
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      5,
                          (_) => Container(height: 1, color: gridColor),
                    ),
                  ),
                ),
                // barras + rótulos
                Row(
                  children: [
                    // eixo Y simulado (marcas)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(right: yAxisGap),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                                (_) => Container(
                              height: 10,
                              width: yAxisTickWidth,
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(barsCount, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: i == barsCount - 1 ? 0 : safeSpacing,
                            ),
                            child: SizedBox(
                              width: itemWidth,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: fakeHeights[i],
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      color: base,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 8,
                                    width: titleWidth * .9,
                                    decoration: BoxDecoration(
                                      color: base,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 8,
                                    width: titleWidth * .7,
                                    decoration: BoxDecoration(
                                      color: base,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
