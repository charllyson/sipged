// lib/_blocs/modules/contracts/hiring/5Edital/edital_state.dart

import 'package:equatable/equatable.dart';

import 'edital_data.dart';

class EditalState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? editalId;

  final Map<String, String> sectionIds;
  final Map<String, Map<String, dynamic>> sectionsData;

  const EditalState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.editalId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory EditalState.initial() => const EditalState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        editalId != null &&
        editalId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentEditalId => editalId;

  String? get currentDocsId {
    return sectionIds[EditalData.sectionDocumentos];
  }

  EditalState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? editalId,
    Map<String, String>? sectionIds,
    Map<String, Map<String, dynamic>>? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearEditalId = false,
  }) {
    return EditalState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      editalId: clearEditalId ? null : (editalId ?? this.editalId),
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
    editalId,
    sectionIds,
    sectionsData,
  ];
}