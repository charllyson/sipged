import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/_widgets/upBar/up_bar.dart';
import 'package:sisged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:sisged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:sisged/_widgets/charts/bars/bar_chart_changed.dart';

import 'package:sisged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:sisged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:sisged/_blocs/actives/oaes/active_oaes_event.dart';

class OaesRightStatsPanel extends StatelessWidget {
  const OaesRightStatsPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    const double kGaugeBoxWidth = 260;
    const double kPieBoxWidth = 280;
    const double kWrapSpacing = 16.0;
    const double kWrapRunSpacing = 16.0;

    const double kBarWidth = 50.0;
    const double kBarGap = 16.0;
    const double kWideBreakpoint = 980; // ajuste se quiser
    final bool isWide = MediaQuery.of(context).size.width >= kWideBreakpoint;

    return Stack(
      children: [
        BackgroundClean(),
        Column(
          children: [
            Expanded(
              child: BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
                builder: (context, st) {
                  final bloc = context.read<ActiveOaesBloc>();

                  // Gauge derivado do Pie
                  final gaugeVm = st.gaugeForPieSelection(
                    selectedPieIndex: st.selectedPieIndexFilter,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: kWrapSpacing,
                          runSpacing: kWrapRunSpacing,
                          alignment: WrapAlignment.center,
                          children: [
                            // ---- GAUGE ----
                            SizedBox(
                              width: kGaugeBoxWidth,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double side = constraints.maxWidth;
                                  final double dynamicRadius = side * 0.35;
                                  final double dynamicFontSize = dynamicRadius * 0.5;

                                  return GaugeCircularPercent(
                                    centerTitle: gaugeVm.percent.clamp(0.0, 1.0),
                                    footerTitle: gaugeVm.label,
                                    headerMode: GaugeTextMode.number,
                                    centerMode: GaugeTextMode.number,
                                    values: [gaugeVm.count],
                                    footerMode: GaugeTextMode.explicit,
                                    radius: dynamicRadius,
                                    larguraGrafico: side,
                                    centerFontSize: dynamicFontSize,
                                    footerFontSize: 12,
                                  );
                                },
                              ),
                            ),

                            // ---- PIE ----
                            SizedBox(
                              width: kPieBoxWidth,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double side = constraints.maxWidth;
                                  final double chartHeight = (side * 0.85).clamp(160.0, 195.0);
                                  final double maxOuter = (chartHeight / 2) - 12.0;

                                  final double baseSlice =
                                  (side * 0.2).clamp(34.0, maxOuter);
                                  final double hiSlice =
                                  (baseSlice + 6.0).clamp(baseSlice, maxOuter);
                                  final double centerHole =
                                  (baseSlice * 0.58).clamp(18.0, baseSlice - 10.0);

                                  return PieChartChanged(
                                    colorCard: Colors.white,
                                    valueFormatType: ValueFormatType.integer,
                                    labels: st.pieLabelsForChart,
                                    values: st.pieValuesForChart,
                                    coresPersonalizadas: st.pieColorsForChart,
                                    selectedIndex: st.selectedPieIndexFilter,
                                    larguraGrafico: side,
                                    alturaCard: 295,
                                    chartHeight: chartHeight,
                                    sliceRadius: baseSlice,
                                    sliceRadiusHighlighted: hiSlice,
                                    centerSpaceRadius: centerHole,
                                    sectionsSpace: 2,
                                    onTouch: (idx) {
                                      bloc.add(ActiveOaesPieFilterChanged(idx));
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ---- BARRAS (Regiões) ----
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableWidth = constraints.hasBoundedWidth
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;

                            final int n = st.regionLabels.length;
                            final double minContentWidth =
                                16 + n * (kBarWidth + kBarGap) + 16;

                            final double contentWidth =
                            minContentWidth > availableWidth ? minContentWidth : availableWidth;

                            final selectedRegionIdx = st.selectedRegionFilter == null
                                ? null
                                : st.regionLabels.indexWhere(
                                  (r) => r.toUpperCase() ==
                                  st.selectedRegionFilter!.toUpperCase(),
                            );

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentWidth,
                                child: BarChartChanged(
                                  colorCard: Colors.white,
                                  valueFormatter: (v) => v.toStringAsFixed(0),
                                  heightGraphic: 260,
                                  widthBar: kBarWidth,
                                  labels: st.regionLabels,
                                  values: st.regionCountsFilteredByPie(),
                                  selectedIndex: selectedRegionIdx,
                                  onBarTap: (label) {
                                    final newRegion = label == st.selectedRegionFilter
                                        ? null
                                        : label;
                                    bloc.add(ActiveOaesRegionFilterChanged(newRegion));
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
