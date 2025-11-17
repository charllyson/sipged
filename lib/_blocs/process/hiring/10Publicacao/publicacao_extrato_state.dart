// lib/_blocs/process/hiring/10Publicacao/publicacao_extrato_state.dart

part of 'publicacao_extrato_bloc.dart';

class PublicacaoExtratoState {
  final bool loading;
  final bool saving;
  final String? error;

  final String? pubId;
  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  final bool saveSuccess;

  bool get hasValidPath => pubId != null && sectionIds.isNotEmpty;

  const PublicacaoExtratoState({
    required this.loading,
    required this.saving,
    required this.error,
    required this.pubId,
    required this.sectionIds,
    required this.sectionsData,
    required this.saveSuccess,
  });

  factory PublicacaoExtratoState.initial() =>
      const PublicacaoExtratoState(
        loading: false,
        saving: false,
        error: null,
        pubId: null,
        sectionIds: {},
        sectionsData: {},
        saveSuccess: false,
      );

  PublicacaoExtratoState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    String? pubId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool? saveSuccess,
  }) {
    return PublicacaoExtratoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      // passa error explicitamente (pode ser null para limpar)
      error: error,
      pubId: pubId ?? this.pubId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }

  /// atalho para anexos na seção "veiculo"
  String? get currentVeiculoDocId =>
      sectionIds[PublicacaoExtratoSections.veiculo];
}
