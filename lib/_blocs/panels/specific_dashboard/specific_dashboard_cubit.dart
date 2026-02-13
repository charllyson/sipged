import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

import 'specific_dashboard_state.dart';

class SpecificDashboardCubit extends Cubit<SpecificDashboardState> {
  final DfdRepository dfdRepository;
  final AdditivesRepository additivesRepository;
  final ApostillesRepository apostillesRepository;

  final ReportMeasurementRepository reportRepository;
  final AdjustmentMeasurementRepository adjustmentRepository;
  final RevisionMeasurementRepository revisionRepository;

  SpecificDashboardCubit({
    required this.dfdRepository,
    required this.additivesRepository,
    required this.apostillesRepository,
    required this.reportRepository,
    required this.adjustmentRepository,
    required this.revisionRepository,
  }) : super(const SpecificDashboardState());

  Future<void> loadForContract(String contractId) async {
    final id = contractId.trim();
    if (id.isEmpty) return;

    emit(state.copyWith(resumeLoading: true, resumeError: null));

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

      final double totalAditivos = (results[1] as double?) ?? 0.0;
      final double totalApostilamentos = (results[2] as double?) ?? 0.0;

      final reportList = (results[3] as List);
      final adjustmentList = (results[4] as List);
      final revisionList = (results[5] as List);

      final double valorContratado =
      (dfd?.valorDemanda ?? dfd?.estimativaValor ?? 0).toDouble();

      final double extensaoKm = (dfd?.extensaoKm ?? 0).toDouble();

      final String? natureza = (dfd?.naturezaIntervencao ?? '').trim().isEmpty
          ? null
          : dfd!.naturezaIntervencao!.trim();

      final double totalMedicoes =
      reportRepository.somarValorMedicoes(reportList.cast());

      final double totalAdjustments =
      adjustmentRepository.sumAdjustments(adjustmentList.cast());

      final double totalRevisions =
      revisionRepository.sumRevisions(revisionList.cast());

      final double totalReajustesERevisoes = totalAdjustments + totalRevisions;

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

      // ✅ Benchmarks (MÉDIA + TETO)
      // Regra coerente com a UI do "Atual":
      // - Atual = (valorContratado + aditivos + apostilas) / km  -> CONTRATADO/KM
      // - Média ponderada = sum(totalContratado) / sum(km)
      // - Teto = max(totalContratado/km) dentre contratos da mesma natureza
      double benchmarkMedia = 0.0;
      double benchmarkTeto = 0.0;

      if ((natureza ?? '').trim().isNotEmpty) {
        final stats = await _computeBenchmarkStatsContratado(natureza!.trim());
        benchmarkMedia = stats.mediaPonderada;
        benchmarkTeto = stats.tetoMax;
      }

      emit(
        state.copyWith(
          resumeLoading: false,
          dfdExtensaoKm: extensaoKm,
          dfdNaturezaIntervencao: natureza,
          benchmarkMediaCostPerKm: benchmarkMedia,
          benchmarkTetoCostPerKm: benchmarkTeto,
          contractValues: contractValues,
          apostillesValues: apostillesValues,
          resumeValues: resumeValuesLegacy,
        ),
      );
    } catch (e) {
      emit(state.copyWith(resumeLoading: false, resumeError: e.toString()));
    }
  }

  // ===========================================================
  // ✅ Benchmark (Média ponderada + Teto) — CONTRATADO/KM
  // ===========================================================
  Future<({double mediaPonderada, double tetoMax})> _computeBenchmarkStatsContratado(
      String natureza,
      ) async {
    final sw = Stopwatch()..start();

    if (kDebugMode) {
      debugPrint('[BenchmarkStats] START natureza="$natureza" (CONTRATADO)');
    }

    // seeds: contratos que têm localizacao com natureza exata + km direto do doc
    final seeds =
    await dfdRepository.listBenchmarkSeedsByNaturezaIntervencao(natureza);

    if (seeds.isEmpty) {
      if (kDebugMode) debugPrint('[BenchmarkStats] EMPTY seeds');
      return (mediaPonderada: 0.0, tetoMax: 0.0);
    }

    double sumValor = 0.0; // para média ponderada
    double sumKm = 0.0;

    double tetoMax = 0.0; // teto = maior custo/km (por contrato)

    // Performance:
    // - batchSize moderado (evita saturar Firestore / navegador no Web)
    // - dentro do contrato, lê em paralelo base/aditivos/apostilas
    const int batchSize = 12;

    int ok = 0;
    int skipKmZero = 0;
    int err = 0;

    for (int i = 0; i < seeds.length; i += batchSize) {
      final batch = seeds.sublist(i, math.min(i + batchSize, seeds.length));

      final futures = batch.map((seed) async {
        try {
          final contractId = seed.contractId;
          final km = seed.km;

          if (km <= 0) return (ok: false, km: 0.0, total: 0.0);

          // ✅ TOTAL CONTRATADO:
          // base (valorDemanda/estimativa) + aditivos + apostilas
          final parts = await Future.wait<double>([
            dfdRepository.readBaseValueForContract(contractId),
            additivesRepository.getAllAdditivesValue(contractId),
            apostillesRepository.getAllApostillesValue(contractId),
          ]);

          final base = parts[0];
          final aditivos = parts[1];
          final apostilas = parts[2];

          final total = (base + aditivos + apostilas).clamp(0.0, double.infinity);

          return (ok: true, km: km, total: total);
        } catch (_) {
          return (ok: false, km: 0.0, total: 0.0);
        }
      }).toList();

      final results = await Future.wait(futures);

      for (final r in results) {
        if (!r.ok) {
          err += 1;
          continue;
        }

        if (r.km <= 0) {
          skipKmZero += 1;
          continue;
        }

        ok += 1;

        // ✅ média ponderada (somatório / somatório km)
        sumValor += r.total;
        sumKm += r.km;

        // ✅ teto = max(custoPorKmContrato)
        final custoPorKmContrato = r.total / r.km;
        if (custoPorKmContrato > tetoMax) tetoMax = custoPorKmContrato;
      }

      if (kDebugMode) {
        debugPrint(
          '[BenchmarkStats] batch ${(i ~/ batchSize) + 1} '
              'sumKm=${sumKm.toStringAsFixed(2)} tetoMax=${tetoMax.toStringAsFixed(2)}',
        );
      }
    }

    final mediaPonderada = (sumKm > 0) ? (sumValor / sumKm) : 0.0;

    sw.stop();
    if (kDebugMode) {
      debugPrint(
        '[BenchmarkStats] DONE natureza="$natureza" (CONTRATADO) seeds=${seeds.length} '
            'ok=$ok skipKmZero=$skipKmZero err=$err '
            'sumValor=${sumValor.toStringAsFixed(2)} sumKm=${sumKm.toStringAsFixed(2)} '
            'media=${mediaPonderada.toStringAsFixed(2)} teto=${tetoMax.toStringAsFixed(2)} '
            'elapsed=${sw.elapsedMilliseconds}ms',
      );
    }

    return (mediaPonderada: mediaPonderada, tetoMax: tetoMax);
  }

  // ===========================================================
  // restante (toggle/clear) — mantém igual
  // ===========================================================

  void toggleScheduleSlice({required int rowIndex, required int sliceIndex}) {
    final sameRow = state.selectedScheduleRowIndex == rowIndex;
    final sameSlice = state.selectedScheduleSliceIndex == sliceIndex;

    if (sameRow && sameSlice) {
      emit(state.copyWith(clearScheduleSelection: true));
    } else {
      emit(state.copyWith(
        selectedScheduleRowIndex: rowIndex,
        selectedScheduleSliceIndex: sliceIndex,
      ));
    }
  }

  void clearScheduleSelection() {
    emit(state.copyWith(clearScheduleSelection: true));
  }

  void toggleContractSlice({required int sliceIndex}) {
    final same = state.selectedContractSliceIndex == sliceIndex;
    if (same) {
      emit(state.copyWith(clearContractSlice: true));
    } else {
      emit(state.copyWith(selectedContractSliceIndex: sliceIndex));
    }
    emit(state.copyWith(clearApostillesSlice: true));
  }

  void clearContractSelection() {
    emit(state.copyWith(clearContractSlice: true));
  }

  void toggleApostillesSlice({required int sliceIndex}) {
    final same = state.selectedApostillesSliceIndex == sliceIndex;
    if (same) {
      emit(state.copyWith(clearApostillesSlice: true));
    } else {
      emit(state.copyWith(selectedApostillesSliceIndex: sliceIndex));
    }
    emit(state.copyWith(clearContractSlice: true));
  }

  void clearApostillesSelection() {
    emit(state.copyWith(clearApostillesSlice: true));
  }

  void toggleResumeSlice({required int rowIndex, required int sliceIndex}) {
    final sameRow = state.selectedResumeRowIndex == rowIndex;
    final sameSlice = state.selectedResumeSliceIndex == sliceIndex;

    if (sameRow && sameSlice) {
      emit(state.copyWith(clearLegacyResumeSelection: true));
      emit(state.copyWith(clearContractSlice: true, clearApostillesSlice: true));
      return;
    }

    emit(state.copyWith(
      selectedResumeRowIndex: rowIndex,
      selectedResumeSliceIndex: sliceIndex,
    ));

    if (sliceIndex <= 3) {
      emit(state.copyWith(
        selectedContractSliceIndex: sliceIndex,
        clearApostillesSlice: true,
      ));
    } else {
      emit(state.copyWith(
        selectedApostillesSliceIndex: sliceIndex - 4,
        clearContractSlice: true,
      ));
    }
  }

  void clearResumeSelection() {
    emit(state.copyWith(clearLegacyResumeSelection: true));
    emit(state.copyWith(clearContractSlice: true, clearApostillesSlice: true));
  }
}
