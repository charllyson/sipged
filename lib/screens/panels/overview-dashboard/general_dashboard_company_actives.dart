import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_chart_changed.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class GeneralDashboardCompanyActives extends StatelessWidget {
  final GeneralDashboardCubit cubit;

  const GeneralDashboardCompanyActives({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    const double kTreemapWidth = 420;

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 12,
      // Desktop/Tablet: barras flex + treemap fixo
      fixedWidths: const <double?>[
        null,
        kTreemapWidth,
      ],

      // Scroll no mobile apenas para barras (índice 0) quando tiver muitos itens
      enableScrollOnSmall: true,
      scrollNeededForIndex: (i) => i == 0 && cubit.labelsCompany.length > 7,
      minScrollWidthForIndex: (i, availableWidth) => i == 0
          ? math.max(cubit.labelsCompany.length * 80.0, availableWidth)
          : availableWidth,

      children: [
        // 0) Barras - Empresas
            (context, m, i) {
          if (m.isSmall) {
            final bool needScroll = cubit.labelsCompany.length > 7;
            return BarChartChanged(
              colorCard: Colors.white,
              heightGraphic: 285,
              labels: cubit.labelsCompany,
              values: cubit.valuesCompanyFull,
              filteredValues: cubit.valuesCompany,
              barColors: cubit.barColorsEmpresa,
              selectedIndex: cubit.state.selectedCompanyIndex,
              onBarTap: (companyLabel) => cubit.onCompanySelected(companyLabel),
              expandToMaxWidth: !needScroll,
              shimmerBarsCount: 18,
            );
          }

          return BarChartChanged(
            colorCard: Colors.white,
            heightGraphic: 285,
            labels: cubit.labelsCompany,
            values: cubit.valuesCompanyFull,
            filteredValues: cubit.valuesCompany,
            barColors: cubit.barColorsEmpresa,
            selectedIndex: cubit.state.selectedCompanyIndex,
            onBarTap: (companyLabel) => cubit.onCompanySelected(companyLabel),
            expandToMaxWidth: true,
            shimmerBarsCount: 18,
          );
        },

        // 1) Treemap - Rodovias
            (context, m, i) {
          return TreemapChartChanged(
            items: cubit.treemapRodovias,
            filteredValues: cubit.treemapRodoviasFilteredValues,
            onItemSelected: (label) => cubit.onRoadSelected(label),
          );
        },
      ],
    );
  }
}
