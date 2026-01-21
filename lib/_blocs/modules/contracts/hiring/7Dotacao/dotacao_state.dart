// lib/_blocs/modules/contracts/hiring/7Dotacao/dotacao_state.dart
import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';
import 'dotacao_sections.dart';

class DotacaoState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? dotacaoId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const DotacaoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.dotacaoId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory DotacaoState.initial() => const DotacaoState();

  bool get hasValidPath => dotacaoId != null && sectionIds.isNotEmpty;

  DotacaoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? dotacaoId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return DotacaoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      dotacaoId: dotacaoId ?? this.dotacaoId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalhos
  String? get currentDotacaoId => dotacaoId;
  String? get currentDocsId    => sectionIds[DotacaoSections.documentos];
}
