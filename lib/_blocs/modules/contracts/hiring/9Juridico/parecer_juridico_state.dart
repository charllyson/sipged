// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_state.dart

import 'package:equatable/equatable.dart';

import 'parecer_juridico_data.dart';

class ParecerState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? parecerId;

  final Map<String, String> sectionIds;
  final Map<String, Map<String, dynamic>> sectionsData;

  const ParecerState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.parecerId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory ParecerState.initial() => const ParecerState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        parecerId != null &&
        parecerId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentParecerId => parecerId;

  String? get currentDocsId {
    return sectionIds[ParecerJuridicoData.sectionDocumentos];
  }

  ParecerState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? parecerId,
    Map<String, String>? sectionIds,
    Map<String, Map<String, dynamic>>? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearParecerId = false,
  }) {
    return ParecerState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      parecerId: clearParecerId ? null : (parecerId ?? this.parecerId),
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
    parecerId,
    sectionIds,
    sectionsData,
  ];
}