import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ContractsTableShimmerWidget extends StatelessWidget {
  final BoxConstraints constraints;

  const ContractsTableShimmerWidget({super.key, required this.constraints});

  static const int _rowCount = 5; // número de linhas de simulação
  static const int _columnCount = 7; // VALIDADE, CONTRATO, OBRA, REGIÃO, EMPRESA, Nº PROCESSO

  @override
  Widget build(BuildContext context) {
    final List<double> columnWidths = [200, 235, 310, 220, 200, 300, 250];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_rowCount, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: List.generate(_columnCount, (colIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: columnWidths[colIndex],
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
