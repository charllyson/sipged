import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BarChartShimmerWidget extends StatelessWidget {
  final int barsCount;
  final double barWidth;
  final double titleWidth;
  final double height;
  final double spacing;
  final String? chartTitle;
  final List<String>? labels; // opcional: para medir largura do scroll igual ao real

  const BarChartShimmerWidget({
    super.key,
    required this.barsCount,
    this.barWidth = 60,
    this.titleWidth = 100,
    this.height = 260,
    this.spacing = 24,
    this.chartTitle,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // grid horizontal simulada
    final gridColor = Colors.grey.shade200;
    final bg = Colors.white;
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    // alturas falsas de barra (reprodutíveis)
    final rnd = Random(7);
    final fakeHeights = List<double>.generate(
      barsCount,
          (_) => (0.2 + rnd.nextDouble() * 0.75) * (height - 70), // 70 ~ área dos títulos
    );

    // largura total (igual ao cálculo do chart real)

    return Card(
      color: bg,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chartTitle != null) ...[
              Center(
                child: Container(
                  height: 18, width: 160,
                  decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // grid + barras
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: height,
                child: Stack(
                  children: [
                    // linhas do grid
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (_) => Container(
                          height: 1, color: gridColor,
                        )),
                      ),
                    ),
                    // barras + rótulos
                    Row(
                      children: [
                        // eixo Y simulado (marcas)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8), // <- aumente aqui, ex.: 16
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                5,
                                    (_) => Container(
                                  height: 10,
                                  width: 34,
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
                                padding: EdgeInsets.only(right: i == barsCount - 1 ? 0 : spacing),
                                child: SizedBox(
                                  width: max(barWidth, titleWidth),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // barra
                                      Container(
                                        height: fakeHeights[i],
                                        width: barWidth,
                                        decoration: BoxDecoration(
                                          color: base,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // duas linhas de texto do rótulo simuladas
                                      Container(height: 8, width: titleWidth * .9, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                                      const SizedBox(height: 4),
                                      Container(height: 8, width: titleWidth * .7, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
