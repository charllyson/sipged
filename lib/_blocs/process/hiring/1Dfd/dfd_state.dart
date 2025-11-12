part of 'dfd_bloc.dart';

class DfdState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? dfdId;
  final SectionIds sectionIds; // Map<String, String>
  final SectionsMap sectionsData; // Map<String, Map<String, dynamic>>

  // Leves para UI
  final String? workType;       // objeto.tipoObra
  final double? extensaoKm;     // localizacao.extensaoKm
  final String? contractStatus; // identificacao.statusContrato

  const DfdState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.dfdId,
    this.sectionIds = const {},
    this.sectionsData = const {},
    this.workType,
    this.extensaoKm,
    this.contractStatus,
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
    String? workType,
    double? extensaoKm,
    String? contractStatus,
  }) {
    return DfdState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      dfdId: dfdId ?? this.dfdId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
      workType: workType ?? this.workType,
      extensaoKm: extensaoKm ?? this.extensaoKm,
      contractStatus: contractStatus ?? this.contractStatus,
    );
  }

  String? get currentDocsCheckId => sectionIds['documentos'];
}
