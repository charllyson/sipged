// lib/_blocs/modules/contracts/hiring/7Dotacao/dotacao_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/sections_types.dart';

import 'dotacao_sections.dart';

class DotacaoState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? dotacaoId;

  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const DotacaoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.dotacaoId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory DotacaoState.initial() => const DotacaoState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        dotacaoId != null &&
        dotacaoId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentDotacaoId => dotacaoId;
  String? get currentDocsId => sectionIds[DotacaoSections.documentos];

  DotacaoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? dotacaoId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearDotacaoId = false,
  }) {
    return DotacaoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      dotacaoId: clearDotacaoId ? null : (dotacaoId ?? this.dotacaoId),
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
    dotacaoId,
    sectionIds,
    sectionsData,
  ];
}