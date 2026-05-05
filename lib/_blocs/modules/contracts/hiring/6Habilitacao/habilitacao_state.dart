// lib/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'habilitacao_sections.dart';

class HabilitacaoState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? habId;

  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const HabilitacaoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.habId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory HabilitacaoState.initial() => const HabilitacaoState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        habId != null &&
        habId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentHabId => habId;
  String? get currentDocsId => sectionIds[HabilitacaoSections.licitacaoAdesao];

  HabilitacaoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? habId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearHabId = false,
  }) {
    return HabilitacaoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      habId: clearHabId ? null : (habId ?? this.habId),
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
    habId,
    sectionIds,
    sectionsData,
  ];
}