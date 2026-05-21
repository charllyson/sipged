import 'package:equatable/equatable.dart';

class ProgressState extends Equatable {
  final bool loading;
  final bool approved;
  final bool completed;
  final String? error;

  final String tenantId;
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
    required this.tenantId,
    this.contractId,
    this.collectionName,
    this.completedByStage = const <String, bool>{},
    this.forceEnabledByStage = const <String, bool>{},
  });

  factory ProgressState.initial({
    required String tenantId,
  }) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para ProgressState.');
    }

    return ProgressState(
      tenantId: cleanTenantId,
    );
  }

  bool get hasValidTenant {
    return tenantId.trim().isNotEmpty;
  }

  bool get hasValidContract {
    return contractId != null && contractId!.trim().isNotEmpty;
  }

  bool get hasValidCollection {
    return collectionName != null && collectionName!.trim().isNotEmpty;
  }

  bool get isCurrentStageDone {
    return approved || completed;
  }

  ProgressState copyWith({
    bool? loading,
    bool? approved,
    bool? completed,
    String? error,
    String? tenantId,
    String? contractId,
    String? collectionName,
    Map<String, bool>? completedByStage,
    Map<String, bool>? forceEnabledByStage,
    bool clearError = false,
    bool clearContractId = false,
    bool clearCollectionName = false,
  }) {
    final cleanTenantId = (tenantId ?? this.tenantId).trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId não pode ficar vazio em ProgressState.');
    }

    return ProgressState(
      loading: loading ?? this.loading,
      approved: approved ?? this.approved,
      completed: completed ?? this.completed,
      error: clearError ? null : (error ?? this.error),
      tenantId: cleanTenantId,
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      collectionName:
      clearCollectionName ? null : (collectionName ?? this.collectionName),
      completedByStage: completedByStage ?? this.completedByStage,
      forceEnabledByStage: forceEnabledByStage ?? this.forceEnabledByStage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loading,
    approved,
    completed,
    error,
    tenantId,
    contractId,
    collectionName,
    completedByStage,
    forceEnabledByStage,
  ];
}