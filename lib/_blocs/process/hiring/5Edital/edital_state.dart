// lib/_blocs/process/hiring/5Edital/edital_state.dart
part of 'edital_bloc.dart';

class EditalState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? editalId;
  final SectionIds sectionIds;     // Map<String, String>
  final SectionsMap sectionsData;  // Map<String, Map<String, dynamic>>

  const EditalState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.editalId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory EditalState.initial() => const EditalState();

  bool get hasValidPath => editalId != null && sectionIds.isNotEmpty;

  EditalState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? editalId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return EditalState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      editalId: editalId ?? this.editalId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalhos
  String? get currentEditalId => editalId;
  String? get currentDocsId => sectionIds[EditalSections.documentos];
}
