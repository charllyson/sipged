// lib/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_state.dart

import 'package:equatable/equatable.dart';

import 'publicacao_extrato_data.dart';

class PublicacaoExtratoState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? pubId;

  final Map<String, String> sectionIds;
  final Map<String, Map<String, dynamic>> sectionsData;

  const PublicacaoExtratoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.pubId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory PublicacaoExtratoState.initial() {
    return const PublicacaoExtratoState();
  }

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        pubId != null &&
        pubId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentPubId => pubId;

  String? get currentVeiculoDocId {
    return sectionIds[PublicacaoExtratoData.sectionVeiculo];
  }

  PublicacaoExtratoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? pubId,
    Map<String, String>? sectionIds,
    Map<String, Map<String, dynamic>>? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearPubId = false,
  }) {
    return PublicacaoExtratoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      pubId: clearPubId ? null : (pubId ?? this.pubId),
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
    pubId,
    sectionIds,
    sectionsData,
  ];
}