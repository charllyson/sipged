import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';
import '../../../../_datas/documents/contracts/contracts/contract_rules.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_widgets/charts/barGraph/bar_chart_changed.dart';
import '../../../../_widgets/charts/pieGraph/pie_chart_changed.dart';
import 'dashboard_controller.dart';

class ChartsContractSection extends StatelessWidget {
  final DashboardController controller;

  const ChartsContractSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              PieChartChanged(
                larguraGrafico: 250,
                useExternalLegend: true,
                coresPersonalizadas: controller.labelsStatusOrdenados.map(ContractStyle.getColorByStatus).toList(),
                showPercentageOutside: true,
                labels: controller.labelsStatusOrdenados,
                values: controller.valuesStatusOrdenados,
                selectedLabel: controller.selectedStatus,
                onTapLabel: controller.onStatusSelected,
              ),
              const SizedBox(width: 8),
              BarChartChanged(
                heightGraphic: 260,
                widthTitleBar: 80,
                labels: ContractRules.regions,
                values: controller.valuesRegiao,
                selectedIndex: controller.selectedRegionIndex,
                onBarTap: controller.onRegionSelected,
              ),
              const SizedBox(width: 8),
              BarChartChanged(
                heightGraphic: 260,
                widthBar: 30,
                widthTitleBar: 100,
                labels: controller.uniqueCompanies,
                values: controller.valuesEmpresa,
                barColors: controller.barColorsEmpresa,
                selectedIndex: controller.selectedCompanyIndex,
                onBarTap: controller.onCompanySelected,
              )
            ],
          ),
        ),
      ],
    );
  }
}
