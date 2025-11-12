part of 'termo_arquivamento_bloc.dart';

class TermoArquivamentoState {
  final bool loading;
  final bool saving;
  final String? error;

  final String? taId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  final bool saveSuccess;

  bool get hasValidPath => taId != null && sectionIds.isNotEmpty;

  const TermoArquivamentoState({
    required this.loading,
    required this.saving,
    required this.error,
    required this.taId,
    required this.sectionIds,
    required this.sectionsData,
    required this.saveSuccess,
  });

  factory TermoArquivamentoState.initial() => const TermoArquivamentoState(
    loading: false,
    saving: false,
    error: null,
    taId: null,
    sectionIds: {},
    sectionsData: {},
    saveSuccess: false,
  );

  TermoArquivamentoState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    String? taId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool? saveSuccess,
  }) {
    return TermoArquivamentoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error,
      taId: taId ?? this.taId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}
