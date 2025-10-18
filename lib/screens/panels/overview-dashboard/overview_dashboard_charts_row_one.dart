import 'package:flutter/material.dart';
import 'package:siged/_blocs/panels/overview-dashboard/overview_dashboard_style.dart';
import 'package:siged/_blocs/process/contracts/contract_rules.dart';
import 'package:siged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';
import '../../../_blocs/process/contracts/contracts_controller.dart';
import '../../../../_widgets/charts/radar/radar_chart_changed_widget.dart';

class OverviewDashboardChartRowOne extends StatelessWidget {
  final ContractsController controller;

  const OverviewDashboardChartRowOne({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Larguras fixas dos dois primeiros gráficos
    const double kPieWidth = 360;
    const double kRadarWidth = 360;

    // Espaçamentos entre os cards (mantendo os mesmos que você usou)
    const double kLeadingPadding = 12; // antes do Pie
    const double kAfterPadding = 12; // antes do Pie
    const double kBetweenPieRadar = 8;
    const double kBetweenRadarBar = 8;
    const double kTrailingPadding = 0; // depois do Bar (pode ajustar se quiser)

    final labels = controller.radarServiceLabels;
    final datasets = controller.radarDatasetsServices(
      primary: OverviewDashboardStyle.kPrimary,
      warning: OverviewDashboardStyle.kWarning,
      success: OverviewDashboardStyle.kSuccess,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalFixed =
            kLeadingPadding + kPieWidth + kBetweenPieRadar + kRadarWidth + kBetweenRadarBar + kTrailingPadding + kAfterPadding;

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
            children: [
              const SizedBox(width: kLeadingPadding),
              // PIE (largura fixa)
              SizedBox(
                width: kPieWidth,
                child: PieChartChanged(
                  larguraGrafico: kPieWidth,
                  sliceRadius: 50,
                  useExternalLegend: true,
                  coresPersonalizadas: controller.labelsStatusGeneralContracts
                      .map(OverviewDashboardStyle.getColorByStatus)
                      .toList(),
                  showPercentageOutside: true,
                  labels: controller.labelsStatusGeneralContracts,
                  values: controller.valuesStatusGeneralContracts,
                  selectedLabel: controller.selectedStatus,
                  onTapLabel: controller.onStatusSelected,
                ),
              ),
              const SizedBox(width: kBetweenPieRadar),

              // RADAR (largura fixa)
              SizedBox(
                width: kRadarWidth,
                child: RadarChartChanged(
                  labels: labels,
                  datasets: datasets,
                  tickCount: 5,
                  minAtCenter: false,
                  larguraGrafico: kRadarWidth,
                  alturaCard: 290,
                ),
              ),
              const SizedBox(width: kBetweenRadarBar),

              // BAR (expande para ocupar o restante da largura)
              SizedBox(
                width: barWidth,
                child: BarChartChanged(
                  expandToMaxWidth: true,     // <<--- faz o widget ocupar a largura disponível
                  heightGraphic: 260,
                  labels: ContractRules.regions,
                  values: controller.valuesRegionOfMap,
                  selectedIndex: controller.selectedRegionIndex,
                  onBarTap: controller.onRegionSelected,
                ),
              ),
              if (kTrailingPadding > 0) const SizedBox(width: kTrailingPadding),
            ],
          ),
        );
      },
    );
  }
}
