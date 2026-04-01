// lib/screens/modules/actives/oaes/active_oaes_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_change.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

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
        BackgroundChange(),
        Column(
          children: [
            Expanded(
              child: BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
                builder: (context, st) {
                  final cubit = context.read<ActiveOaesCubit>();

                  final gaugeVm = st.gaugeForPieSelectionWithRegion(
                    region: st.selectedRegionFilter,
                    selectedPieIndex: st.selectedPieIndexFilter,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              SizedBox(
                                width: kGaugeBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double side =
                                        constraints.maxWidth;
                                    final double dynamicRadius =
                                        side * 0.35;
                                    final double dynamicFontSize =
                                        dynamicRadius * 0.5;

                                    return Padding(
                                      padding:
                                      const EdgeInsets.only(top: 12.0),
                                      child: GaugeChartChange(
                                        centerLabel: gaugeVm.percent
                                            .clamp(0.0, 1.0),
                                        footerLabel: gaugeVm.label,
                                        headerMode: GaugeTextMode.number,
                                        centerMode: GaugeTextMode.number,
                                        values: [gaugeVm.count],
                                        footerMode:
                                        GaugeTextMode.explicit,
                                        radius: dynamicRadius,
                                        widthGraphic: side,
                                        centerFontSize: dynamicFontSize,
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
                                    return Padding(
                                      padding:
                                      const EdgeInsets.only(
                                          right: 12.0, top: 12),
                                      child: DonutChartChanged(
                                        colorCard: Colors.white,
                                        valueFormatType:
                                        ValueFormatType.integer,
                                        labels: st.pieLabelsForChart,
                                        values: st.pieValuesForChart,
                                        colorsSlices:
                                        st.pieColorsForChart,
                                        selectedIndex:
                                        st.selectedPieIndexFilter,
                                        heightGraphic: 295,
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
                                : st.regionLabels.indexWhere((r) =>
                            r.toUpperCase() ==
                                st.selectedRegionFilter!
                                    .toUpperCase());

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
                                      label == st.selectedRegionFilter
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
