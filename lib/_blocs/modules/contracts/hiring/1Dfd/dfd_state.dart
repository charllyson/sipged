// lib/_blocs/modules/contracts/hiring/1Dfd/dfd_state.dart

import 'package:equatable/equatable.dart';

import 'dfd_data.dart';

class DfdState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String tenantId;
  final String? contractId;
  final String? dfdId;

  final Map<String, String> sectionIds;
  final Map<String, Map<String, dynamic>> sectionsData;

  const DfdState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    required this.tenantId,
    this.contractId,
    this.dfdId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory DfdState.initial({
    required String tenantId,
  }) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para DfdState.');
    }

    return DfdState(
      tenantId: cleanTenantId,
    );
  }

  bool get hasValidTenant {
    return tenantId.trim().isNotEmpty;
  }

  bool get hasValidPath {
    return tenantId.trim().isNotEmpty &&
        contractId != null &&
        contractId!.trim().isNotEmpty &&
        dfdId != null &&
        dfdId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentDocsCheckId {
    return sectionIds[DfdData.sectionDocumentos];
  }

  DfdState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? tenantId,
    String? contractId,
    String? dfdId,
    Map<String, String>? sectionIds,
    Map<String, Map<String, dynamic>>? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearDfdId = false,
  }) {
    final cleanTenantId = (tenantId ?? this.tenantId).trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId não pode ficar vazio em DfdState.');
    }

    return DfdState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      tenantId: cleanTenantId,
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      dfdId: clearDfdId ? null : (dfdId ?? this.dfdId),
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loading,
    saving,
    saveSuccess,
    error,
    tenantId,
    contractId,
    dfdId,
    sectionIds,
    sectionsData,
  ];
}