// lib/_blocs/modules/contracts/hiring/2Etp/etp_state.dart
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class EtpState {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? etpId;
  final SectionIds sectionIds;     // Map<String, String>
  final SectionsMap sectionsData;  // Map<String, Map<String, dynamic>>

  const EtpState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.etpId,
    this.sectionIds = const {},
    this.sectionsData = const {},
  });

  factory EtpState.initial() => const EtpState();

  bool get hasValidPath => etpId != null && sectionIds.isNotEmpty;

  EtpState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? etpId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
  }) {
    return EtpState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: error,
      etpId: etpId ?? this.etpId,
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  // atalhos (se quiser manter)
  String? get currentEtpId => etpId;
  String? get currentDocsId => sectionIds['documentos'];
}
