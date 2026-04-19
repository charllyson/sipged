// lib/_widgets/charts/neuralbar/horizontal_bar_chart_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HorizontalBarChartShimmer extends StatelessWidget {
  /// Altura fixa do gráfico (mesma usada no widget real)
  final double height;

  /// Quantidade de linhas "falsas" no shimmer
  final int skeletonRows;

  const HorizontalBarChartShimmer({
    super.key,
    required this.height,
    this.skeletonRows = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseColor =
    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final highlightColor =
    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(skeletonRows, (index) {
            return Row(
              children: [
                // "label" da linha
                Container(
                  width: 140,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // "barra" da linha
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
