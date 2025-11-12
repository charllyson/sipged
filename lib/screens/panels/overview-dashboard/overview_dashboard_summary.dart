import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_widgets/summary/summary_expandable_card.dart';
import 'package:siged/_blocs/process/hiring/5Edital/company_data.dart';
import '../../../_blocs/_process/process_controller.dart';

class OverviewDashboardSummary extends StatelessWidget {
  const OverviewDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DemandsDashboardController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // ✅ rolagem horizontal evita esmagar cards em iPad 12,9"
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DfdData.statusTypes.map((status) {
            final inicial  = controller.totaisStatusIniciais[status] ?? 0.0;
            final aditivo  = controller.totaisStatusAditivos[status] ?? 0.0;
            final apostila = controller.totaisStatusApostilas[status] ?? 0.0;
            return SummaryExpandableCard(
              subTitles: const ['Inicial','Aditivo','Apostila'],
              title: DfdData.getTitleByStatus(status),
              icon: DemandsDashboardOverviewStyle.iconStatus(status),
              colorIcon: DemandsDashboardOverviewStyle.getColorByStatus(status),
              valoresIndividuais: [inicial, aditivo, apostila],
              loading: !controller.initialized,
            );
          }).toList(),
        ),
      ),
    );
  }
}
