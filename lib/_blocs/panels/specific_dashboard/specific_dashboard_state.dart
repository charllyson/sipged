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
  /// Extensão do contrato (km) vinda do DFD
  final double dfdExtensaoKm;

  /// ✅ Natureza da intervenção (DFD.localizacao.naturezaIntervencao)
  final String? dfdNaturezaIntervencao;

  // =========================
  // RESUMOS (SEPARADOS)
  // =========================
  /// Contrato + Aditivos (4 valores):
  /// [valorContratado, valorAditivos, totalMedicoes, saldoContrato]
  final List<double> contractValues;

  /// Apostilamentos (3 valores):
  /// [totalApostilamentos, totalReajustesRevisoes, saldoApostilamentos]
  final List<double> apostillesValues;

  // =========================
  // SELEÇÕES (SEPARADAS)
  // =========================
  final int? selectedContractSliceIndex;
  final int? selectedApostillesSliceIndex;

  /// Acompanhamento físico: linha selecionada (0=GERAL, 1..N=serviços)
  final int? selectedScheduleRowIndex;

  /// Acompanhamento físico: slice selecionado (0..2)
  final int? selectedScheduleSliceIndex;

  // =========================
  // LEGADO (para não quebrar outros widgets antigos que ainda usem)
  // =========================
  /// 7 valores:
  /// [valorContratado, aditivos, medicoes, saldoContrato, apostilamentos, reajustes+revisoes, saldoApostilamentos]
  final List<double> resumeValues;
  final int? selectedResumeRowIndex;
  final int? selectedResumeSliceIndex;

  const SpecificDashboardState({
    this.resumeLoading = false,
    this.resumeError,
    this.dfdExtensaoKm = 0.0,
    this.dfdNaturezaIntervencao, // ✅
    this.contractValues = const <double>[0, 0, 0, 0],
    this.apostillesValues = const <double>[0, 0, 0],
    this.selectedContractSliceIndex,
    this.selectedApostillesSliceIndex,
    this.selectedScheduleRowIndex,
    this.selectedScheduleSliceIndex,
    // legado
    this.resumeValues = const <double>[0, 0, 0, 0, 0, 0, 0],
    this.selectedResumeRowIndex,
    this.selectedResumeSliceIndex,
  });

  SpecificDashboardState copyWith({
    bool? resumeLoading,
    String? resumeError,

    double? dfdExtensaoKm,
    String? dfdNaturezaIntervencao,

    List<double>? contractValues,
    List<double>? apostillesValues,

    int? selectedContractSliceIndex,
    int? selectedApostillesSliceIndex,

    int? selectedScheduleRowIndex,
    int? selectedScheduleSliceIndex,

    // legado
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
      dfdNaturezaIntervencao ?? this.dfdNaturezaIntervencao, // ✅

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

      // legado
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
