// lib/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'minuta_contrato_sections.dart';

class MinutaState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? minutaId;

  final SectionIds sectionIds;
  final SectionsMap sectionsData;

  const MinutaState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.minutaId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory MinutaState.initial() => const MinutaState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        minutaId != null &&
        minutaId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentMinutaId => minutaId;
  String? get currentGestaoId => sectionIds[MinutaSections.gestaoRefs];

  MinutaState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? minutaId,
    SectionIds? sectionIds,
    SectionsMap? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearMinutaId = false,
  }) {
    return MinutaState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      minutaId: clearMinutaId ? null : (minutaId ?? this.minutaId),
      sectionIds: sectionIds ?? this.sectionIds,
      sectionsData: sectionsData ?? this.sectionsData,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loading,
    saving,
    saveSuccess,
    error,
    contractId,
    minutaId,
    sectionIds,
    sectionsData,
  ];
}