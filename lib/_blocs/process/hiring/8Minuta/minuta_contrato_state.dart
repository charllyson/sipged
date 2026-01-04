// lib/_blocs/process/hiring/8Minuta/minuta_contrato_state.dart

import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'minuta_contrato_sections.dart';

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

  // atalhos
  String? get currentMinutaId => minutaId;
  String? get currentGestaoId => sectionIds[MinutaSections.gestaoRefs];
}
