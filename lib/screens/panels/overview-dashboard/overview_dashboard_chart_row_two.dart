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
    const double kPieWidth = 360;
    const double kRadarWidth = 360;

    // Espaçamentos entre os cards (mantendo os mesmos que você usou)
    const double kLeadingPadding = 12; // antes do Pie
    const double kAfterPadding = 12; // antes do Pie
    const double kBetweenPieRadar = 8;
    const double kBetweenRadarBar = 8;
    const double kTrailingPadding = 0; // depois do Bar (pode ajustar se quiser)

    return LayoutBuilder(
        builder: (context, constraints) {
          final totalFixed = kLeadingPadding + kPieWidth + kBetweenPieRadar + kRadarWidth + kBetweenRadarBar + kTrailingPadding + kAfterPadding;

          // Mínimo de largura para o bar quando a tela é bem estreita
          const double kBarMinWidth = 600;

          // Se houver espaço sobrando, o Bar ocupa esse espaço.
          // Se a tela for pequena, garantimos ao menos kBarMinWidth e o SingleChildScrollView permitirá scroll.
          final double barWidth = (constraints.maxWidth > totalFixed)
              ? (constraints.maxWidth - totalFixed)
              : kBarMinWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),

              // ------- Barras por Empresa -------
              SizedBox(
                width: barWidth,
                child: BarChartChanged(
                  colorCard: Colors.white,
                  heightGraphic: 285,
                  widthBar: 47,
                  expandToMaxWidth: true,     // <<--- faz o widget ocupar a largura disponível
                  labels: controller.labelsCompany,
                  values: controller.valuesCompany,
                  barColors: controller.barColorsEmpresa,
                  selectedIndex: controller.selectedCompanyIndex,
                  onBarTap: controller.onCompanySelected,
                ),
              ),
              const SizedBox(width: 12),
              // No Row:
              TreemapChartChanged(items: controller.treemapRodovias),


              const SizedBox(width: 12),
            ],
          ),
        );
      }
    );
  }
}
