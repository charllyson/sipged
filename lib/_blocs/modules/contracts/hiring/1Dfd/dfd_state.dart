import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class DfdState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  /// id do contrato associado a este DFD
  final String? contractId;

  final String? dfdId;
  final SectionIds sectionIds;     // Map<String, String>
  final SectionsMap sectionsData;  // Map<String, Map<String, dynamic>>

  const DfdState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
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
    String? contractId,
    String? dfdId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return DfdState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      // comportamento: se não passar "error", limpa
      error: error,
      contractId: contractId ?? this.contractId,
      dfdId: dfdId ?? this.dfdId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  String? get currentDocsCheckId => sectionIds['documentos'];
}
