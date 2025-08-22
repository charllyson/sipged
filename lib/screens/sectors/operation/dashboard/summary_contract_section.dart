import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';
import 'package:sisged/screens/sectors/operation/dashboard/summary_expandable_card.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_rules.dart';
import 'dashboard_controller.dart';

class SummaryContractSection extends StatelessWidget {
  const SummaryContractSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ContractRules.statusTypes.map((status) {
          final inicial  = controller.totaisStatusIniciais[status] ?? 0.0;
          final aditivo  = controller.totaisStatusAditivos[status] ?? 0.0;
          final apostila = controller.totaisStatusApostilas[status] ?? 0.0;
          return SummaryExpandableCard(
            title: ContractRules.getTitleByStatus(status),
            icon: ContractStyle.iconStatus(status),
            colorIcon: ContractStyle.getColorByStatus(status),
            valoresIndividuais: [inicial, aditivo, apostila],
            loading: !controller.initialized, // ou controller.isCalculating
          );
        }).toList(),
      ),
    );
  }
}
