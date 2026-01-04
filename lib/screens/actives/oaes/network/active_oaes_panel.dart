// lib/screens/sectors/actives/oaes/active_oaes_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:siged/_widgets/charts/bars/bar_chart_changed.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_cubit.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';

class ActiveOaesPanel extends StatelessWidget {
  const ActiveOaesPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    const double kGaugeBoxWidth = 260;
    const double kPieBoxWidth = 280;
    const double kBarWidth = 50.0;
    const double kBarGap = 16.0;

    return Stack(
      children: [
        const BackgroundClean(),
        Column(
          children: [
            Expanded(
              child: BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
                // 🔥 Painel só recalcula quando dados ou filtros mudam
                buildWhen: (prev, curr) {
                  return prev.all != curr.all ||
                      prev.selectedPieIndexFilter !=
                          curr.selectedPieIndexFilter ||
                      prev.selectedRegionFilter !=
                          curr.selectedRegionFilter ||
                      prev.regionLabels != curr.regionLabels;
                },
                builder: (context, st) {
                  final cubit = context.read<ActiveOaesCubit>();

                  final gaugeVm = st.gaugeForPieSelectionWithRegion(
                    region: st.selectedRegionFilter,
                    selectedPieIndex: st.selectedPieIndexFilter,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // === Gauge + Pizza =====================================================
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              SizedBox(
                                width: kGaugeBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double side = constraints.maxWidth;
                                    final double dynamicRadius = side * 0.35;
                                    final double dynamicFontSize =
                                        dynamicRadius * 0.5;

                                    return Padding(
                                      padding:
                                      const EdgeInsets.only(top: 12.0),
                                      child: GaugeCircularPercent(
                                        centerTitle: gaugeVm.percent
                                            .clamp(0.0, 1.0),
                                        footerTitle: gaugeVm.label,
                                        headerMode:
                                        GaugeTextMode.number,
                                        centerMode:
                                        GaugeTextMode.number,
                                        values: [gaugeVm.count],
                                        footerMode:
                                        GaugeTextMode.explicit,
                                        radius: dynamicRadius,
                                        larguraGrafico: side,
                                        centerFontSize:
                                        dynamicFontSize,
                                        footerFontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: kPieBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double side = constraints.maxWidth;
                                    final double chartHeight =
                                    (side * 0.85).clamp(160.0, 195.0);

                                    final double maxOuter =
                                        (chartHeight / 2) - 12.0;

                                    final double baseSlice =
                                    (side * 0.2).clamp(34.0, maxOuter);
                                    final double hiSlice =
                                    (baseSlice + 6.0)
                                        .clamp(baseSlice, maxOuter);
                                    final double centerHole =
                                    (baseSlice * 0.58)
                                        .clamp(18.0, baseSlice - 10.0);

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                        top: 12,
                                      ),
                                      child: PieChartChanged(
                                        colorCard: Colors.white,
                                        valueFormatType:
                                        ValueFormatType.integer,
                                        labels: st.pieLabelsForChart,
                                        values: st.pieValuesForChart,
                                        coresPersonalizadas:
                                        st.pieColorsForChart,
                                        selectedIndex:
                                        st.selectedPieIndexFilter,
                                        larguraGrafico: side,
                                        alturaCard: 295,
                                        chartHeight: chartHeight,
                                        sliceRadius: baseSlice,
                                        sliceRadiusHighlighted:
                                        hiSlice,
                                        centerSpaceRadius:
                                        centerHole,
                                        sectionsSpace: 2,
                                        onTouch: (idx) {
                                          cubit.setPieFilter(idx);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // === Barras por região =================================================
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableWidth =
                            constraints.hasBoundedWidth
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;

                            final int n = st.regionLabels.length;
                            final double minContentWidth =
                                16 + n * (kBarWidth + kBarGap) + 16;

                            final double contentWidth =
                            minContentWidth > availableWidth
                                ? minContentWidth
                                : availableWidth;

                            final selectedRegionIdx =
                            st.selectedRegionFilter == null
                                ? null
                                : st.regionLabels.indexWhere(
                                  (r) =>
                              r.toUpperCase() ==
                                  st.selectedRegionFilter!
                                      .toUpperCase(),
                            );

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: BarChartChanged(
                                    colorCard: Colors.white,
                                    valueFormatter: (v) =>
                                        v.toStringAsFixed(0),
                                    heightGraphic: 260,
                                    widthBar: kBarWidth,
                                    labels: st.regionLabels,
                                    values: st
                                        .regionCountsFilteredByPie(),
                                    selectedIndex: selectedRegionIdx,
                                    onBarTap: (label) {
                                      final newRegion =
                                      label ==
                                          st.selectedRegionFilter
                                          ? null
                                          : label;
                                      cubit.setRegionFilter(newRegion);
                                    },
                                    expandToMaxWidth: true,
                                  ),
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
