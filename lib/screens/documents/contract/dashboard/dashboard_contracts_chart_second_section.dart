import 'package:flutter/material.dart';
import 'package:sisged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sisged/_widgets/charts/treemap/treemap_chart_changed.dart';
import '../../../../_blocs/documents/contracts/contracts/contracts_controller.dart';

class DashboardContractsChartSecondSection extends StatelessWidget {
  final ContractsController controller;

  const DashboardContractsChartSecondSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 12),

          // ------- Barras por Empresa -------
          BarChartChanged(
            heightGraphic: 285,
            widthBar: 47,
            labels: controller.labelsEmpresa,
            values: controller.valuesEmpresa,
            barColors: controller.barColorsEmpresa,
            selectedIndex: controller.selectedCompanyIndex,
            onBarTap: controller.onCompanySelected,
          ),
          const SizedBox(width: 12),
          // No Row:
          TreemapChartChanged(items: controller.treemapRodovias),


          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
