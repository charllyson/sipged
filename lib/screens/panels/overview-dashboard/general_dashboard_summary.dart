import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/cards/expandable/expandable_card.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_data.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_state.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

class GeneralDashboardSummary extends StatelessWidget {
  const GeneralDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GeneralDashboardCubit>();
    final GeneralDashboardState state = cubit.state;

    final cards = ProgressData.statusTypes.map((status) {
      final inicial = state.totaisStatusIniciais[status] ?? 0.0;
      final aditivo = state.totaisStatusAditivos[status] ?? 0.0;
      final apostila = state.totaisStatusApostilas[status] ?? 0.0;

      return ExpandableCard(
        subTitles: const [
          'Inicial',
          'Aditivo',
          'Apostila',
        ],
        title: ContractData.getTitleByStatus(status),
        icon: ContractData.iconStatus(status),
        colorIcon: ContractData.getColorByStatus(status),
        valoresIndividuais: [
          inicial,
          aditivo,
          apostila,
        ],
        loading: !state.initialized,
        formatAsCurrency: true,
        valueFormatter: SipGedFormatMoney.doubleToText,
      );
    }).toList();

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 8,
      verticalGap: 12,
      fixedWidths: List<double?>.filled(cards.length, null),
      enableScrollOnSmall: false,
      children: List.generate(cards.length, (index) {
        return (context, m, i) {
          return cards[i];
        };
      }),
    );
  }
}