part of 'minuta_contrato_bloc.dart';

class MinutaState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? minutaId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const MinutaState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.minutaId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory MinutaState.initial() => const MinutaState();

  bool get hasValidPath => minutaId != null && sectionIds.isNotEmpty;

  MinutaState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? minutaId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return MinutaState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      minutaId: minutaId ?? this.minutaId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  /// Atalho para docId da seção que guarda anexos/links (gestão/refs)
  String? get currentGestaoId => sectionIds[MinutaSections.gestaoRefs];
}
