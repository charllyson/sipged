// lib/screens/panels/specific-dashboard/summaries/specific_dashboard_apostilles_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_state.dart';

import 'package:siged/_widgets/charts/linear_bar/horizontal_bar_chart_changed.dart';
import 'package:siged/_widgets/charts/legend/chart_legend.dart';
import 'package:siged/_widgets/charts/linear_bar/types.dart';
import 'package:siged/_widgets/charts/linear_bar/range_overlay_config.dart';

class SpecificDashboardApostillesSummary extends StatelessWidget {
  final bool isLoading;

  const SpecificDashboardApostillesSummary({
    super.key,
    this.isLoading = false,
  });

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

    const String label = 'APOSTILAMENTOS';

    // ============================
    // LEGEND: 3 linhas (inclui saldo)
    // ============================
    const List<String> legendSliceLabels = [
      '(+) Total de Apostilamentos',
      '(-) Total de Reajuste e Revisões',
      '(=) Saldo de Apostilamentos',
    ];

    // Verde (apostilamentos), Laranja (reajustes/revisões), Cinza (saldo)
    const Color kReajustesColor = Color(0xFFFFA500);
    const Color kApostilamentoColor = Color(0xFF22C55E);


    const List<Color> legendSliceColors = [
      kApostilamentoColor, // total apostilamentos
      kReajustesColor, // reajustes + revisões
      Color(0xFFF5F5F5), // saldo (apenas legenda)
    ];

    // ============================
    // BAR: SOMENTE 1 fatia (Total de Apostilamentos)
    // - saldo NÃO aparece no bar
    // - overlay: de 0 até totalReajustesRevisoes (dentro do totalApostilamentos)
    // ============================
    const List<String> barSliceLabels = [
      '(+) Total de Apostilamentos',
    ];

    const List<Color> barSliceColors = [
      kApostilamentoColor,
    ];

    return BlocBuilder<SpecificDashboardCubit, SpecificDashboardState>(
      builder: (context, state) {
        final cubit = context.read<SpecificDashboardCubit>();

        final bool effectiveLoading = isLoading || state.resumeLoading;

        final labelsLegend = const <String>[label];

        // Garantir 3 valores (apostilamentos, reajustes/revisões, saldo)
        final List<double> apostilles3 =
        _ensureLength(state.apostillesValues, 3);

        final double totalApostilamentos = apostilles3[0];
        final double totalReajustesRevisoes = apostilles3[1];
        // final double saldo = apostilles3[2]; // fica só na legenda

        // ✅ seleção: aqui só faz sentido selecionar slice 0 (bar tem 1 slice).
        final int? selectedRowIndex =
        (state.selectedApostillesSliceIndex == null) ? null : 0;

        final int? selectedSliceIndexForBar =
        (state.selectedApostillesSliceIndex != null &&
            state.selectedApostillesSliceIndex == 0)
            ? 0
            : null;

        // Valores da LEGENDA (3 linhas)
        final valuesLegend = <List<double>>[apostilles3];

        // Valores do BAR (1 fatia): total apostilamentos
        final List<double> barValues = <double>[
          totalApostilamentos,
        ];

        // Overlay: de 0 até totalReajustesRevisoes, limitado ao totalApostilamentos
        final double barMax =
        totalApostilamentos.clamp(0.0, double.infinity);

        final RangeOverlayConfig? overlay =
        (barMax > 0 && totalReajustesRevisoes > 0)
            ? RangeOverlayConfig(
          startValue: 0,
          endValue: totalReajustesRevisoes.clamp(0.0, barMax),
          maxValue: barMax,
          fillColor: kReajustesColor.withOpacity(0.28),
          dashedLineColor: kReajustesColor.withOpacity(0.85),
          overlayOverflow: 8,
          dashedStrokeWidth: 2,
          dashWidth: 6.0,
          dashGap: 4.0,
          showLabels: true,
          valueType: ValueType.money,
        )
            : null;

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

                // ✅ negrito no saldo (índice 2)
                boldLegendIndices: {2},

                // ✅ seleção só faz sentido para slice 0 (bar)
                selectedRowIndex: selectedRowIndex,
                selectedSliceIndex: selectedSliceIndexForBar,

                onLegendTap: (row, slice, rowLabel, sliceLabel) {
                  // Só permite selecionar a fatia 0 (Total Apostilamentos).
                  if (slice == 0) {
                    cubit.toggleApostillesSlice(sliceIndex: 0);
                  } else {
                    // Clicar em Reajustes/Revisões ou Saldo apenas limpa seleção.
                    cubit.clearApostillesSelection();
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
                  // Só existe slice 0
                  cubit.toggleApostillesSlice(sliceIndex: 0);
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
