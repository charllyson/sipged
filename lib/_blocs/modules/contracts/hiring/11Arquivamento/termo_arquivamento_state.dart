// lib/_blocs/modules/contracts/hiring/10Arquivamento/termo_arquivamento_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/sections_types.dart';

import 'termo_arquivamento_sections.dart';

class TermoArquivamentoState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? taId;

  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const TermoArquivamentoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.taId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory TermoArquivamentoState.initial() {
    return const TermoArquivamentoState();
  }

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        taId != null &&
        taId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentContractId => contractId;
  String? get currentTaId => taId;
  String? get currentPecasDocId => sectionIds[TermoArquivamentoSections.pecas];

  TermoArquivamentoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? taId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearTaId = false,
  }) {
    return TermoArquivamentoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      taId: clearTaId ? null : (taId ?? this.taId),
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
    taId,
    sectionIds,
    sectionsData,
  ];
}