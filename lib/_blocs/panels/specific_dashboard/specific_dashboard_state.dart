import 'package:flutter/foundation.dart';

@immutable
class SpecificDashboardState {
  // =========================
  // LOADERS / ERROS
  // =========================
  final bool resumeLoading;
  final String? resumeError;

  // =========================
  // DFD
  // =========================
  final double dfdExtensaoKm;

  /// Label apenas para exibição.
  final String? dfdNaturezaIntervencao;

  /// ID estável vindo da lista/catálogo.
  /// Esse é o campo correto para calcular média e teto.
  final String? dfdNaturezaIntervencaoId;

  // =========================
  // BENCHMARKS
  // =========================
  final double benchmarkMediaCostPerKm;
  final double benchmarkTetoCostPerKm;

  // =========================
  // RESUMOS
  // =========================
  final List<double> contractValues;
  final List<double> apostillesValues;

  // =========================
  // SELEÇÕES
  // =========================
  final int? selectedContractSliceIndex;
  final int? selectedApostillesSliceIndex;

  final int? selectedScheduleRowIndex;
  final int? selectedScheduleSliceIndex;

  // =========================
  // LEGADO
  // =========================
  final List<double> resumeValues;
  final int? selectedResumeRowIndex;
  final int? selectedResumeSliceIndex;

  const SpecificDashboardState({
    this.resumeLoading = false,
    this.resumeError,
    this.dfdExtensaoKm = 0.0,
    this.dfdNaturezaIntervencao,
    this.dfdNaturezaIntervencaoId,
    this.benchmarkMediaCostPerKm = 0.0,
    this.benchmarkTetoCostPerKm = 0.0,
    this.contractValues = const <double>[0, 0, 0, 0],
    this.apostillesValues = const <double>[0, 0, 0],
    this.selectedContractSliceIndex,
    this.selectedApostillesSliceIndex,
    this.selectedScheduleRowIndex,
    this.selectedScheduleSliceIndex,
    this.resumeValues = const <double>[0, 0, 0, 0, 0, 0, 0],
    this.selectedResumeRowIndex,
    this.selectedResumeSliceIndex,
  });

  SpecificDashboardState copyWith({
    bool? resumeLoading,
    String? resumeError,
    double? dfdExtensaoKm,
    String? dfdNaturezaIntervencao,
    String? dfdNaturezaIntervencaoId,
    double? benchmarkMediaCostPerKm,
    double? benchmarkTetoCostPerKm,
    List<double>? contractValues,
    List<double>? apostillesValues,
    int? selectedContractSliceIndex,
    int? selectedApostillesSliceIndex,
    int? selectedScheduleRowIndex,
    int? selectedScheduleSliceIndex,
    List<double>? resumeValues,
    int? selectedResumeRowIndex,
    int? selectedResumeSliceIndex,
    bool clearResumeError = false,
    bool clearContractSlice = false,
    bool clearApostillesSlice = false,
    bool clearScheduleSelection = false,
    bool clearLegacyResumeSelection = false,
    bool clearDfdNaturezaIntervencao = false,
    bool clearDfdNaturezaIntervencaoId = false,
  }) {
    return SpecificDashboardState(
      resumeLoading: resumeLoading ?? this.resumeLoading,
      resumeError: clearResumeError ? null : (resumeError ?? this.resumeError),
      dfdExtensaoKm: dfdExtensaoKm ?? this.dfdExtensaoKm,
      dfdNaturezaIntervencao: clearDfdNaturezaIntervencao
          ? null
          : (dfdNaturezaIntervencao ?? this.dfdNaturezaIntervencao),
      dfdNaturezaIntervencaoId: clearDfdNaturezaIntervencaoId
          ? null
          : (dfdNaturezaIntervencaoId ?? this.dfdNaturezaIntervencaoId),
      benchmarkMediaCostPerKm:
      benchmarkMediaCostPerKm ?? this.benchmarkMediaCostPerKm,
      benchmarkTetoCostPerKm:
      benchmarkTetoCostPerKm ?? this.benchmarkTetoCostPerKm,
      contractValues: contractValues ?? this.contractValues,
      apostillesValues: apostillesValues ?? this.apostillesValues,
      selectedContractSliceIndex: clearContractSlice
          ? null
          : (selectedContractSliceIndex ?? this.selectedContractSliceIndex),
      selectedApostillesSliceIndex: clearApostillesSlice
          ? null
          : (selectedApostillesSliceIndex ?? this.selectedApostillesSliceIndex),
      selectedScheduleRowIndex: clearScheduleSelection
          ? null
          : (selectedScheduleRowIndex ?? this.selectedScheduleRowIndex),
      selectedScheduleSliceIndex: clearScheduleSelection
          ? null
          : (selectedScheduleSliceIndex ?? this.selectedScheduleSliceIndex),
      resumeValues: resumeValues ?? this.resumeValues,
      selectedResumeRowIndex: clearLegacyResumeSelection
          ? null
          : (selectedResumeRowIndex ?? this.selectedResumeRowIndex),
      selectedResumeSliceIndex: clearLegacyResumeSelection
          ? null
          : (selectedResumeSliceIndex ?? this.selectedResumeSliceIndex),
    );
  }
}