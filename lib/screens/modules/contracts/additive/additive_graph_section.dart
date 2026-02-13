import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class AdditiveGraphSection extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final void Function(int index)? onSelectIndex;

  const AdditiveGraphSection({
    super.key,
    required this.labels,
    required this.values,
    this.selectedIndex,
    this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final List<double?> valuesNullable = values.map<double?>((v) => v).toList();

    final bool hasSelection = selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < values.length;

    final List<double>? filteredPieValues = hasSelection
        ? List<double>.generate(
      values.length,
          (i) => i == selectedIndex ? values[i] : 0.0,
    )
        : null;

    final List<double?>? filteredBarValues = hasSelection
        ? List<double?>.generate(
      values.length,
          (i) => i == selectedIndex ? valuesNullable[i] : 0.0,
    )
        : null;

    Widget pieChart({required double cardWidth}) {
      return PieChartChanged(
        labels: labels,
        values: values,
        filteredValues: filteredPieValues,
        selectedIndex: hasSelection ? selectedIndex : null,
        larguraCard: cardWidth,
        larguraGrafico: math.min(cardWidth * 0.6, 260),
        onTouch: (index) {
          if (onSelectIndex == null) return;
          onSelectIndex!.call(index ?? -1);
        },
      );
    }

    Widget barChart({required bool expand}) {
      return BarChartChanged(
        shimmerBarsCount: 4,
        heightGraphic: 260,
        labels: labels,
        values: valuesNullable,
        filteredValues: filteredBarValues,
        selectedIndex: hasSelection ? selectedIndex : null,
        expandToMaxWidth: expand,
        onBarTap: (label) {
          if (onSelectIndex == null) return;
          final index = labels.indexOf(label);
          onSelectIndex!.call(index >= 0 ? index : -1);
        },
      );
    }

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 12,

      // Desktop/Tablet: mantém intenção do layout antigo (pie fixo / barras flex)
      fixedWidths: const [340, null],

      // Scroll no mobile somente para as barras (índice 1)
      enableScrollOnSmall: true,
      scrollNeededForIndex: (i) => i == 1 && labels.length > 6,
      minScrollWidthForIndex: (i, availableWidth) =>
      i == 1 ? math.max(labels.length * 80.0, availableWidth) : availableWidth,

      children: [
        // index 0: Pie
            (context, m, i) {
          final double cardW =
          m.isSmall ? m.availableWidth : (m.currentItemWidth ?? 340);
          return pieChart(cardWidth: cardW);
        },

        // index 1: Bars
            (context, m, i) {
          if (m.isSmall) {
            final bool needScroll = labels.length > 6;
            return barChart(expand: !needScroll);
          }
          return barChart(expand: true);
        },
      ],
    );
  }
}
