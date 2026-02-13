import 'package:flutter/foundation.dart';

@immutable
class SpecificDashboardState {
  // =========================
  // LOADERS / ERROS
  // =========================
  final bool resumeLoading;
  final String? resumeError;

  // =========================
  // DFD (dados necessários para métricas)
  // =========================
  final double dfdExtensaoKm;
  final String? dfdNaturezaIntervencao;

  // =========================
  // BENCHMARKS (CUSTO/KM)
  // =========================
  /// Média ponderada por km (mesma natureza)
  final double benchmarkMediaCostPerKm;

  /// ✅ NOVO: Teto dinâmico = MAIOR custo/km entre contratos da mesma natureza
  final double benchmarkTetoCostPerKm;

  // =========================
  // RESUMOS (SEPARADOS)
  // =========================
  final List<double> contractValues;
  final List<double> apostillesValues;

  // =========================
  // SELEÇÕES (SEPARADAS)
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

    this.benchmarkMediaCostPerKm = 0.0,
    this.benchmarkTetoCostPerKm = 0.0, // ✅ novo

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

    double? benchmarkMediaCostPerKm,
    double? benchmarkTetoCostPerKm, // ✅ novo

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
  }) {
    return SpecificDashboardState(
      resumeLoading: resumeLoading ?? this.resumeLoading,
      resumeError: clearResumeError ? null : (resumeError ?? this.resumeError),

      dfdExtensaoKm: dfdExtensaoKm ?? this.dfdExtensaoKm,
      dfdNaturezaIntervencao:
      dfdNaturezaIntervencao ?? this.dfdNaturezaIntervencao,

      benchmarkMediaCostPerKm:
      benchmarkMediaCostPerKm ?? this.benchmarkMediaCostPerKm,
      benchmarkTetoCostPerKm:
      benchmarkTetoCostPerKm ?? this.benchmarkTetoCostPerKm, // ✅

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
