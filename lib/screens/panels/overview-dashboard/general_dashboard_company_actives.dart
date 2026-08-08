import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_chart_changed.dart';

class GeneralDashboardCompanyActives extends StatelessWidget {
  final GeneralDashboardCubit cubit;

  const GeneralDashboardCompanyActives({
    super.key,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    const double kTreemapWidth = 420;

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 12,
      fixedWidths: const <double?>[
        null,
        kTreemapWidth,
      ],
      enableScrollOnSmall: true,
      scrollNeededForIndex: (index) {
        return index == 0 && cubit.labelsCompany.length > 7;
      },
      minScrollWidthForIndex: (index, availableWidth) {
        if (index == 0) {
          return math.max(
            cubit.labelsCompany.length * 80.0,
            availableWidth,
          );
        }

        return availableWidth;
      },
      children: [
            (context, metrics, index) {
          final bool needScroll =
              metrics.isSmall && cubit.labelsCompany.length > 7;

          return BarChartChanged(
            colorCard: Colors.white,
            labels: cubit.labelsCompany,
            values: cubit.valuesCompanyFull,
            filteredValues: cubit.valuesCompany,
            barColors: cubit.barColorsEmpresa,
            selectedIndex: cubit.state.selectedCompanyIndex,
            onBarSelectionChanged: (companyLabel) {
              if (companyLabel == null) {
                cubit.onCompanyIndexSelected(null);
                return;
              }

              cubit.onCompanySelected(companyLabel);
            },
            expandToMaxWidth: metrics.isSmall ? !needScroll : true,
            shimmerBarsCount: 18,
          );
        },
            (context, metrics, index) {
          return TreemapChartChanged(
            items: cubit.treemapRodovias,
            filteredValues: cubit.treemapRodoviasFilteredValues,
            onItemSelected: (label) {
              cubit.onRoadSelected(label);
            },
          );
        },
      ],
    );
  }
}