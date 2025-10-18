import 'package:flutter/material.dart';
import 'package:siged/_widgets/chip/build_value_card.dart';

class MeasurementResumedCards extends StatelessWidget {
  // agora aceita nulos
  final List<double?>? valores;

  const MeasurementResumedCards(this.valores, {super.key});

  @override
  Widget build(BuildContext context) {
    final v0 = (valores != null && valores!.isNotEmpty) ? valores![0] : null;
    final v1 = (valores != null && valores!.length > 1) ? valores![1] : null;
    final v2 = (valores != null && valores!.length > 2) ? valores![2] : null;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        BuildValueCard(title: 'Medições', value: v0, icon: Icons.bar_chart),
        BuildValueCard(title: 'Reajustes', value: v1, icon: Icons.trending_up),
        BuildValueCard(title: 'Revisões', value: v2, icon: Icons.change_circle),
      ],
    );
  }
}
