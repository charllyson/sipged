import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_change.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';

class ActiveRailwaysPanel extends StatelessWidget {
  const ActiveRailwaysPanel({super.key, this.onClose});
  final VoidCallback? onClose;

  String _fmtKm(double v) => '${v.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    const double kGaugeBoxWidth = 260;
    const double kPieBoxWidth = 280;
    const double kBarWidth = 50.0;
    const double kBarGap = 16.0;

    return Stack(
      children: [
        BackgroundChange(),
        Column(
          children: [
            Expanded(
              child:
              BlocBuilder<ActiveRailwaysCubit, ActiveRailwaysState>(
                builder: (context, st) {
                  final cubit = context.read<ActiveRailwaysCubit>();

                  // ---- Gauge derivado do Pie (calculado aqui) ----
                  final values = st.pieValuesForChart;
                  final labels = st.pieLabelsForChart;
                  final total = values.fold<double>(0.0, (a, b) => a + b);
                  final selectedIdx = st.selectedPieIndexFilter;

                  double selValue;
                  String selLabel;
                  double percent;

                  if (total <= 0) {
                    selValue = 0.0;
                    selLabel = 'Total';
                    percent = 0.0;
                  } else if (selectedIdx == null ||
                      selectedIdx < 0 ||
                      selectedIdx >= values.length) {
                    selValue = total;
                    selLabel = 'Total';
                    percent = 1.0;
                  } else {
                    selValue = values[selectedIdx];
                    selLabel = labels[selectedIdx];
                    percent = (selValue / total).clamp(0.0, 1.0);
                  }

                  // índice da região selecionada (usa canonização interna do state)
                  final selectedRegionIdx =
                  st.indexOfRegionNormalized(st.selectedRegionFilter);

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // ===== Gauge + Pie =====
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // ---- GAUGE ----
                              SizedBox(
                                width: kGaugeBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double side =
                                        constraints.maxWidth;

                                    return GaugeChartChange(
                                      centerLabel: percent,
                                      footerLabel:
                                      '$selLabel • ${_fmtKm(selValue)}',
                                      headerMode: GaugeTextMode.number,
                                      centerMode: GaugeTextMode.number,
                                      values: [
                                        double.parse(
                                          selValue.toStringAsFixed(3),
                                        ),
                                      ],
                                      footerMode:
                                      GaugeTextMode.explicit,
                                      widthGraphic: side,
                                      footerFontSize: 12,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ---- PIE (Status) — valores em km ----
                              SizedBox(
                                width: kPieBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double side =
                                        constraints.maxWidth;
                                    return DonutChartChanged(
                                      colorCard: Colors.white,
                                      valueFormatType:
                                      ValueFormatType.decimal,
                                      labels:
                                      st.pieLabelsForChart,
                                      values:
                                      st.pieValuesForChart, // km
                                      colorsSlices:
                                      st.pieColorsForChart,
                                      selectedIndex:
                                      st.selectedPieIndexFilter,
                                      widthGraphic: side,
                                      heightGraphic: 295,
                                      onTouch: (idx) {
                                        cubit.setPieFilter(idx);
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ===== Barras por região (respeita pie) — km =====
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableWidth =
                            constraints.hasBoundedWidth
                                ? constraints.maxWidth
                                : MediaQuery.of(context)
                                .size
                                .width;

                            final int n =
                                st.regionLabels.length;
                            final double minContentWidth =
                                16 + n * (kBarWidth + kBarGap) + 16;

                            final double contentWidth =
                            minContentWidth >
                                availableWidth
                                ? minContentWidth
                                : availableWidth;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentWidth,
                                child: BarChartChanged(
                                  colorCard: Colors.white,
                                  valueFormatter: (v) => _fmtKm(v),
                                  heightGraphic: 260,
                                  widthBar: kBarWidth,
                                  labels: st.regionLabels,
                                  values: st.regionSumsKm(),
                                  selectedIndex: selectedRegionIdx,
                                  onBarTap: (label) {
                                    final newRegion =
                                    label == st.selectedRegionFilter ? null : label;
                                    cubit.setRegionFilter(newRegion);
                                  },
                                  expandToMaxWidth: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
