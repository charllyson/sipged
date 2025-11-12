part of 'habilitacao_bloc.dart';

class HabilitacaoState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? habId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const HabilitacaoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.habId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory HabilitacaoState.initial() => const HabilitacaoState();

  bool get hasValidPath => habId != null && sectionIds.isNotEmpty;

  HabilitacaoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? habId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return HabilitacaoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      habId: habId ?? this.habId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalhos úteis
  String? get currentHabId  => habId;
  String? get currentDocsId => sectionIds[HabilitacaoSections.licitacaoAdesao];
}
