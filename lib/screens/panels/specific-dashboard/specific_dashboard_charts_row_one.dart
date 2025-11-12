// lib/screens/panels/specific-dashboard/specific_dashboard_charts_row_one.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_overview_style.dart';

import 'package:siged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:siged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:siged/_widgets/charts/radar/radar_chart_changed_widget.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_style.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_controller.dart';

// <<< NOVO: leitura de extensão via DFD >>>
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

class SpecificDashboardChartRowOne extends StatelessWidget {
  final DemandsDashboardController controller;
  final ProcessData contract;

  const SpecificDashboardChartRowOne({
    super.key,
    required this.controller,
    required this.contract,
  });

  // Cache dos dados de barras por contrato
  static final Map<String, Future<({List<String> labels, List<double> values, List<Color> colors})>> _barCache = {};

  // Cache da extensão (km) vinda do DFD por contrato
  static final Map<String, Future<double>> _extKmCache = {};

  String _canonStatus(String? raw) {
    String t = (raw ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[\-\_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (t.contains('conclu')) return 'concluido';
    if (t.contains('andament') || t.contains('in progress')) return 'em_andamento';
    if (t.contains('todo') || t.contains('a iniciar')) return 'a_iniciar';
    return 'a_iniciar';
  }

  // ===== Extensão via DFD =====
  Future<double> _readExtentKmFromDfd(String contractId) {
    if (_extKmCache.containsKey(contractId)) return _extKmCache[contractId]!;
    final future = () async {
      try {
        final repo = DfdRepository();
        final res = await repo.readWorkTypeAndExtent(contractId);
        return (res.extensaoKm ?? 0.0).toDouble();
      } catch (_) {
        return 0.0;
      }
    }();
    _extKmCache[contractId] = future;
    return future;
  }

  // ===== Barras por serviço (% concluído) =====
  Future<({List<String> labels, List<double> values, List<Color> colors})>
  _loadServicePercents(BuildContext context) {
    final contractId = contract.id ?? '';
    if (contractId.isEmpty) {
      return Future.value((labels: <String>[], values: <double>[], colors: <Color>[]));
    }
    final cached = _barCache[contractId];
    if (cached != null) return cached;
    final future = _computeServicePercents(context, contractId);
    _barCache[contractId] = future;
    return future;
  }

  Future<({List<String> labels, List<double> values, List<Color> colors})>
  _computeServicePercents(BuildContext context, String contractId) async {
    ScheduleRoadRepository repo;
    try {
      repo = context.read<ScheduleRoadRepository>();
    } catch (_) {
      repo = ScheduleRoadRepository();
    }

    final services = (await repo.loadAvailableServicesFromBudget(contractId))
        .where((s) => s.key.toLowerCase() != 'geral')
        .toList();

    final lanes = await repo.loadFaixas(contractId);

    // <<< AJUSTE: usa extensão somente do DFD >>>
    final km = await _readExtentKmFromDfd(contractId);
    final totalEstacas = max(0, ((km * 1000) / 20).ceil());

    final List<String> labels = <String>[];
    final List<double> values = <double>[];
    final List<Color> colors = <Color>[];

    for (final s in services) {
      final serviceKey = s.key.toLowerCase();
      final enabledLaneCount = lanes.where((l) => l.isAllowed(serviceKey)).length;
      final totalEsperado = totalEstacas * enabledLaneCount;

      double pct = 0.0;
      if (totalEsperado > 0) {
        final execs = await repo.fetchExecucoes(
          contractId: contractId,
          selectedServiceKey: serviceKey,
          serviceKeysForGeral: const <String>[],
          metaForSelected: ScheduleRoadData(
            numero: 0,
            faixaIndex: 0,
            key: s.key,
            label: s.label,
            icon: s.icon,
            color: s.color,
          ),
        );

        final concluidos = execs.where((e) {
          final idx = e.faixaIndex;
          if (idx < 0 || idx >= lanes.length) return false;
          if (!lanes[idx].isAllowed(serviceKey)) return false;
          return _canonStatus(e.status) == 'concluido';
        }).length;

        pct = (concluidos / totalEsperado) * 100.0;
      }

      labels.add((s.label.isNotEmpty ? s.label : s.key).toUpperCase());
      values.add(pct);
      colors.add(ScheduleRoadStyle.colorForService(
        s.label.isNotEmpty ? s.label : s.key,
      ));
    }

    return (labels: labels, values: values, colors: colors);
  }

  @override
  Widget build(BuildContext context) {
    const double kPieWidth = 360;
    const double kRadarWidth = 360;

    const double kLeadingPadding = 12;
    const double kAfterPadding = 12;
    const double kBetweenPieRadar = 8;
    const double kBetweenRadarBar = 8;
    const double kTrailingPadding = 0;

    final labelsRadar = controller.radarServiceLabels;
    final datasets = controller.radarDatasetsServices(
      primary: DemandsDashboardOverviewStyle.kPrimary,
      warning: DemandsDashboardOverviewStyle.kWarning,
      success: DemandsDashboardOverviewStyle.kSuccess,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalFixed =
            kLeadingPadding + kPieWidth + kBetweenPieRadar + kRadarWidth + kBetweenRadarBar + kTrailingPadding + kAfterPadding;

        const double kBarMinWidth = 600;
        final double barWidth =
        (constraints.maxWidth > totalFixed)
            ? (constraints.maxWidth - totalFixed)
            : kBarMinWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: kLeadingPadding),

              // PIE
              SizedBox(
                width: kPieWidth,
                child: BlocBuilder<ScheduleRoadBloc, ScheduleRoadState>(
                  builder: (context, state) {
                    const pieLabels = <String>['Concluído', 'Em andamento', 'A iniciar'];
                    final pieValues = <double>[
                      state.pctConcluido,
                      state.pctAndamento,
                      state.pctAIniciar,
                    ];
                    final pieColors = <Color>[
                      Colors.green,
                      Colors.orange,
                      Colors.grey.shade400,
                    ];

                    return PieChartChanged(
                      larguraGrafico: kPieWidth,
                      sliceRadius: 50,
                      useExternalLegend: true,
                      showPercentageOutside: true,
                      coresPersonalizadas: pieColors,
                      labels: pieLabels,
                      values: pieValues,
                    );
                  },
                ),
              ),

              const SizedBox(width: kBetweenPieRadar),

              // RADAR
              SizedBox(
                width: kRadarWidth,
                child: RadarChartChanged(
                  labels: labelsRadar,
                  datasets: datasets,
                  tickCount: 5,
                  minAtCenter: false,
                  larguraGrafico: kRadarWidth,
                  alturaCard: 290,
                ),
              ),

              const SizedBox(width: kBetweenRadarBar),

              // BARRAS por serviço (% concluído)
              SizedBox(
                width: barWidth,
                child: FutureBuilder<({List<String> labels, List<double> values, List<Color> colors})>(
                  future: _loadServicePercents(context),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return BarChartChanged(
                        expandToMaxWidth: true,
                        heightGraphic: 260,
                        labels: const [],
                        values: const [],
                      );
                    }

                    final data = snap.data!;
                    return BarChartChanged(
                      expandToMaxWidth: true,
                      heightGraphic: 260,
                      labels: data.labels,
                      values: data.values,
                      barColors: data.colors,
                      valueFormatter: (v) => '${v.toStringAsFixed(0)}%',
                      onBarTap: (_) {},
                    );
                  },
                ),
              ),

              if (kTrailingPadding > 0) const SizedBox(width: kTrailingPadding),
              const SizedBox(width: kAfterPadding),
            ],
          ),
        );
      },
    );
  }
}
