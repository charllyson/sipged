import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_style.dart';

import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/pies/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/radar/radar_chart_changed.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class GeneralDashboardStatusServicesRegion extends StatelessWidget {
  final GeneralDashboardCubit cubit;

  const GeneralDashboardStatusServicesRegion({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    const double kPieWidth = 360;
    const double kRadarWidth = 360;

    final labels = cubit.radarServiceLabels;
    final datasets = cubit.radarDatasetsServices(
      primary: GeneralDashboardStyle.kPrimary,
      warning: GeneralDashboardStyle.kWarning,
      success: GeneralDashboardStyle.kSuccess,
    );

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 12,

      // Desktop/Tablet: 3 na mesma linha (3º flex)
      fixedWidths: const <double?>[
        kPieWidth,
        kRadarWidth,
        null,
      ],

      // Scroll no mobile apenas para as barras (índice 2) se houver muitas labels
      enableScrollOnSmall: true,
      scrollNeededForIndex: (i) => i == 2 && cubit.labelsRegionOfMap.length > 7,
      minScrollWidthForIndex: (i, availableWidth) => i == 2
          ? math.max(cubit.labelsRegionOfMap.length * 80.0, availableWidth)
          : availableWidth,

      children: [
        // 0) Pizza status contratos
            (context, m, i) {
          final double cardW =
          m.isSmall ? m.availableWidth : (m.currentItemWidth ?? kPieWidth);

          return DonutChartChanged(
            legendPosition: DonutLegendPosition.bottom,
            sliceRadius: 50,
            coresPersonalizadas: cubit.labelsStatusGeneralContracts
                .map(GeneralDashboardStyle.getColorByStatus)
                .toList(),
            showPercentageOutside: true,
            labels: cubit.labelsStatusGeneralContracts,
            values: cubit.valuesStatusGeneralContractsFull,
            filteredValues: cubit.valuesStatusGeneralContractsFiltered,
            selectedLabel: cubit.state.selectedStatus,
            onTapLabel: (label) => cubit.onStatusSelected(label),
            larguraCard: cardW,
            larguraGrafico: math.min(cardW * 0.75, 260),
          );
        },

        // 1) Radar serviços
            (context, m, i) {
          return RadarChartChanged(
            labels: labels,
            datasets: datasets,
            tickCount: 5,
            minAtCenter: false,
            alturaCard: 290,
          );
        },

        // 2) Barras regiões (map link)
            (context, m, i) {
          if (m.isSmall) {
            final bool needScroll = cubit.labelsRegionOfMap.length > 7;
            return BarChartChanged(
              heightGraphic: 260,
              labels: cubit.labelsRegionOfMap,
              values: cubit.valuesRegionOfMapFull,
              filteredValues: cubit.valuesRegionOfMapFiltered,
              barColors: cubit.barColorsRegion,
              selectedIndex: cubit.state.selectedRegionIndex,
              onBarTap: (region) => cubit.onRegionSelected(region),
              expandToMaxWidth: !needScroll,
              shimmerBarsCount: 7,
            );
          }

          return BarChartChanged(
            heightGraphic: 260,
            labels: cubit.labelsRegionOfMap,
            values: cubit.valuesRegionOfMapFull,
            filteredValues: cubit.valuesRegionOfMapFiltered,
            barColors: cubit.barColorsRegion,
            selectedIndex: cubit.state.selectedRegionIndex,
            onBarTap: (region) => cubit.onRegionSelected(region),
            expandToMaxWidth: true,
            shimmerBarsCount: 7,
          );
        },
      ],
    );
  }
}
