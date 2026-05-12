// lib/_blocs/modules/contracts/hiring/0Stages/progress_state.dart

import 'package:equatable/equatable.dart';

class ProgressState extends Equatable {
  final bool loading;
  final bool approved;
  final bool completed;
  final String? error;

  final String? contractId;
  final String? collectionName;

  /// stageKey -> approved || completed
  final Map<String, bool> completedByStage;

  /// Liberação manual de etapas.
  final Map<String, bool> forceEnabledByStage;

  const ProgressState({
    this.loading = false,
    this.approved = false,
    this.completed = false,
    this.error,
    this.contractId,
    this.collectionName,
    this.completedByStage = const <String, bool>{},
    this.forceEnabledByStage = const <String, bool>{},
  });

  factory ProgressState.initial() => const ProgressState();

  bool get isCurrentStageDone => approved || completed;

  ProgressState copyWith({
    bool? loading,
    bool? approved,
    bool? completed,
    String? error,
    String? contractId,
    String? collectionName,
    Map<String, bool>? completedByStage,
    Map<String, bool>? forceEnabledByStage,
    bool clearError = false,
    bool clearContractId = false,
    bool clearCollectionName = false,
  }) {
    return ProgressState(
      loading: loading ?? this.loading,
      approved: approved ?? this.approved,
      completed: completed ?? this.completed,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      collectionName: clearCollectionName
          ? null
          : (collectionName ?? this.collectionName),
      completedByStage: completedByStage ?? this.completedByStage,
      forceEnabledByStage:
      forceEnabledByStage ?? this.forceEnabledByStage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loading,
    approved,
    completed,
    error,
    contractId,
    collectionName,
    completedByStage,
    forceEnabledByStage,
  ];
}