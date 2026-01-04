// lib/_blocs/process/hiring/9Juridico/parecer_juridico_state.dart

import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'parecer_juridico_sections.dart';

class ParecerState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? parecerId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const ParecerState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.parecerId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory ParecerState.initial() => const ParecerState();

  bool get hasValidPath => parecerId != null && sectionIds.isNotEmpty;

  ParecerState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? parecerId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return ParecerState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      parecerId: parecerId ?? this.parecerId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  /// Atalho para docId da seção de anexos
  String? get currentDocsId => sectionIds[ParecerSections.documentos];
}
