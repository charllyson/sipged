import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Dados do contrato
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

// Schedule rodoviário
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_repository.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';

// Widget que renderiza GERAL + serviços
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_schedules_details.dart';

// ✅ Novo layout
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class SpecificDashboardSchedules extends StatefulWidget {
  final ProcessData contract;

  const SpecificDashboardSchedules({
    super.key,
    required this.contract,
  });

  @override
  State<SpecificDashboardSchedules> createState() =>
      _SpecificDashboardSchedulesState();
}

class _SpecificDashboardSchedulesState extends State<SpecificDashboardSchedules> {
  /// Future cacheado para evitar recriação a cada build.
  Future<List<ServiceStatusRow>>? _rowsFuture;

  /// Último total de estacas usado para cálculo das linhas.
  int? _lastTotalEstacas;

  // =====================================================================
  // MÉTODO PARA GERAR LINHAS DE SERVIÇOS (A INICIAR, ANDAMENTO, CONCLUÍDO)
  // =====================================================================
  Future<List<ServiceStatusRow>> _computeRows(
      BuildContext context,
      int totalEstacas,
      ) async {
    final repo = ScheduleRoadRepository();
    final contractId = widget.contract.id ?? '';

    if (contractId.isEmpty) return [];

    final services = (await repo.loadAvailableServicesFromBudget(contractId))
        .where((s) => s.key.toLowerCase() != 'geral')
        .toList();

    final lanes = await repo.loadFaixas(contractId);

    if (services.isEmpty || lanes.isEmpty) return [];

    if (totalEstacas <= 0) {
      // Sem meta → 100% a iniciar para todos
      return services
          .map(
            (s) => ServiceStatusRow(
          label: s.label.toUpperCase(),
          pctConcluido: 0.0,
          pctAndamento: 0.0,
          pctAIniciar: 100.0,
        ),
      )
          .toList();
    }

    final List<ServiceStatusRow> rows = [];

    for (final s in services) {
      final enabledLaneCount = lanes.where((l) => l.isAllowed(s.key)).length;

      final laneCount = enabledLaneCount > 0 ? enabledLaneCount : lanes.length;

      final int meta = math.max(1, totalEstacas * laneCount);

      final execs = await repo.fetchExecucoes(
        contractId: contractId,
        selectedServiceKey: s.key,
        serviceKeysForGeral: const [],
        metaForSelected: ScheduleRoadData(
          numero: 0,
          faixaIndex: 0,
          key: s.key,
          label: s.label,
          icon: s.icon,
          color: s.color,
        ),
      );

      int c = 0;
      int a = 0;

      for (final e in execs) {
        final st = (e.status ?? '').toLowerCase();
        if (st.contains('concl')) {
          c++;
        } else if (st.contains('and')) {
          a++;
        }
      }

      final double pctConcluido = (c / meta) * 100.0;
      final double pctAndamento = (a / meta) * 100.0;
      final double pctAIniciar =
      (100.0 - pctConcluido - pctAndamento).clamp(0.0, 100.0);

      rows.add(
        ServiceStatusRow(
          label: s.label.toUpperCase(),
          pctConcluido: pctConcluido,
          pctAndamento: pctAndamento,
          pctAIniciar: pctAIniciar,
        ),
      );
    }

    return rows;
  }

  /// Placeholder para manter a mesma ALTURA de layout enquanto carrega.
  List<ServiceStatusRow> _placeholder() {
    return List.generate(
      7,
          (i) => const ServiceStatusRow(
        label: '···',
        pctConcluido: 0.0,
        pctAndamento: 0.0,
        pctAIniciar: 0.0,
      ),
    );
  }

  // =====================================================================
  // CICLO DE VIDA
  // =====================================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scheduleState = context.read<ScheduleRoadCubit>().state;
    final totalEstacas = scheduleState.totalEstacas;

    if (_lastTotalEstacas != totalEstacas) {
      _lastTotalEstacas = totalEstacas;
      _rowsFuture = _computeRows(context, totalEstacas);
    }
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleRoadCubit>().state;

    final geralValues = <double>[
      schedule.pctConcluido,
      schedule.pctAndamento,
      schedule.pctAIniciar,
    ];

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 12,
      verticalGap: 12,

      // Apenas 1 item ocupando tudo
      fixedWidths: const <double?>[null],

      enableScrollOnSmall: false,

      children: [
            (context, m, i) {
          return FutureBuilder<List<ServiceStatusRow>>(
            future: _rowsFuture,
            builder: (context, snap) {
              final bool stillLoading = schedule.loadingExecucoes ||
                  !schedule.initialized ||
                  _rowsFuture == null ||
                  snap.connectionState == ConnectionState.waiting;

              if (stillLoading) {
                return SpecificDashboardScheduleDetails(
                  geralValues: geralValues,
                  rows: _placeholder(),
                  isLoading: true,
                );
              }

              if (snap.hasError) {
                return SpecificDashboardScheduleDetails(
                  geralValues: geralValues,
                  rows: const <ServiceStatusRow>[],
                  isLoading: false,
                );
              }

              final rows = snap.data ?? <ServiceStatusRow>[];

              return SpecificDashboardScheduleDetails(
                geralValues: geralValues,
                rows: rows,
                isLoading: false,
              );
            },
          );
        },
      ],
    );
  }
}
