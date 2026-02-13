// lib/screens/panels/specific-dashboard/specific_dashboard_schedules_details.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/charts/linear_bar/horizontal_bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/legend/chart_legend.dart';
import 'package:sipged/_widgets/charts/linear_bar/slice_hatch_config.dart';
import 'package:sipged/_widgets/charts/linear_bar/types.dart';

// Cubit/State específicos do dashboard de acompanhamento físico
import 'package:sipged/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart';
import 'package:sipged/_blocs/panels/specific_dashboard/specific_dashboard_state.dart';

class ServiceStatusRow {
  final String label;
  final double pctConcluido;
  final double pctAndamento;
  final double pctAIniciar;

  const ServiceStatusRow({
    required this.label,
    required this.pctConcluido,
    required this.pctAndamento,
    required this.pctAIniciar,
  });

  List<double> get values => <double>[
    pctConcluido,
    pctAndamento,
    pctAIniciar,
  ];
}

class SpecificDashboardScheduleDetails extends StatelessWidget {
  final List<ServiceStatusRow> rows;

  /// Valores gerais (somatório) na ordem:
  /// [Concluído, Em andamento, A iniciar]
  final List<double> geralValues;

  /// Quando true, mostra shimmer nas barras/legendas.
  final bool isLoading;

  const SpecificDashboardScheduleDetails({
    super.key,
    required this.rows,
    required this.geralValues,
    this.isLoading = false,
  });

  static const String _kLabelGeral = 'GERAL';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpecificDashboardCubit, SpecificDashboardState>(
      builder: (context, state) {
        const sliceLabels = <String>['Concluído', 'Em andamento', 'A iniciar'];
        List<Color> sliceColors = <Color>[
          Colors.green,
          Colors.amber,
          Colors.grey.shade200,
        ];

        // Alturas / larguras base dos cards
        const double kCardHeight = 77.0;
        const double kLegendWidth = 400.0;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Se não está carregando e não há serviços, mostramos só o GERAL.
        final List<ServiceStatusRow> effectiveRows;
        if (!isLoading && rows.isEmpty) {
          effectiveRows = const <ServiceStatusRow>[];
        } else {
          effectiveRows = rows;
        }

        String fmt(double v) => '${v.toStringAsFixed(1)}%';

        final cubit = context.read<SpecificDashboardCubit>();

        return Column(
          children: [
            // ============================================================
            // LINHA GERAL  (rowIndex global = 0)
            // ============================================================
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRow(
                context: context,
                legendLabel: _kLabelGeral,
                globalRowIndex: 0,
                values: geralValues,
                sliceLabels: sliceLabels,
                sliceColors: sliceColors,
                cardHeight: kCardHeight,
                legendWidth: kLegendWidth,
                isDark: isDark,
                isLoading: isLoading,
                state: state,
                cubit: cubit,
                formatter: fmt,
              ),
            ),

            // ============================================================
            // LINHAS DE SERVIÇOS (rowIndex global = 1..N)
            // ============================================================
            for (int i = 0; i < effectiveRows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRow(
                  context: context,
                  legendLabel: effectiveRows[i].label,
                  globalRowIndex: i + 1,
                  values: effectiveRows[i].values,
                  sliceLabels: sliceLabels,
                  sliceColors: sliceColors,
                  cardHeight: kCardHeight,
                  legendWidth: kLegendWidth,
                  isDark: isDark,
                  isLoading: isLoading,
                  state: state,
                  cubit: cubit,
                  formatter: fmt,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String legendLabel,
    required int globalRowIndex,
    required List<double> values,
    required List<String> sliceLabels,
    required List<Color> sliceColors,
    required double cardHeight,
    required double legendWidth,
    required bool isDark,
    required bool isLoading,
    required SpecificDashboardState state,
    required SpecificDashboardCubit cubit,
    required String Function(double) formatter,
  }) {
    // Verifica se ESTA linha é a atualmente selecionada
    final bool isSelectedRow = state.selectedScheduleRowIndex == globalRowIndex;

    // Como cada card tem apenas 1 linha, o índice local é sempre 0 quando selecionado
    final int? localSelectedRowIndex = isSelectedRow ? 0 : null;
    final int? selectedSliceIndex =
    isSelectedRow ? state.selectedScheduleSliceIndex : null;

    // Responsividade: quebra em coluna no mobile
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600; // breakpoint simples

    // ---------- LEGENDA ----------
    final legendWidget = ChartLegend(
      widthCard: isMobile ? double.infinity : legendWidth,
      heightCard: cardHeight,
      isSmall: true,
      labels: <String>[legendLabel],
      values: <List<double>>[values],
      groupLegendLabels: sliceLabels,
      colors: sliceColors,
      valueType: ValueType.percent,
      isDark: isDark,
      compact: true,
      selectedRowIndex: localSelectedRowIndex,
      selectedSliceIndex: selectedSliceIndex,//
      onLegendTap: (row, slice, rowLabel, sliceLabel) {
        cubit.toggleScheduleSlice(
          rowIndex: globalRowIndex,
          sliceIndex: slice,
        );
      },
      isLoading: isLoading,
    );

    // ---------- BARRA ----------
    final barWidget = HorizontalBarChanged(
      label: legendLabel,
      values: values,
      groupLegendLabels: sliceLabels,
      sliceColors: sliceColors,
      barHeight: 28,
      labelWidth: 0,
      gapLabelToBar: 12,
      sliceLabelLocation: LabelLocation.none,
      showSliceLabelsOnBar: false,
      isLoading: isLoading,
      cardHeight: cardHeight,
      selectedRowIndex: localSelectedRowIndex,
      selectedSliceIndex: selectedSliceIndex,
      hatch: SliceHatchConfig(
          byIndex: {
            2: SliceHatchStyle(
              lineColor: Colors.grey.shade300,
              backgroundOpacity: 0.18,
            ),
          }
      ),
    );

    // ====== MOBILE: legenda em cima, barra embaixo ======
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          legendWidget,
          const SizedBox(height: 8),
          barWidget,
        ],
      );
    }

    // ====== DESKTOP/TABLET: legenda + barra lado a lado ======
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        legendWidget,
        const SizedBox(width: 12),
        Expanded(child: barWidget),
      ],
    );
  }
}
