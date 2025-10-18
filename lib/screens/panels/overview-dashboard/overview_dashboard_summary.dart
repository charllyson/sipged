import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/panels/overview-dashboard/overview_dashboard_style.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import 'package:siged/_blocs/process/contracts/contract_rules.dart';
import '../../../_blocs/process/contracts/contracts_controller.dart';

class OverviewDashboardSummary extends StatelessWidget {
  const OverviewDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContractsController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // ✅ rolagem horizontal evita esmagar cards em iPad 12,9"
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ContractRules.statusTypes.map((status) {
            final inicial  = controller.totaisStatusIniciais[status] ?? 0.0;
            final aditivo  = controller.totaisStatusAditivos[status] ?? 0.0;
            final apostila = controller.totaisStatusApostilas[status] ?? 0.0;
            return SummaryExpandableCard(
              subTitles: const ['Inicial','Aditivo','Apostila'],
              title: ContractRules.getTitleByStatus(status),
              icon: OverviewDashboardStyle.iconStatus(status),
              colorIcon: OverviewDashboardStyle.getColorByStatus(status),
              valoresIndividuais: [inicial, aditivo, apostila],
              loading: !controller.initialized,
            );
          }).toList(),
        ),
      ),
    );
  }
}
