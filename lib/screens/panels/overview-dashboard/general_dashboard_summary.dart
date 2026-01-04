import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_state.dart';
import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_style.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/cards/summary/expandable_card.dart';
import 'package:siged/_widgets/layout/responsive_section/responsive_section_row.dart';

class GeneralDashboardSummary extends StatelessWidget {
  const GeneralDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GeneralDashboardCubit>();
    final GeneralDashboardState state = cubit.state;

    final cards = HiringData.statusTypes.map((status) {
      final inicial = state.totaisStatusIniciais[status] ?? 0.0;
      final aditivo = state.totaisStatusAditivos[status] ?? 0.0;
      final apostila = state.totaisStatusApostilas[status] ?? 0.0;

      return ExpandableCard(
        subTitles: const ['Inicial', 'Aditivo', 'Apostila'],
        title: HiringData.getTitleByStatus(status),
        icon: GeneralDashboardStyle.iconStatus(status),
        colorIcon: GeneralDashboardStyle.getColorByStatus(status),
        valoresIndividuais: [inicial, aditivo, apostila],
        loading: !state.initialized,
      );
    }).toList();

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 8,
      verticalGap: 12,

      // Todos flex no desktop (dividem o espaço igualmente)
      fixedWidths: List<double?>.filled(cards.length, null),

      // Summary cards NÃO precisam de scroll no mobile
      enableScrollOnSmall: false,

      children: List.generate(cards.length, (index) {
        return (context, m, i) {
          // Mobile: largura total
          if (m.isSmall) {
            return cards[i];
          }

          // Desktop/Tablet: ocupa a largura calculada
          return cards[i];
        };
      }),
    );
  }
}
