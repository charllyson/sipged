// lib/_blocs/modules/contracts/hiring/2Tr/tr_state.dart
import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class TrState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? trId;
  final SectionIds sectionIds;    // Map<String, String>
  final SectionsMap sectionsData; // Map<String, Map<String, dynamic>>

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

  /// Atalho: id da seção de documentos / referências
  String? get currentDocsId => sectionIds['documentosReferencias'];
}
