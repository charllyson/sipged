import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PieChartShimmerWidget extends StatelessWidget {
  final double largura;
  final double altura;

  const PieChartShimmerWidget({
    super.key,
    this.largura = 250,
    this.altura = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: SizedBox(
        width: 280,
        height: 250,
        child: Center(
          child: Stack(
            children: [
              Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Furo central
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
