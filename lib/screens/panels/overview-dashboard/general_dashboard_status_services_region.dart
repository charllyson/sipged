import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_style.dart';

import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/radar/radar_chart_changed.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class GeneralDashboardStatusServicesRegion extends StatelessWidget {
  final GeneralDashboardCubit cubit;

  const GeneralDashboardStatusServicesRegion({
    super.key,
    required this.cubit,
  });

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
      fixedWidths: const <double?>[
        kPieWidth,
        kRadarWidth,
        null,
      ],
      enableScrollOnSmall: true,
      scrollNeededForIndex: (index) {
        return index == 2 && cubit.labelsRegionOfMap.length > 7;
      },
      minScrollWidthForIndex: (index, availableWidth) {
        if (index == 2) {
          return math.max(
            cubit.labelsRegionOfMap.length * 80.0,
            availableWidth,
          );
        }

        return availableWidth;
      },
      children: [
            (context, metrics, index) {
          final double cardWidth = metrics.isSmall
              ? metrics.availableWidth
              : (metrics.currentItemWidth ?? kPieWidth);

          return DonutChartChanged(
            legendPosition: DonutLegendPosition.bottom,
            colorsSlices: cubit.labelsStatusGeneralContracts
                .map(GeneralDashboardStyle.getColorByStatus)
                .toList(),
            showPercentageOutside: true,
            labels: cubit.labelsStatusGeneralContracts,
            values: cubit.valuesStatusGeneralContractsFull,
            filteredValues: cubit.valuesStatusGeneralContractsFiltered,
            selectedLabel: cubit.state.selectedStatus,
            onTapLabel: (label) {
              cubit.onStatusSelected(label);
            },
            widthGraphic: cardWidth,
          );
        },
            (context, metrics, index) {
          return RadarChartChanged(
            labels: labels,
            datasets: datasets,
            tickCount: 5,
            minAtCenter: false,
            alturaCard: 290,
          );
        },
            (context, metrics, index) {
          final bool needScroll =
              metrics.isSmall && cubit.labelsRegionOfMap.length > 7;

          return BarChartChanged(
            labels: cubit.labelsRegionOfMap,
            values: cubit.valuesRegionOfMapFull,
            filteredValues: cubit.valuesRegionOfMapFiltered,
            barColors: cubit.barColorsRegion,
            selectedIndex: cubit.state.selectedRegionIndex,
            onBarSelectionChanged: (regionLabel) {
              if (regionLabel == null) {
                cubit.onRegionIndexSelected(null);
                return;
              }

              cubit.onRegionSelected(regionLabel);
            },
            expandToMaxWidth: metrics.isSmall ? !needScroll : true,
            shimmerBarsCount: 7,
          );
        },
      ],
    );
  }
}