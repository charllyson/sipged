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
  const ActiveOaesPanel({
    super.key,
    this.onClose,
  });

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    const double kGaugeBoxWidth = 260;
    const double kPieBoxWidth = 280;
    const double kBarWidth = 50.0;
    const double kBarGap = 16.0;

    return Stack(
      children: [
        const BackgroundChange(),
        Column(
          children: [
            Expanded(
              child: BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
                buildWhen: (prev, curr) {
                  return prev.all != curr.all ||
                      prev.selectedPieIndexFilter != curr.selectedPieIndexFilter ||
                      prev.selectedRegionFilter != curr.selectedRegionFilter ||
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
                                    final double dynamicFontSize = dynamicRadius * 0.5;

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: GaugeChartChange(
                                        centerLabel: gaugeVm.percent.clamp(0.0, 1.0),
                                        footerLabel: gaugeVm.label,
                                        headerMode: GaugeTextMode.number,
                                        centerMode: GaugeTextMode.number,
                                        values: [gaugeVm.count],
                                        footerMode: GaugeTextMode.explicit,
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
                                    final double side = constraints.maxWidth;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                        top: 12,
                                      ),
                                      child: DonutChartChanged(
                                        colorCard: Colors.white,
                                        valueFormatType: ValueFormatType.integer,
                                        labels: st.pieLabelsForChart,
                                        values: st.pieValuesForChart,
                                        colorsSlices: st.pieColorsForChart,
                                        selectedIndex: st.selectedPieIndexFilter,
                                        widthGraphic: side,
                                        heightGraphic: 295,

                                        // Ao clicar em uma fatia:
                                        // - se for nova, seleciona;
                                        // - se for a mesma, o próprio Donut envia null.
                                        // O Cubit também foi blindado para alternar.
                                        onTouch: cubit.setPieFilter,
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
                            final double availableWidth = constraints.hasBoundedWidth
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;

                            final int n = st.regionLabels.length;

                            final double minContentWidth =
                                16 + n * (kBarWidth + kBarGap) + 16;

                            final double contentWidth = minContentWidth > availableWidth
                                ? minContentWidth
                                : availableWidth;

                            final int? selectedRegionIdx =
                            st.selectedRegionFilter == null
                                ? null
                                : st.regionLabels.indexWhere(
                                  (region) =>
                              region.trim().toUpperCase() ==
                                  st.selectedRegionFilter!.trim().toUpperCase(),
                            );

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentWidth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: BarChartChanged(
                                    colorCard: Colors.white,
                                    valueFormatter: (value) => value.toStringAsFixed(0),
                                    heightGraphic: 260,
                                    widthBar: kBarWidth,
                                    labels: st.regionLabels,
                                    values: st.regionCountsFilteredByPie(),
                                    selectedIndex: selectedRegionIdx != null &&
                                        selectedRegionIdx >= 0
                                        ? selectedRegionIdx
                                        : null,

                                    // Aqui estava o problema:
                                    // onBarTap não recebe null quando clica novamente.
                                    // onBarSelectionChanged recebe null e limpa a seleção.
                                    onBarSelectionChanged: cubit.setRegionFilter,

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