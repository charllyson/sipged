import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_state.dart';
import 'package:siged/_widgets/charts/linear_bar/horizontal_bar_chart_bars.dart';

import 'package:siged/_widgets/charts/linear_bar/horizontal_bar_chart_changed.dart';
import 'package:siged/_widgets/charts/legend/chart_legend.dart';
import 'package:siged/_widgets/charts/linear_bar/types.dart';
import 'package:siged/_widgets/charts/linear_bar/range_overlay_config.dart';

class SpecificDashboardContractSummary extends StatelessWidget {
  final bool isLoading;

  const SpecificDashboardContractSummary({
    super.key,
    this.isLoading = false,
  });

  String _formatMoney(double v) => 'R\$ ${v.toStringAsFixed(0)}';

  List<double> _ensureLength(List<double> values, int n) {
    if (values.length == n) return values;
    if (values.length > n) return values.sublist(0, n);
    return <double>[...values, ...List<double>.filled(n - values.length, 0.0)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double kCardHeight = 165.0;
    const double kLegendWidth = 400.0;

    const String label = 'CONTRATO + ADITIVOS';

    // ============================
    // LEGEND: 4 linhas (inclui medição e saldo)
    // ============================
    const List<String> legendSliceLabels = [
      '(+) Valor Contratado',
      '(+) Valor de Aditivos',
      '(-) Total de Medições',
      '(=) Saldo do Contrato',
    ];
    const Color kMedicoesColor = Color(0xFFFFA500);
    const Color kContratosColor = Color(0xFF3B82F6);
    const Color kAditivosColor = Color(0xFF93C5FD);


    const List<Color> legendSliceColors = [
      kContratosColor,
      kAditivosColor,
      kMedicoesColor,
      Color(0xFFF5F5F5),
    ];

    // ============================
    // BAR: somente 2 fatias (Contrato + Aditivos)
    // ============================
    const List<String> barSliceLabels = [
      '(+) Valor Contratado',
      '(+) Valor de Aditivos',
    ];

    const List<Color> barSliceColors = [
      kContratosColor,
      kAditivosColor,
    ];

    return BlocBuilder<SpecificDashboardCubit, SpecificDashboardState>(
      builder: (context, state) {
        final cubit = context.read<SpecificDashboardCubit>();
        final labelsLegend = const <String>[label];
        final contract4 = _ensureLength(state.contractValues, 4);
        final double valorContratado = contract4[0];
        final double totalAditivos = contract4[1];
        final double totalMedicoes = contract4[2];
        final bool effectiveLoading = isLoading || state.resumeLoading;
        final int? selectedRowIndex =
        (state.selectedContractSliceIndex == null) ? null : 0;

        final int? selectedSliceIndexForBar = (state.selectedContractSliceIndex != null &&
            state.selectedContractSliceIndex! >= 0 &&
            state.selectedContractSliceIndex! <= 1)
            ? state.selectedContractSliceIndex
            : null;

        final List<double> barValues = <double>[
          valorContratado,
          totalAditivos,
        ];
        final double contratoAtualMax = (valorContratado + totalAditivos).clamp(0.0, double.infinity);
        final RangeOverlayConfig? overlay = (contratoAtualMax > 0 && totalMedicoes > 0)
            ? RangeOverlayConfig(
          startValue: 0,
          endValue: totalMedicoes.clamp(0.0, contratoAtualMax),
          maxValue: contratoAtualMax,
          fillColor: kMedicoesColor.withOpacity(0.28),
          dashedLineColor: kMedicoesColor.withOpacity(0.85),
          overlayOverflow: 8,
          dashedStrokeWidth: 2,
          dashWidth: 6.0,
          dashGap: 4.0,
          showLabels: true,
          valueType: ValueType.money,
        )
            : null;
        final valuesLegend = <List<double>>[contract4];
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 900;

            Widget buildLegendCard() {
              return ChartLegend(
                widthCard: isNarrow ? double.infinity : kLegendWidth,
                heightCard: kCardHeight,
                labels: labelsLegend,
                values: valuesLegend,
                groupLegendLabels: legendSliceLabels,
                colors: legendSliceColors,
                valueType: ValueType.money,
                isDark: isDark,
                compact: true,
                isSmall: false,
                isLoading: effectiveLoading,
                boldLegendIndices: {3},
                selectedRowIndex: selectedRowIndex,
                selectedSliceIndex: selectedSliceIndexForBar,

                onLegendTap: (row, slice, rowLabel, sliceLabel) {
                  if (slice <= 1) {
                    cubit.toggleContractSlice(sliceIndex: slice);
                  } else {
                    cubit.clearContractSelection();
                  }
                },
              );
            }

            Widget buildBarCard() {
              return HorizontalBarChanged(
                label: '',
                values: barValues,
                barHeight: 97,
                sliceColors: barSliceColors,
                groupLegendLabels: barSliceLabels,
                showSliceLabelsOnBar: false,
                sliceLabelLocation: LabelLocation.aboveBar,
                labelWidth: 0,
                cardHeight: kCardHeight,
                selectedRowIndex: selectedRowIndex,
                selectedSliceIndex: selectedSliceIndexForBar,
                rangeOverlay: overlay,
                onSliceTap: (row, slice, rowLabel, sliceLabel) {
                  cubit.toggleContractSlice(sliceIndex: slice);
                },
                isLoading: effectiveLoading,
              );
            }

            if (isNarrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: buildLegendCard(),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: buildBarCard(),
                  ),
                  if (state.resumeError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Text(
                        state.resumeError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: kLegendWidth, child: buildLegendCard()),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: buildBarCard()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
