// lib/_blocs/process/hiring/10Arquivamento/termo_arquivamento_state.dart

import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

class TermoArquivamentoState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? taId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const TermoArquivamentoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.taId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory TermoArquivamentoState.initial() =>
      const TermoArquivamentoState();

  bool get hasValidPath => taId != null && sectionIds.isNotEmpty;

  TermoArquivamentoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? taId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return TermoArquivamentoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      taId: taId ?? this.taId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }
}
