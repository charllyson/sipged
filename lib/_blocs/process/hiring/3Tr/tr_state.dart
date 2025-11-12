part of 'tr_bloc.dart';

class TrState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? trId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const TrState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.trId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory TrState.initial() => const TrState();

  bool get hasValidPath => trId != null && sectionIds.isNotEmpty;

  TrState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? trId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return TrState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      trId: trId ?? this.trId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalhos úteis
  String? get currentTrId => trId;
  String? get currentDocsId => sectionIds['documentosReferencias'];
}
