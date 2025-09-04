import 'package:flutter/material.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import '../../../../_blocs/sectors/transit/accidents/accidents_data.dart';

class AccidentsSummarySection extends StatelessWidget {
  final Map<String, double> totalsByType;   // <- vem pronto do controller

  const AccidentsSummarySection({
    super.key,
    required this.totalsByType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: AccidentsData.accidentTypes.map((status) {
          final total = totalsByType[status] ?? 0.0;
          return SummaryExpandableCard(
            title: AccidentsData.getTitleByAccidentType(status),
            icon: AccidentsData.iconAccidentType(status),
            colorIcon: AccidentsData.getColorByAccidentType(status),
            valorTotal: Future.value(total), // 🔹 temos número síncrono
            formatAsCurrency: false,
          );
        }).toList(),
      ),
    );
  }
}
