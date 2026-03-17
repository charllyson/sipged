import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_chart_change.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/screens/modules/actives/roads/network/color_mode_selector.dart';

class ActiveRoadsPanel extends StatelessWidget {
  const ActiveRoadsPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  String _fmtKm(double v) => '${v.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    const gaugeBoxWidth = 260.0;
    const pieBoxWidth = 280.0;
    const barWidth = 50.0;
    const barGap = 16.0;

    return Stack(
      children: [
        BackgroundClean(),
        Column(
          children: [
            Expanded(
              child: BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
                builder: (context, state) {
                  final cubit = context.read<ActiveRoadsCubit>();
                  final gaugeVm = state.gaugeForCurrentFilters();
                  final selectedRegionIdx =
                  state.indexOfRegionNormalized(state.selectedRegionFilter);
                  final selectedVsaIdx = state.selectedVsaFilter != null
                      ? state.selectedVsaFilter! - 1
                      : null;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              SizedBox(
                                width: gaugeBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final side = constraints.maxWidth;
                                    final radius = side * 0.35;
                                    final centerFont = radius * 0.5;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12.0,
                                        right: 12,
                                      ),
                                      child: GaugeChartChange(
                                        heightGraphic: 230,
                                        centerLabel:
                                        gaugeVm.percent.clamp(0.0, 1.0),
                                        footerLabel:
                                        '${gaugeVm.label} • ${_fmtKm(gaugeVm.count)}',
                                        headerMode: GaugeTextMode.number,
                                        centerMode: GaugeTextMode.number,
                                        values: [
                                          double.parse(
                                            gaugeVm.count.toStringAsFixed(3),
                                          ),
                                        ],
                                        footerMode: GaugeTextMode.explicit,
                                        radius: radius,
                                        widthGraphic: side,
                                        centerFontSize: centerFont,
                                        footerFontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                width: pieBoxWidth,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final side = constraints.maxWidth;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: DonutChartChanged(
                                        colorCard: Colors.white,
                                        valueFormatType: ValueFormatType.decimal,
                                        labels: state.pieLabelsForChart,
                                        values: state.pieValuesForChart,
                                        colorsSlices: state.pieColorsForChart,
                                        selectedIndex: state.selectedPieIndexFilter,
                                        widthGraphic: side,
                                        heightGraphic: 230,
                                        onTouch: (index) {
                                          final newValue =
                                          index == state.selectedPieIndexFilter
                                              ? null
                                              : index;
                                          cubit.setPieFilter(newValue);
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
                            final availableWidth = constraints.hasBoundedWidth
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;

                            final count = state.regionLabels.length;
                            final minContentWidth =
                                16 + count * (barWidth + barGap) + 16;

                            final contentWidth = minContentWidth > availableWidth
                                ? minContentWidth
                                : availableWidth;

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
                                    chartTitle: 'Km por regional',
                                    valueFormatter: (v) => _fmtKm(v),
                                    heightGraphic: 230,
                                    widthBar: barWidth,
                                    labels: state.regionLabels,
                                    values: state.regionCountsFilteredByPie(),
                                    barColors: state.regionBarColors(
                                      selectedRegionIdx,
                                    ),
                                    selectedIndex: selectedRegionIdx,
                                    onBarTap: (label) {
                                      final newRegion =
                                      label == state.selectedRegionFilter
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
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ColorModeSelectorCards(
                              selectedMode: state.colorMode,
                              onChanged: cubit.setColorMode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: BarChartChanged(
                            colorCard: Colors.white,
                            chartTitle: 'Valor de Avaliação Subjetiva',
                            valueFormatter: (v) => _fmtKm(v),
                            heightGraphic: 230,
                            widthBar: 52,
                            labels: state.vsaLabelsForChart,
                            values: state.vsaKmValuesForChart,
                            barColors: state.vsaColorsForChart,
                            selectedIndex: selectedVsaIdx,
                            expandToMaxWidth: true,
                            sortType: BarChartSortType.none,
                            onBarTap: (label) {
                              final idx =
                              state.vsaLabelsForChart.indexOf(label);
                              if (idx < 0) return;

                              final tappedVsa = idx + 1;
                              final newVsa =
                              state.selectedVsaFilter == tappedVsa
                                  ? null
                                  : tappedVsa;

                              cubit.setVsaFilter(newVsa);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
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