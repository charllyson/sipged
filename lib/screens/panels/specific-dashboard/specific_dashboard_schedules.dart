import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Dados do contrato
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

// Schedule rodoviário
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

// Widget que renderiza GERAL + serviços
import 'package:sipged/screens/panels/specific-dashboard/specific_dashboard_schedules_details.dart';

// Layout responsivo
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class SpecificDashboardSchedules extends StatefulWidget {
  final ContractData contract;
  final String tenantId;

  const SpecificDashboardSchedules({
    super.key,
    required this.contract,
    required this.tenantId,
  });

  @override
  State<SpecificDashboardSchedules> createState() =>
      _SpecificDashboardSchedulesState();
}

class _SpecificDashboardSchedulesState extends State<SpecificDashboardSchedules> {
  /// Future cacheado para evitar recriação desnecessária a cada build.
  Future<List<ServiceStatusRow>>? _rowsFuture;

  /// Chave usada para saber quando o Future precisa ser recriado.
  String? _rowsFutureKey;

  String get _contractId => (widget.contract.id ?? '').trim();

  String get _tenantId => widget.tenantId.trim();

  bool get _hasValidContextIds => _tenantId.isNotEmpty && _contractId.isNotEmpty;

  ScheduleRoadRepository _createRepository() {
    return ScheduleRoadRepository(
      tenantId: _tenantId,
    );
  }

  // =====================================================================
  // A INICIAR, EM ANDAMENTO, CONCLUÍDO
  // =====================================================================
  Future<List<ServiceStatusRow>> _computeRows({
    required int totalEstacas,
  }) async {
    if (!_hasValidContextIds) return const <ServiceStatusRow>[];

    final repo = _createRepository();

    final services = (await repo.loadAvailableServicesFromBudget(_contractId))
        .where((s) => s.key.toLowerCase() != 'geral')
        .toList(growable: false);

    final lanes = await repo.loadFaixas(_contractId);

    if (services.isEmpty || lanes.isEmpty) {
      return const <ServiceStatusRow>[];
    }

    if (totalEstacas <= 0) {
      return services
          .map(
            (s) => ServiceStatusRow(
          label: s.label.toUpperCase(),
          pctConcluido: 0.0,
          pctAndamento: 0.0,
          pctAIniciar: 100.0,
        ),
      )
          .toList(growable: false);
    }

    final rows = <ServiceStatusRow>[];

    for (final service in services) {
      final enabledLaneCount =
          lanes.where((lane) => lane.isAllowed(service.key)).length;

      final laneCount = enabledLaneCount > 0 ? enabledLaneCount : lanes.length;

      final int meta = math.max(1, totalEstacas * laneCount);

      final execs = await repo.fetchExecucoes(
        contractId: _contractId,
        selectedServiceKey: service.key,
        serviceKeysForGeral: const <String>[],
        metaForSelected: ScheduleRoadData(
          numero: 0,
          faixaIndex: 0,
          key: service.key,
          label: service.label,
          icon: service.icon,
          color: service.color,
        ),
      );

      int concluidos = 0;
      int andamento = 0;

      for (final exec in execs) {
        final status = _canonicalStatus(exec.status);

        if (status == 'concluido') {
          concluidos++;
        } else if (status == 'em_andamento') {
          andamento++;
        }
      }

      final double pctConcluido = (concluidos / meta) * 100.0;
      final double pctAndamento = (andamento / meta) * 100.0;
      final double pctAIniciar =
      (100.0 - pctConcluido - pctAndamento).clamp(0.0, 100.0);

      rows.add(
        ServiceStatusRow(
          label: service.label.toUpperCase(),
          pctConcluido: pctConcluido,
          pctAndamento: pctAndamento,
          pctAIniciar: pctAIniciar,
        ),
      );
    }

    return rows;
  }

  String _canonicalStatus(String? raw) {
    var value = (raw ?? '').toLowerCase().trim();

    value = value
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
        .replaceAll(RegExp(r'[\s\-_]+'), ' ');

    if (value.contains('conclu')) return 'concluido';

    if (value.contains('andament') || value.contains('progress')) {
      return 'em_andamento';
    }

    return 'a_iniciar';
  }

  /// Garante que o Future só seja recriado quando mudar:
  /// - tenantId
  /// - contractId
  /// - totalEstacas
  /// - revisão de geometria
  /// - revisão de execuções
  /// - revisão de serviços
  /// - revisão de faixas
  Future<List<ServiceStatusRow>>? _ensureRowsFuture(ScheduleRoadState st) {
    if (!_hasValidContextIds) {
      _rowsFutureKey = null;
      _rowsFuture = Future.value(const <ServiceStatusRow>[]);
      return _rowsFuture;
    }

    final key = [
      _tenantId,
      _contractId,
      st.totalEstacas,
      st.geometryRevision,
      st.execRevision,
      st.servicesRevision,
      st.lanesRevision,
    ].join('|');

    if (_rowsFuture == null || _rowsFutureKey != key) {
      _rowsFutureKey = key;
      _rowsFuture = _computeRows(
        totalEstacas: st.totalEstacas,
      );
    }

    return _rowsFuture;
  }

  /// Placeholder para manter a mesma altura de layout enquanto carrega.
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

  @override
  void didUpdateWidget(covariant SpecificDashboardSchedules oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldContractId = (oldWidget.contract.id ?? '').trim();
    final newContractId = _contractId;

    if (oldWidget.tenantId.trim() != _tenantId || oldContractId != newContractId) {
      _rowsFutureKey = null;
      _rowsFuture = null;
    }
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleRoadCubit>().state;

    final geralValues = <double>[
      schedule.pctConcluido.isFinite ? schedule.pctConcluido : 0.0,
      schedule.pctAndamento.isFinite ? schedule.pctAndamento : 0.0,
      schedule.pctAIniciar.isFinite ? schedule.pctAIniciar : 0.0,
    ];

    final rowsFuture = _ensureRowsFuture(schedule);

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 12,
      gap: 12,
      verticalGap: 12,
      fixedWidths: const <double?>[null],
      enableScrollOnSmall: false,
      children: [
            (context, m, i) {
          return FutureBuilder<List<ServiceStatusRow>>(
            future: rowsFuture,
            builder: (context, snap) {
              final bool stillLoading = schedule.loadingExecucoes ||
                  schedule.loadingServices ||
                  schedule.loadingLanes ||
                  !schedule.initialized ||
                  rowsFuture == null ||
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

              final rows = snap.data ?? const <ServiceStatusRow>[];

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