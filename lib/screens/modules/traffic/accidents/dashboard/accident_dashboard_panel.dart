// lib/screens/modules/traffic/accidents/dashboard/accident_dashboard_panel.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/charts/horizontal_bars/horizontal_bars.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_widgets/charts/pies/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/section_title.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'package:sipged/screens/modules/traffic/accidents/dashboard/insight_strip.dart';
import 'package:sipged/screens/modules/traffic/accidents/dashboard/kpi_card.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_state.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

class AccidentDashboardPanel extends StatefulWidget {
  const AccidentDashboardPanel({super.key});

  @override
  State<AccidentDashboardPanel> createState() => _AccidentDashboardPanelState();
}

class _AccidentDashboardPanelState extends State<AccidentDashboardPanel> {
  late final TextEditingController _yearCtrl;
  late final TextEditingController _monthCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _severityCtrl;

  static const String kAll = 'TODOS';
  static const String kAllCities = 'TODAS';

  @override
  void initState() {
    super.initState();
    _yearCtrl = TextEditingController();
    _monthCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _typeCtrl = TextEditingController();
    _severityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _cityCtrl.dispose();
    _typeCtrl.dispose();
    _severityCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(
      AccidentsState s,
      List<String> cities,
      List<String> types,
      List<String> severities,
      ) {
    final yearText = (s.year ?? DateTime.now().year).toString();
    final monthText = (s.month ?? 0).toString();
    final cityText =
    (s.city == null || s.city!.trim().isEmpty) ? kAllCities : s.city!;
    final typeText =
    (s.type == null || s.type!.trim().isEmpty) ? kAll : s.type!;
    final sevText =
    (s.severity == null || s.severity!.trim().isEmpty) ? kAll : s.severity!;

    if (_yearCtrl.text != yearText) _yearCtrl.text = yearText;
    if (_monthCtrl.text != monthText) _monthCtrl.text = monthText;
    if (_cityCtrl.text != cityText) _cityCtrl.text = cityText;
    if (_typeCtrl.text != typeText) _typeCtrl.text = typeText;
    if (_severityCtrl.text != sevText) _severityCtrl.text = sevText;

    if (!cities.contains(_cityCtrl.text)) _cityCtrl.text = kAllCities;
    if (_typeCtrl.text != kAll && !types.contains(_typeCtrl.text)) {
      _typeCtrl.text = kAll;
    }
    if (_severityCtrl.text != kAll && !severities.contains(_severityCtrl.text)) {
      _severityCtrl.text = kAll;
    }
  }

  Map<String, int> _bySeverity(List<AccidentsData> list) {
    final out = <String, int>{'LEVE': 0, 'MODERADO': 0, 'GRAVE': 0};
    for (final a in list) {
      final key = AccidentsDataSeverity.severityOf(a);
      out[key] = (out[key] ?? 0) + 1;
    }
    out.removeWhere((k, v) => v == 0);
    return out;
  }

  List<_DayPoint> _seriesByDay(List<AccidentsData> list) {
    final map = <int, int>{};
    for (final a in list) {
      final d = a.date?.toLocal();
      if (d == null) continue;
      map[d.day] = (map[d.day] ?? 0) + 1;
    }
    final orderedKeys = map.keys.toList()..sort();
    return orderedKeys
        .map((day) => _DayPoint(day: day, value: map[day]!.toDouble()))
        .toList();
  }

  String _topCity(List<AccidentsData> list) {
    final counts = <String, int>{};
    for (final a in list) {
      final c = (a.city ?? a.locality ?? '').trim();
      if (c.isEmpty) continue;
      final key = c.toUpperCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return '—';
    String best = counts.keys.first;
    int bestV = counts[best]!;
    for (final e in counts.entries) {
      if (e.value > bestV) {
        best = e.key;
        bestV = e.value;
      }
    }
    return best;
  }

  int _deaths(List<AccidentsData> list) {
    int sum = 0;
    for (final a in list) {
      sum += (a.death ?? 0);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccidentsCubit>();

    return BlocBuilder<AccidentsCubit, AccidentsState>(
      builder: (context, state) {
        final theme = Theme.of(context);

        final years = List.generate(5, (i) => (DateTime.now().year - i).toString());
        final months = List.generate(13, (i) => i.toString()); // 0 = todos

        final cities = <String>[
          kAllCities,
          ...state.totalsByCity.keys.toList()
            ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase())),
        ];

        final types = state.totalsByType.keys.toList()..sort();
        final severities = _bySeverity(state.view).keys.toList()..sort();

        _syncControllers(state, cities, types, severities);

        final total = state.view.length;
        final deaths = _deaths(state.view);
        final sevMap = _bySeverity(state.view);
        final severe = (sevMap['GRAVE'] ?? 0);

        final ordered = _seriesByDay(state.view);
        final labelsTrend = ordered.map((e) => e.day.toString()).toList();
        final valuesTrend = ordered.map((e) => e.value).toList();

        final topCity = _topCity(state.view);

        final byType = <String, int>{};
        for (final a in state.view) {
          final key = AccidentsData.canonicalType(a.typeOfAccident);
          byType[key] = (byType[key] ?? 0) + 1;
        }
        final donutLabels = byType.keys.toList()..sort();
        final donutValues = donutLabels.map((k) => (byType[k] ?? 0).toDouble()).toList();

        final donutColors = List<Color>.generate(
          donutLabels.length,
              (i) => SipGedTheme.chartPaletteColors(i),
        );

        final bySeverity = sevMap;

        return LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxWidth < 720;
            final veryNarrow = c.maxWidth < 520;

            final hTrend = compact ? 220.0 : 240.0;
            final hDonut = compact ? 260.0 : 280.0;
            final hSevBars = compact ? 260.0 : 280.0;

            final Widget kpiReal = veryNarrow
                ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 132,
                    child: KpiCard(
                      title: 'Sinistros',
                      value: '$total',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 132,
                    child: KpiCard(
                      title: 'Graves',
                      value: '$severe',
                      icon: Icons.local_hospital_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 132,
                    child: KpiCard(
                      title: 'Óbitos',
                      value: '$deaths',
                      icon: Icons.heart_broken_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            )
                : Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Sinistros',
                    value: '$total',
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCard(
                    title: 'Graves',
                    value: '$severe',
                    icon: Icons.local_hospital_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiCard(
                    title: 'Óbitos',
                    value: '$deaths',
                    icon: Icons.heart_broken_outlined,
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    kpiReal,
                    const SizedBox(height: 12),

                    BasicCard(
                      isDark: theme.brightness == Brightness.dark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Filtros',
                            subtitle: 'Recortes e sincronização com o mapa',
                            icon: Icons.tune_rounded,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                child: DropDownButtonChange(
                                  controller: _yearCtrl,
                                  labelText: 'Ano',
                                  items: years,
                                  menuMaxHeight: 320,
                                  onChanged: (v) {
                                    final parsed = int.tryParse(v ?? '');
                                    if (parsed == null) return;
                                    cubit.changeFilter(
                                      year: parsed,
                                      month: state.month,
                                      city: state.city,
                                      type: state.type,
                                      severity: state.severity,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: DropDownButtonChange(
                                  controller: _monthCtrl,
                                  labelText: 'Mês',
                                  items: months,
                                  menuMaxHeight: 320,
                                  sortTransformer: (list) => list,
                                  onChanged: (v) {
                                    final parsed = int.tryParse(v ?? '');
                                    if (parsed == null) return;
                                    cubit.changeFilter(
                                      year: state.year,
                                      month: parsed == 0 ? null : parsed,
                                      city: state.city,
                                      type: state.type,
                                      severity: state.severity,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 210,
                                child: DropDownButtonChange(
                                  controller: _cityCtrl,
                                  labelText: 'Cidade',
                                  items: cities,
                                  menuMaxHeight: 320,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    cubit.changeFilter(
                                      year: state.year,
                                      month: state.month,
                                      city: (v == kAllCities) ? null : v,
                                      type: state.type,
                                      severity: state.severity,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    BasicCard(
                      isDark: theme.brightness == Brightness.dark,
                      child: InsightStrip(
                        title: 'Insight rápido',
                        text: total == 0
                            ? 'Sem registros neste recorte.'
                            : 'Concentração em $topCity. Ajuste filtros para explorar padrões.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),

                    const SizedBox(height: 12),

                    LineChartChanged(
                      headerTitle: 'Tendência',
                      headerSubtitle: 'Volume diário',
                      headerIcon: Icons.show_chart_rounded,
                      labels: labelsTrend.isEmpty ? const ['—'] : labelsTrend,
                      values: valuesTrend.isEmpty ? const [0.0] : valuesTrend,
                      alturaGrafico: hTrend,
                      showLegend: false,
                      prefix: 'Dia ',
                      tooltipFormatter: (v) => '${v.toInt()} sinistros',
                    ),

                    const SizedBox(height: 12),

                    // ✅ Donut com TOGGLE
                    DonutChartChanged(
                      labels: donutLabels,
                      values: donutValues,
                      legendPosition: DonutLegendPosition.right,
                      coresPersonalizadas: donutColors,
                      valueFormatType: ValueFormatType.integer,
                      chartHeight: hDonut - 20,
                      centerSpaceRadius: 34,
                      sectionsSpace: 3,
                      sliceRadius: 44,
                      onTapLabel: (label) {
                        if (label == null) return;
                        cubit.toggleType(label); // ✅ toggle
                      },
                    ),

                    const SizedBox(height: 12),

                    BasicCard(
                      isDark: theme.brightness == Brightness.dark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Gravidade',
                            subtitle: 'Ranking no recorte',
                            icon: Icons.leaderboard_rounded,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: hSevBars,
                            child: HorizontalBars(
                              data: bySeverity,
                              highlightKey: state.severity,
                              onTapKey: (key) {
                                cubit.toggleSeverity(key); // ✅ toggle
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (state.error != null && state.error!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.withOpacity(0.85),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DayPoint {
  final int day;
  final double value;
  const _DayPoint({required this.day, required this.value});
}

class AccidentsDataSeverity {
  static String severityOf(AccidentsData a) {
    final deaths = (a.death ?? 0);
    if (deaths > 0) return 'GRAVE';

    final score = (a.scoresVictims ?? 0);
    if (score >= 3) return 'GRAVE';
    if (score == 2) return 'MODERADO';
    return 'LEVE';
  }
}
