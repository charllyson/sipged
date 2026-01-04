// lib/screens/sectors/traffic/dashboard/accidents_analytics_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/transit/accidents/accidents_cubit.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/screens/sectors/traffic/accidents/accidents_selector_dates_section.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_charts_section.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_summary_section.dart';

// ===================== Painel de Analytics (cards + gráficos + filtro) =====================
class AccidentsAnalyticsPanel extends StatefulWidget {
  const AccidentsAnalyticsPanel({super.key});

  @override
  State<AccidentsAnalyticsPanel> createState() =>
      _AccidentsAnalyticsPanelState();
}

class _AccidentsAnalyticsPanelState extends State<AccidentsAnalyticsPanel> {
  String? _selectedRegionName;
  String? _selectedTypeName;

  void _onTypeSelectedLocal(String? typeName, List<String> labelsType) {
    if (typeName == null ||
        typeName.toUpperCase() == _selectedTypeName?.toUpperCase()) {
      _selectedTypeName = null;
    } else {
      _selectedTypeName = typeName;
    }
    setState(() {});
  }

  void _onRegionSelectedLocal(String? regionName, List<String> labelsRegiao) {
    if (regionName == null ||
        regionName.toUpperCase() == _selectedRegionName?.toUpperCase()) {
      _selectedRegionName = null;
    } else {
      _selectedRegionName = regionName;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
        BlocBuilder<AccidentsCubit, AccidentsState>(
          builder: (context, state) {
            // dados para os cards/resumo
            final totalsByType = state.totalsByType;
            final totalsByCity = state.totalsByCity;

            // arrays para os gráficos (somente >0)
            final labelsType = totalsByType.entries
                .where((e) => e.value > 0)
                .map((e) => e.key)
                .toList();
            final valuesType = totalsByType.entries
                .where((e) => e.value > 0)
                .map((e) => e.value)
                .toList();

            final labelsRegiao = totalsByCity.entries
                .where((e) => e.value > 0)
                .map((e) => e.key)
                .toList();
            final valuesRegiao = totalsByCity.entries
                .where((e) => e.value > 0)
                .map((e) => e.value)
                .toList();

            // índices selecionados
            final selectedIndexType = (_selectedTypeName == null)
                ? null
                : labelsType.indexWhere(
                  (t) =>
              t.toUpperCase() ==
                  _selectedTypeName!.toUpperCase(),
            );
            final selectedIndexRegiao = (_selectedRegionName == null)
                ? null
                : labelsRegiao.indexWhere(
                  (r) =>
              r.toUpperCase() ==
                  _selectedRegionName!.toUpperCase(),
            );

            // totais
            final valorTotal = state.universe.length.toDouble();
            final totalByType = state.view.length.toDouble();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(text: 'Estatística geral de acidentes'),
                  AccidentsSummarySection(
                    totalsByType: state.resumeByType,
                  ),
                  const SectionTitle(text: 'Maiores índices por tipos e cidades'),
                  AccidentsChartsSection(
                    labelsType: labelsType,
                    valuesType: valuesType,
                    labelsRegiao: labelsRegiao,
                    valuesRegiao: valuesRegiao,
                    selectedIndexType: selectedIndexType,
                    selectedIndexRegiao: selectedIndexRegiao,
                    totalAccidents: totalByType,
                    valorTotal: valorTotal,
                    onTypeSelected: (t) =>
                        _onTypeSelectedLocal(t, labelsType),
                    onRegionTap: (r) =>
                        _onRegionSelectedLocal(r, labelsRegiao),
                  ),

                  const SectionTitle(text: 'Filtro por ano'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AccidentsSelectorDatesSection(
                      allAccidents: state.universe,
                      initialYear: state.year,
                      initialMonth: state.month,
                      onSelectionChanged: (res) async {
                        final y = res.selectedYear, m = res.selectedMonth;
                        if (y == state.year && m == state.month) return;
                        context.read<AccidentsCubit>().changeFilter(
                          year: y,
                          month: m,
                        );
                      },
                    ),
                  ),

                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        ),

        // Overlay leve de loading
        BlocBuilder<AccidentsCubit, AccidentsState>(
          buildWhen: (a, b) => a.loading != b.loading,
          builder: (context, state) {
            if (!state.loading) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(12),
                  child: const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
