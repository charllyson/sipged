// lib/_widgets/panels/specific_dashboard/specific_dashboard_metrics.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/charts/cost_ruler/cost_ruler.dart';
import 'package:sipged/_widgets/charts/legend/chart_legend.dart';
import 'package:sipged/_widgets/charts/linear_bar/types.dart';

import 'package:sipged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/specific_dashboard/specific_dashboard_state.dart';

class SpecificDashboardMetrics extends StatefulWidget {
  const SpecificDashboardMetrics({super.key});

  @override
  State<SpecificDashboardMetrics> createState() => _SpecificDashboardMetricsState();
}

class _SpecificDashboardMetricsState extends State<SpecificDashboardMetrics> {
  /// 0 = Atual, 1 = Média, 2 = Teto
  int? _selectedMetricIndex;

  void _toggleMetricIndex(int index) {
    setState(() {
      _selectedMetricIndex = (_selectedMetricIndex == index) ? null : index;
    });
  }

  /// ✅ mesma lógica de cor do marcador "Atual" na régua
  Color _colorForAtual({
    required double value,
    required double? media,
    required double? teto,
  }) {
    if (teto != null && teto.isFinite && teto > 0 && value > teto) {
      return Colors.red;
    }
    if (media != null && media.isFinite && media > 0 && value <= media) {
      return Colors.green;
    }
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double kCardHeight = 170.0;
    const double kLegendWidth = 400.0;

    // ✅ mantém consistente com o RulerPainter (defaults)
    const Color kRulerAccent = Color(0xFF4C6BFF); // mesma do CostRuler/RulerPainter
    const Color kRulerTeto = Colors.red; // mesmo do RulerPainter para "Teto"

    const List<String> groupLegendLabels = ['Este contrato', 'Média', 'Teto'];

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

        final double mediaDinamica = state.benchmarkMediaCostPerKm;
        final double tetoDinamico = state.benchmarkTetoCostPerKm;

        final Map<String, double> benchmarks = <String, double>{
          'Média': mediaDinamica,
          'Teto': tetoDinamico,
        };

        final double maxAuto =
        math.max(tetoDinamico, math.max(custoPorKm, mediaDinamica));
        final double maxNice = _niceMax(maxAuto);

        final String natureza = (state.dfdNaturezaIntervencao ?? '').trim();
        final String naturezaLabel = natureza.isEmpty ? 'NÃO INFORMADO' : natureza;

        final List<String> legendRowLabels = <String>[
          'CUSTO POR KM DE: $naturezaLabel',
        ];

        final List<List<double>> legendValues = <List<double>>[
          <double>[custoPorKm, mediaDinamica, tetoDinamico],
        ];

        // ✅ cores da legenda calculadas para bater com os círculos da régua
        final Color atualColor = _colorForAtual(
          value: custoPorKm,
          media: mediaDinamica,
          teto: tetoDinamico,
        );
        final List<Color> legendColors = <Color>[
          atualColor,
          kRulerAccent,
          kRulerTeto,
        ];

        final int? selectedRowIndex = (_selectedMetricIndex == null) ? null : 0;
        final int? selectedSliceIndex = _selectedMetricIndex;

        Widget buildLegendCard() {
          return ChartLegend(
            labels: legendRowLabels,
            values: legendValues,
            groupLegendLabels: groupLegendLabels,
            colors: legendColors, // ✅ agora bate com a régua
            valueType: ValueType.money,
            isDark: isDark,
            compact: true,
            isSmall: false,
            widthCard: double.infinity,
            heightCard: kCardHeight,
            isLoading: state.resumeLoading,
            boldLegendIndices: const {0},

            selectedRowIndex: selectedRowIndex,
            selectedSliceIndex: selectedSliceIndex,
            onLegendTap: (row, slice, rowLabel, sliceLabel) {
              if (row != 0) return;
              if (slice < 0 || slice > 2) return;
              _toggleMetricIndex(slice);
            },
          );
        }

        Widget buildCostRulerCard() {
          return SizedBox(
            height: kCardHeight,
            child: CostRuler(
              computedValue: custoPorKm,
              value: 0.0,
              divisor: 1.0,
              title: 'Custo por km (Contratado + Aditivos + Apostilamentos)',
              unitLabel: 'km',
              benchmarks: benchmarks,
              min: 0.0,
              max: maxNice,
              formatter: (v) => SipGedFormatMoney.doubleToText(v),

              // ✅ mantém a seleção sincronizada
              selectedIndex: _selectedMetricIndex,
              onMarkerTap: (index) {
                if (index < 0 || index > 2) return;
                _toggleMetricIndex(index);
              },

              // ✅ garante mesma cor “Média” da régua com a legenda
              accentColor: kRulerAccent,
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
                    child: SizedBox(width: double.infinity, child: buildLegendCard()),
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
    if (scaled <= 1) {
      nice = 1;
    } else if (scaled <= 2) {
      nice = 2;
    }
    else if (scaled <= 5) {
      nice = 5;
    }
    else {
      nice = 10;
    }
    return nice * base;
  }
}
