import 'package:flutter/material.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

class AccidentsSummarySection extends StatelessWidget {
  /// Mapa vindo do Bloc/Repository, com chaves **canônicas** (ex.: 'COLISÃO FRONTAL').
  final Map<String, double> totalsByType;

  /// Se true, não renderiza cartões cujo total seja 0.
  final bool hideZero;

  const AccidentsSummarySection({
    super.key,
    required this.totalsByType,
    this.hideZero = false,
  });

  @override
  Widget build(BuildContext context) {
    // Mantém a ordem fixa definida pelo domínio (accidentTypes) e busca no mapa.
    final items = AccidentsData.accidentTypes.where((canonical) {
      if (!hideZero) return true;
      final total = totalsByType[canonical] ?? 0.0;
      return total > 0;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((canonical) {
          final total = totalsByType[canonical] ?? 0.0;
          return SummaryExpandableCard(
            subTitles: const ['Total'],
            title: AccidentsData.displayTitle(canonical),          // título bonito
            icon: AccidentsData.iconFor(canonical),                // ícone por tipo
            colorIcon: AccidentsData.getColorByAccidentType(canonical),
            valorTotal: Future.value(total),                       // seu card espera Future
            formatAsCurrency: false,
          );
        }).toList(),
      ),
    );
  }
}
