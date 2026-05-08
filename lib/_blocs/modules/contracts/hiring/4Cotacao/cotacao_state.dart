// lib/_blocs/modules/contracts/hiring/4Cotacao/cotacao_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/sections_types.dart';

class CotacaoState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? cotacaoId;

  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const CotacaoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.cotacaoId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory CotacaoState.initial() => const CotacaoState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        cotacaoId != null &&
        cotacaoId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentCotacaoId => cotacaoId;
  String? get currentDocsId => sectionIds['anexosEvidencias'];

  CotacaoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? cotacaoId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearCotacaoId = false,
  }) {
    return CotacaoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      cotacaoId: clearCotacaoId ? null : (cotacaoId ?? this.cotacaoId),
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
    cotacaoId,
    sectionIds,
    sectionsData,
  ];
}