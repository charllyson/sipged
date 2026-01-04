// lib/_blocs/process/hiring/10Publicacao/publicacao_extrato_state.dart
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'publicacao_extrato_sections.dart';

class PublicacaoExtratoState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? pubId;
  final SectionIds sectionIds;     // Map<String, String>
  final SectionsMap sectionsData;  // Map<String, Map<String, dynamic>>

  const PublicacaoExtratoState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.pubId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory PublicacaoExtratoState.initial() => const PublicacaoExtratoState();

  bool get hasValidPath => pubId != null && sectionIds.isNotEmpty;

  PublicacaoExtratoState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? pubId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return PublicacaoExtratoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      // error sempre passado explicitamente (pode ser null para limpar)
      error: error,
      pubId: pubId ?? this.pubId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  /// Atalho para anexos na seção "veiculo"
  String? get currentVeiculoDocId =>
      sectionIds[PublicacaoExtratoSections.veiculo];
}
