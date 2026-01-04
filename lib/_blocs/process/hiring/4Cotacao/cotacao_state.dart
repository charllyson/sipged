// lib/_blocs/process/hiring/3Cotacao/cotacao_state.dart
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

class CotacaoState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? cotacaoId;
  final SectionIds sectionIds;    // Map<String, String>
  final SectionsMap sectionsData; // Map<String, Map<String, dynamic>>

  const CotacaoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.cotacaoId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory CotacaoState.initial() => const CotacaoState();

  bool get hasValidPath => cotacaoId != null && sectionIds.isNotEmpty;

  CotacaoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? cotacaoId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return CotacaoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      cotacaoId: cotacaoId ?? this.cotacaoId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalhos úteis
  String? get currentCotacaoId => cotacaoId;
  String? get currentDocsId    => sectionIds['anexosEvidencias'];
}
