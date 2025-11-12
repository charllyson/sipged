// lib/_blocs/process/hiring/1Dfd/dfd_state.dart
part of 'dfd_bloc.dart';

class DfdState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? dfdId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const DfdState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.dfdId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory DfdState.initial() => const DfdState();

  bool get hasValidPath => dfdId != null && sectionIds.isNotEmpty;

  DfdState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? dfdId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return DfdState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      dfdId: dfdId ?? this.dfdId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalho útil quando precisar de anexos da seção 'documentos'
  String? get currentDocsCheckId => sectionIds['documentos'];
}
