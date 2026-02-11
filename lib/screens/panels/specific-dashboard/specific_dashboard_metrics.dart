import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_utils/formats/sipged_format_money.dart';
import 'package:siged/_widgets/charts/cost_ruler/cost_ruler.dart';
import 'package:siged/_widgets/charts/legend/chart_legend.dart';
import 'package:siged/_widgets/charts/linear_bar/types.dart';

import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:siged/_blocs/panels/specific_dashboard/specific_dashboard_state.dart';

class SpecificDashboardMetrics extends StatelessWidget {
  const SpecificDashboardMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double kCardHeight = 170.0;
    const double kLegendWidth = 400.0;

    const Map<String, double> benchmarks = {
      'Média': 1200.0,
      'Teto': 2000.0,
    };

    const Color kAtualColor = Color(0xFF22C55E);
    const Color kMediaColor = Color(0xFF3B82F6);
    const Color kTetoColor = Color(0xFFFFA500);

    const List<String> groupLegendLabels = ['Atual', 'Média', 'Teto'];
    const List<Color> legendColors = [kAtualColor, kMediaColor, kTetoColor];

    return BlocBuilder<SpecificDashboardCubit, SpecificDashboardState>(
      builder: (context, state) {
        final double valorContratado =
        state.contractValues.isNotEmpty ? state.contractValues[0] : 0.0;

        final double totalAditivos =
        state.contractValues.length > 1 ? state.contractValues[1] : 0.0;

        final double totalApostilamentos =
        state.apostillesValues.isNotEmpty ? state.apostillesValues[0] : 0.0;

        final double km = state.dfdExtensaoKm;

        final double numerador =
        (valorContratado + totalAditivos + totalApostilamentos)
            .clamp(0.0, double.infinity);

        final double custoPorKm = (km > 0) ? (numerador / km) : 0.0;

        final double teto = benchmarks['Teto'] ?? 0.0;
        final double maxAuto = math.max(teto, custoPorKm);
        final double maxNice = _niceMax(maxAuto);

        // ✅ pega do estado (alimentado pelo Cubit)
        final String natureza = (state.dfdNaturezaIntervencao ?? '').trim();
        final String naturezaLabel = natureza.isEmpty ? 'NÃO INFORMADO' : natureza;

        final List<String> legendRowLabels = <String>[
          'CUSTO POR KM DE: $naturezaLabel',
        ];

        final List<List<double>> legendValues = <List<double>>[
          <double>[
            custoPorKm,
            benchmarks['Média'] ?? 0.0,
            benchmarks['Teto'] ?? 0.0,
          ],
        ];

        Widget buildLegendCard() {
          return ChartLegend(
            labels: legendRowLabels,
            values: legendValues,
            groupLegendLabels: groupLegendLabels,
            colors: legendColors,
            valueType: ValueType.money,
            isDark: isDark,
            compact: true,
            isSmall: false,
            widthCard: double.infinity,
            heightCard: kCardHeight,
            isLoading: false,
            boldLegendIndices: const {0},
          );
        }

        Widget buildCostRulerCard() {
          return SizedBox(
            height: kCardHeight,
            child: CostRuler(
              computedValue: custoPorKm,
              value: 0.0,
              divisor: 1.0,
              title: 'Custo por km',
              unitLabel: 'km',
              benchmarks: benchmarks,
              min: 0.0,
              max: maxNice,
              formatter: (v) => SipGedFormatMoney.doubleToText(v),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 900;

            if (isNarrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: buildLegendCard(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: buildCostRulerCard(),
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
                  Expanded(flex: 3, child: buildCostRulerCard()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static double _niceMax(double v) {
    if (v <= 0) return 1.0;
    final exp = (math.log(v) / math.ln10).floor();
    final base = math.pow(10.0, exp).toDouble();
    final scaled = v / base;
    double nice;
    if (scaled <= 1) nice = 1;
    else if (scaled <= 2) nice = 2;
    else if (scaled <= 5) nice = 5;
    else nice = 10;
    return nice * base;
  }
}
