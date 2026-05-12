// lib/_blocs/modules/contracts/hiring/2Etp/etp_state.dart

import 'package:equatable/equatable.dart';

import 'etp_data.dart';

class EtpState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String tenantId;
  final String? contractId;
  final String? etpId;

  final Map<String, String> sectionIds;
  final Map<String, Map<String, dynamic>> sectionsData;

  const EtpState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    required this.tenantId,
    this.contractId,
    this.etpId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory EtpState.initial({
    required String tenantId,
  }) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para EtpState.');
    }

    return EtpState(
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
        etpId != null &&
        etpId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentEtpId => etpId;

  String? get currentDocsId {
    return sectionIds[EtpData.sectionDocumentos];
  }

  EtpState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? tenantId,
    String? contractId,
    String? etpId,
    Map<String, String>? sectionIds,
    Map<String, Map<String, dynamic>>? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearEtpId = false,
  }) {
    final cleanTenantId = (tenantId ?? this.tenantId).trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId não pode ficar vazio em EtpState.');
    }

    return EtpState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      tenantId: cleanTenantId,
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      etpId: clearEtpId ? null : (etpId ?? this.etpId),
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
    etpId,
    sectionIds,
    sectionsData,
  ];
}