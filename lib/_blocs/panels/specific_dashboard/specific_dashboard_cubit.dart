// lib/_blocs/panels/specific_dashboard/specific_dashboard_cubit.dart

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

import 'specific_dashboard_state.dart';

class SpecificDashboardCubit extends Cubit<SpecificDashboardState> {
  SpecificDashboardCubit({
    required this.dfdRepository,
    required this.additivesRepository,
    required this.apostillesRepository,
    required this.reportRepository,
    required this.adjustmentRepository,
    required this.revisionRepository,
  }) : super(const SpecificDashboardState());

  final DfdRepository dfdRepository;
  final AdditivesRepository additivesRepository;
  final ApostillesRepository apostillesRepository;

  final ReportExecutedRepository reportRepository;
  final AdjustmentMeasurementRepository adjustmentRepository;
  final RevisionMeasurementRepository revisionRepository;

  Future<void> loadForContract(String contractId) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      debugPrint('[SpecificDashboardCubit] contractId vazio. Abortando load.');
      return;
    }

    debugPrint('');
    debugPrint('============================================================');
    debugPrint('[SpecificDashboardCubit] loadForContract START');
    debugPrint('[SpecificDashboardCubit] contractId=$id');
    debugPrint('[SpecificDashboardCubit] tenantId=${dfdRepository.tenantId}');
    debugPrint('============================================================');

    emit(
      state.copyWith(
        resumeLoading: true,
        clearResumeError: true,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        dfdRepository.readDataForContract(id),
        additivesRepository.getAllAdditivesValue(id),
        apostillesRepository.getAllApostillesValue(id),
        reportRepository.getAllMeasurementsOfContract(uidContract: id),
        adjustmentRepository.getAllAdjustmentsOfContract(uidContract: id),
        revisionRepository.getAllRevisionsOfContract(uidContract: id),
      ]);

      final DfdData? dfd = results[0] as DfdData?;

      final double totalAditivos = _safeDouble(results[1]);
      final double totalApostilamentos = _safeDouble(results[2]);

      final reportList = (results[3] as List).cast<ReportExecutedData>();
      final adjustmentList =
      (results[4] as List).cast<AdjustmentMeasurementData>();
      final revisionList = (results[5] as List).cast<RevisionMeasurementData>();

      final double valorContratado = _resolveValorContratado(dfd);
      final double extensaoKm = _safeDouble(dfd?.extensaoKm);

      final String? naturezaLabel = _cleanNullableText(
        dfd?.naturezaIntervencao,
      );

      final String? naturezaId = _cleanNullableText(
        dfd?.naturezaIntervencaoId,
      );

      debugPrint('');
      debugPrint('[SpecificDashboardCubit] DFD carregado:');
      debugPrint('  dfd == null: ${dfd == null}');
      debugPrint('  valorDemanda: ${dfd?.valorDemanda}');
      debugPrint('  estimativaValor: ${dfd?.estimativaValor}');
      debugPrint('  valorContratado resolvido: $valorContratado');
      debugPrint('  extensaoKm: $extensaoKm');
      debugPrint('  naturezaIntervencao label: $naturezaLabel');
      debugPrint('  naturezaIntervencaoId: $naturezaId');
      debugPrint('  totalAditivos: $totalAditivos');
      debugPrint('  totalApostilamentos: $totalApostilamentos');
      debugPrint('  medições carregadas: ${reportList.length}');
      debugPrint('  reajustes carregados: ${adjustmentList.length}');
      debugPrint('  revisões carregadas: ${revisionList.length}');

      final double totalMedicoes =
      reportRepository.somarValorMedicoes(reportList);

      final double totalAdjustments =
      adjustmentRepository.sumAdjustments(adjustmentList);

      final double totalRevisions = revisionRepository.sumRevisions(revisionList);

      final double totalReajustesERevisoes =
          totalAdjustments + totalRevisions;

      final double saldoContrato =
          (valorContratado + totalAditivos) - totalMedicoes;

      final double saldoApostilamentos =
          totalApostilamentos - totalReajustesERevisoes;

      final contractValues = <double>[
        valorContratado,
        totalAditivos,
        totalMedicoes,
        saldoContrato,
      ];

      final apostillesValues = <double>[
        totalApostilamentos,
        totalReajustesERevisoes,
        saldoApostilamentos,
      ];

      final resumeValuesLegacy = <double>[
        valorContratado,
        totalAditivos,
        totalMedicoes,
        saldoContrato,
        totalApostilamentos,
        totalReajustesERevisoes,
        saldoApostilamentos,
      ];

      final benchmarkStats = await _computeBenchmarkStats(
        naturezaIntervencaoId: naturezaId,
        naturezaIntervencaoLabel: naturezaLabel,
      );

      final double benchmarkMedia = benchmarkStats.mediaPonderada;
      final double benchmarkTeto = benchmarkStats.tetoMax;

      debugPrint('');
      debugPrint('[SpecificDashboardCubit] Valores finais emitidos:');
      debugPrint('  contractValues: $contractValues');
      debugPrint('  apostillesValues: $apostillesValues');
      debugPrint('  benchmarkMediaCostPerKm: $benchmarkMedia');
      debugPrint('  benchmarkTetoCostPerKm: $benchmarkTeto');
      debugPrint('============================================================');
      debugPrint('[SpecificDashboardCubit] loadForContract END');
      debugPrint('============================================================');
      debugPrint('');

      emit(
        state.copyWith(
          resumeLoading: false,
          clearResumeError: true,
          dfdExtensaoKm: extensaoKm,
          dfdNaturezaIntervencao: naturezaLabel,
          dfdNaturezaIntervencaoId: naturezaId,
          benchmarkMediaCostPerKm: benchmarkMedia,
          benchmarkTetoCostPerKm: benchmarkTeto,
          contractValues: contractValues,
          apostillesValues: apostillesValues,
          resumeValues: resumeValuesLegacy,
        ),
      );
    } catch (e, stack) {
      debugPrint('');
      debugPrint('[SpecificDashboardCubit] ERRO em loadForContract');
      debugPrint('Erro: $e');
      debugPrint('Stack: $stack');
      debugPrint('');

      emit(
        state.copyWith(
          resumeLoading: false,
          resumeError: e.toString(),
        ),
      );
    }
  }

  Future<({double mediaPonderada, double tetoMax})> _computeBenchmarkStats({
    required String? naturezaIntervencaoId,
    required String? naturezaIntervencaoLabel,
  }) async {
    final cleanId = naturezaIntervencaoId?.trim();
    final cleanLabel = naturezaIntervencaoLabel?.trim();

    if (cleanId != null && cleanId.isNotEmpty) {
      return _computeBenchmarkStatsContratadoPorNaturezaId(cleanId);
    }

    if (cleanLabel != null && cleanLabel.isNotEmpty) {
      debugPrint('');
      debugPrint('[SpecificDashboardCubit][BENCHMARK] naturezaIntervencaoId vazio.');
      debugPrint('[SpecificDashboardCubit][BENCHMARK] Calculando pela label.');
      debugPrint('  naturezaIntervencao=$cleanLabel');

      return _computeBenchmarkStatsContratadoPorNaturezaLabel(cleanLabel);
    }

    debugPrint('');
    debugPrint('[SpecificDashboardCubit][BENCHMARK] NÃO CALCULADO');
    debugPrint('Motivo: naturezaIntervencaoId e naturezaIntervencao vieram vazios.');
    debugPrint('tenantId=${dfdRepository.tenantId}');

    return (
    mediaPonderada: 0.0,
    tetoMax: 0.0,
    );
  }

  Future<({double mediaPonderada, double tetoMax})>
  _computeBenchmarkStatsContratadoPorNaturezaId(
      String naturezaIntervencaoId,
      ) async {
    final cleanNaturezaId = naturezaIntervencaoId.trim();

    debugPrint('');
    debugPrint('[SpecificDashboardCubit][BENCHMARK][ID] START');
    debugPrint('  naturezaIntervencaoId=$cleanNaturezaId');
    debugPrint('  tenantId=${dfdRepository.tenantId}');

    if (cleanNaturezaId.isEmpty) {
      debugPrint('[SpecificDashboardCubit][BENCHMARK][ID] naturezaId vazio.');
      return (
      mediaPonderada: 0.0,
      tetoMax: 0.0,
      );
    }

    final seeds = await dfdRepository.listBenchmarkSeedsByNaturezaIntervencaoId(
      cleanNaturezaId,
    );

    return _computeBenchmarkFromSeeds(
      seeds: seeds,
      sourceLabel: 'ID:$cleanNaturezaId',
    );
  }

  Future<({double mediaPonderada, double tetoMax})>
  _computeBenchmarkStatsContratadoPorNaturezaLabel(
      String naturezaIntervencao,
      ) async {
    final cleanNatureza = naturezaIntervencao.trim();

    debugPrint('');
    debugPrint('[SpecificDashboardCubit][BENCHMARK][LABEL] START');
    debugPrint('  naturezaIntervencao=$cleanNatureza');
    debugPrint('  tenantId=${dfdRepository.tenantId}');

    if (cleanNatureza.isEmpty) {
      debugPrint('[SpecificDashboardCubit][BENCHMARK][LABEL] natureza vazia.');
      return (
      mediaPonderada: 0.0,
      tetoMax: 0.0,
      );
    }

    final seeds = await dfdRepository.listBenchmarkSeedsByNaturezaIntervencao(
      cleanNatureza,
    );

    return _computeBenchmarkFromSeeds(
      seeds: seeds,
      sourceLabel: 'LABEL:$cleanNatureza',
    );
  }

  Future<({double mediaPonderada, double tetoMax})> _computeBenchmarkFromSeeds({
    required List<({String contractId, double km})> seeds,
    required String sourceLabel,
  }) async {
    debugPrint('');
    debugPrint('[SpecificDashboardCubit][BENCHMARK] Seeds recebidos');
    debugPrint('  source=$sourceLabel');
    debugPrint('  seeds=${seeds.length}');

    if (seeds.isEmpty) {
      debugPrint(
        '[SpecificDashboardCubit][BENCHMARK] Nenhum contrato encontrado para $sourceLabel.',
      );

      return (
      mediaPonderada: 0.0,
      tetoMax: 0.0,
      );
    }

    for (final seed in seeds.take(20)) {
      debugPrint(
        '  seed contractId=${seed.contractId} | km=${seed.km}',
      );
    }

    if (seeds.length > 20) {
      debugPrint('  ... mais ${seeds.length - 20} seed(s)');
    }

    double sumValor = 0.0;
    double sumKm = 0.0;
    double tetoMax = 0.0;

    int okCount = 0;
    int ignoredCount = 0;

    const int batchSize = 12;

    for (int i = 0; i < seeds.length; i += batchSize) {
      final batch = seeds.sublist(
        i,
        math.min(i + batchSize, seeds.length),
      );

      debugPrint(
        '[SpecificDashboardCubit][BENCHMARK] Processando batch '
            '${(i ~/ batchSize) + 1} | itens=${batch.length}',
      );

      final futures = batch.map((seed) async {
        try {
          final seedContractId = seed.contractId.trim();
          final seedKm = seed.km;

          if (seedContractId.isEmpty) {
            return (
            ok: false,
            contractId: seedContractId,
            reason: 'contractId vazio',
            km: 0.0,
            base: 0.0,
            aditivos: 0.0,
            apostilas: 0.0,
            total: 0.0,
            );
          }

          if (seedKm <= 0 || !seedKm.isFinite) {
            return (
            ok: false,
            contractId: seedContractId,
            reason: 'km inválido: $seedKm',
            km: 0.0,
            base: 0.0,
            aditivos: 0.0,
            apostilas: 0.0,
            total: 0.0,
            );
          }

          final parts = await Future.wait<double>([
            dfdRepository.readBaseValueForContract(seedContractId),
            additivesRepository.getAllAdditivesValue(seedContractId),
            apostillesRepository.getAllApostillesValue(seedContractId),
          ]);

          final double base = parts[0];
          final double aditivos = parts[1];
          final double apostilas = parts[2];

          final double total = base + aditivos + apostilas;

          if (total <= 0 || !total.isFinite) {
            return (
            ok: false,
            contractId: seedContractId,
            reason: 'total inválido: $total',
            km: seedKm,
            base: base,
            aditivos: aditivos,
            apostilas: apostilas,
            total: total,
            );
          }

          return (
          ok: true,
          contractId: seedContractId,
          reason: '',
          km: seedKm,
          base: base,
          aditivos: aditivos,
          apostilas: apostilas,
          total: total,
          );
        } catch (e) {
          return (
          ok: false,
          contractId: seed.contractId,
          reason: 'erro: $e',
          km: seed.km,
          base: 0.0,
          aditivos: 0.0,
          apostilas: 0.0,
          total: 0.0,
          );
        }
      }).toList();

      final results = await Future.wait(futures);

      for (final result in results) {
        if (!result.ok) {
          ignoredCount++;

          debugPrint(
            '[SpecificDashboardCubit][BENCHMARK][IGNORADO] '
                'contractId=${result.contractId} | '
                'reason=${result.reason} | '
                'km=${result.km} | '
                'base=${result.base} | '
                'aditivos=${result.aditivos} | '
                'apostilas=${result.apostilas} | '
                'total=${result.total}',
          );

          continue;
        }

        okCount++;

        sumValor += result.total;
        sumKm += result.km;

        final double custoPorKmContrato = result.total / result.km;

        if (custoPorKmContrato.isFinite && custoPorKmContrato > tetoMax) {
          tetoMax = custoPorKmContrato;
        }

        debugPrint(
          '[SpecificDashboardCubit][BENCHMARK][OK] '
              'contractId=${result.contractId} | '
              'km=${result.km} | '
              'base=${result.base} | '
              'aditivos=${result.aditivos} | '
              'apostilas=${result.apostilas} | '
              'total=${result.total} | '
              'custoKm=$custoPorKmContrato',
        );
      }
    }

    final double mediaPonderada = sumKm > 0 ? sumValor / sumKm : 0.0;

    debugPrint('');
    debugPrint('[SpecificDashboardCubit][BENCHMARK] RESULTADO');
    debugPrint('  source=$sourceLabel');
    debugPrint('  okCount=$okCount');
    debugPrint('  ignoredCount=$ignoredCount');
    debugPrint('  sumValor=$sumValor');
    debugPrint('  sumKm=$sumKm');
    debugPrint('  mediaPonderada=$mediaPonderada');
    debugPrint('  tetoMax=$tetoMax');
    debugPrint('[SpecificDashboardCubit][BENCHMARK] END');
    debugPrint('');

    return (
    mediaPonderada: mediaPonderada.isFinite ? mediaPonderada : 0.0,
    tetoMax: tetoMax.isFinite ? tetoMax : 0.0,
    );
  }

  double _resolveValorContratado(DfdData? dfd) {
    final valorDemanda = _safeDouble(dfd?.valorDemanda);

    if (valorDemanda > 0) {
      return valorDemanda;
    }

    return _safeDouble(dfd?.estimativaValor);
  }

  double _safeDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      final parsed = value.toDouble();

      if (!parsed.isFinite) {
        return 0.0;
      }

      return parsed;
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return 0.0;
      }

      final normalized = text.replaceAll('.', '').replaceAll(',', '.');

      final parsed = double.tryParse(normalized) ??
          double.tryParse(text.replaceAll(',', '.')) ??
          0.0;

      if (!parsed.isFinite) {
        return 0.0;
      }

      return parsed;
    }

    return 0.0;
  }

  String? _cleanNullableText(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) {
      return null;
    }

    return clean;
  }

  void toggleScheduleSlice({
    required int rowIndex,
    required int sliceIndex,
  }) {
    final sameRow = state.selectedScheduleRowIndex == rowIndex;
    final sameSlice = state.selectedScheduleSliceIndex == sliceIndex;

    if (sameRow && sameSlice) {
      emit(
        state.copyWith(
          clearScheduleSelection: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedScheduleRowIndex: rowIndex,
          selectedScheduleSliceIndex: sliceIndex,
        ),
      );
    }
  }

  void clearScheduleSelection() {
    emit(
      state.copyWith(
        clearScheduleSelection: true,
      ),
    );
  }

  void toggleContractSlice({
    required int sliceIndex,
  }) {
    final same = state.selectedContractSliceIndex == sliceIndex;

    if (same) {
      emit(
        state.copyWith(
          clearContractSlice: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedContractSliceIndex: sliceIndex,
        ),
      );
    }

    emit(
      state.copyWith(
        clearApostillesSlice: true,
      ),
    );
  }

  void clearContractSelection() {
    emit(
      state.copyWith(
        clearContractSlice: true,
      ),
    );
  }

  void toggleApostillesSlice({
    required int sliceIndex,
  }) {
    final same = state.selectedApostillesSliceIndex == sliceIndex;

    if (same) {
      emit(
        state.copyWith(
          clearApostillesSlice: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedApostillesSliceIndex: sliceIndex,
        ),
      );
    }

    emit(
      state.copyWith(
        clearContractSlice: true,
      ),
    );
  }

  void clearApostillesSelection() {
    emit(
      state.copyWith(
        clearApostillesSlice: true,
      ),
    );
  }

  void toggleResumeSlice({
    required int rowIndex,
    required int sliceIndex,
  }) {
    final sameRow = state.selectedResumeRowIndex == rowIndex;
    final sameSlice = state.selectedResumeSliceIndex == sliceIndex;

    if (sameRow && sameSlice) {
      emit(
        state.copyWith(
          clearLegacyResumeSelection: true,
        ),
      );

      emit(
        state.copyWith(
          clearContractSlice: true,
          clearApostillesSlice: true,
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        selectedResumeRowIndex: rowIndex,
        selectedResumeSliceIndex: sliceIndex,
      ),
    );

    if (sliceIndex <= 3) {
      emit(
        state.copyWith(
          selectedContractSliceIndex: sliceIndex,
          clearApostillesSlice: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedApostillesSliceIndex: sliceIndex - 4,
          clearContractSlice: true,
        ),
      );
    }
  }

  void clearResumeSelection() {
    emit(
      state.copyWith(
        clearLegacyResumeSelection: true,
      ),
    );

    emit(
      state.copyWith(
        clearContractSlice: true,
        clearApostillesSlice: true,
      ),
    );
  }
}