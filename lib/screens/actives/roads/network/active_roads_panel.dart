import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:siged/_widgets/charts/bars/bar_chart_changed.dart';

import 'package:siged/_blocs/actives/roads/active_roads_state.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';

class ActiveRoadsPanel extends StatelessWidget {
  const ActiveRoadsPanel({super.key, this.onClose});
  final VoidCallback? onClose;

  String _fmtKm(double v) => '${v.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    const double kGaugeBoxWidth = 260;
    const double kPieBoxWidth = 280;
    const double kWrapSpacing = 16.0;
    const double kWrapRunSpacing = 16.0;

    const double kBarWidth = 50.0;
    const double kBarGap = 16.0;

    return Stack(
      children: [
        BackgroundClean(),
        Column(
          children: [
            Expanded(
              child: BlocBuilder<ActiveRoadsBloc, ActiveRoadsState>(
                builder: (context, st) {
                  final bloc = context.read<ActiveRoadsBloc>();

                  // Gauge derivado do Pie — agora em km
                  final gaugeVm =
                  st.gaugeForPieSelection(selectedPieIndex: st.selectedPieIndexFilter);

                  // índice da região selecionada calculado no próprio state
                  final selectedRegionIdx =
                  st.indexOfRegionNormalized(st.selectedRegionFilter);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // ===== Gauge + Pie (wrap) =====
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
                                    footerTitle:
                                    '${gaugeVm.label} • ${_fmtKm(gaugeVm.count)}',
                                    headerMode: GaugeTextMode.number,
                                    centerMode: GaugeTextMode.number,
                                    values: [double.parse(gaugeVm.count.toStringAsFixed(3))], // km com 3 casas
                                    footerMode: GaugeTextMode.explicit,
                                    radius: dynamicRadius,
                                    larguraGrafico: side,
                                    centerFontSize: dynamicFontSize,
                                    footerFontSize: 12,
                                  );
                                },
                              ),
                            ),

                            // ---- PIE (Superfície/Status) — valores em km ----
                            SizedBox(
                              width: kPieBoxWidth,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double side = constraints.maxWidth;
                                  final double chartHeight =
                                  (side * 0.85).clamp(160.0, 195.0);
                                  final double maxOuter = (chartHeight / 2) - 12.0;

                                  final double baseSlice =
                                  (side * 0.2).clamp(34.0, maxOuter);
                                  final double hiSlice =
                                  (baseSlice + 6.0).clamp(baseSlice, maxOuter);
                                  final double centerHole =
                                  (baseSlice * 0.58).clamp(18.0, baseSlice - 10.0);

                                  return PieChartChanged(
                                    colorCard: Colors.white,
                                    // se o widget suportar decimais
                                    valueFormatType: ValueFormatType.decimal,
                                    labels: st.pieLabelsForChart,
                                    values: st.pieValuesForChart, // km
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
                                      bloc.add(ActiveRoadsPieFilterChanged(idx));
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ===== Barras por região (respeita pie) — valores em km =====
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableWidth = constraints.hasBoundedWidth
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;

                            final int n = st.regionLabels.length;
                            final double minContentWidth =
                                16 + n * (kBarWidth + kBarGap) + 16;

                            final double contentWidth =
                            minContentWidth > availableWidth
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
                                  values: st.regionCountsFilteredByPie(), // km
                                  selectedIndex: selectedRegionIdx,
                                  onBarTap: (label) {
                                    final newRegion = label == st.selectedRegionFilter
                                        ? null
                                        : label;
                                    bloc.add(ActiveRoadsRegionFilterChanged(newRegion));
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
