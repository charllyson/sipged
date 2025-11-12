import 'package:flutter/material.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';
import 'package:siged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:siged/_widgets/charts/treemap/treemap_chart_changed.dart';
import '../../../_blocs/_process/process_controller.dart';

class OverviewDashboardChartRowTwo extends StatelessWidget {
  final DemandsDashboardController controller;

  const OverviewDashboardChartRowTwo({super.key, required this.controller});

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
            colorCard: Colors.white,
            heightGraphic: 285,
            widthBar: 47,
            labels: controller.labelsCompany,
            values: controller.valuesCompany,
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
