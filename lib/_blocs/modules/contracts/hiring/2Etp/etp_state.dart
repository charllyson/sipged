// lib/_blocs/modules/contracts/hiring/2Etp/etp_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class EtpState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? etpId;

  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const EtpState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.etpId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory EtpState.initial() => const EtpState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        etpId != null &&
        etpId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentEtpId => etpId;
  String? get currentDocsId => sectionIds['documentos'];

  EtpState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? etpId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearEtpId = false,
  }) {
    return EtpState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
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
    contractId,
    etpId,
    sectionIds,
    sectionsData,
  ];
}