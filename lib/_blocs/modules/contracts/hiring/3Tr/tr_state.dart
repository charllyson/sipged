// lib/_blocs/modules/contracts/hiring/3Tr/tr_state.dart

import 'package:equatable/equatable.dart';

import 'tr_data.dart';

class TrState extends Equatable {
  final bool loading;
  final bool saving;
  final bool saveSuccess;
  final String? error;

  final String? contractId;
  final String? trId;

  final Map<String, String> sectionIds;
  final Map<String, Map<String, dynamic>> sectionsData;

  const TrState({
    this.loading = false,
    this.saving = false,
    this.saveSuccess = false,
    this.error,
    this.contractId,
    this.trId,
    this.sectionIds = const <String, String>{},
    this.sectionsData = const <String, Map<String, dynamic>>{},
  });

  factory TrState.initial() => const TrState();

  bool get hasValidPath {
    return contractId != null &&
        contractId!.trim().isNotEmpty &&
        trId != null &&
        trId!.trim().isNotEmpty &&
        sectionIds.isNotEmpty;
  }

  String? get currentTrId => trId;

  String? get currentDocsId {
    return sectionIds[TrData.sectionDocumentosReferencias];
  }

  TrState copyWith({
    bool? loading,
    bool? saving,
    bool? saveSuccess,
    String? error,
    String? contractId,
    String? trId,
    Map<String, String>? sectionIds,
    Map<String, Map<String, dynamic>>? sectionsData,
    bool clearError = false,
    bool clearContractId = false,
    bool clearTrId = false,
  }) {
    return TrState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      trId: clearTrId ? null : (trId ?? this.trId),
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
    trId,
    sectionIds,
    sectionsData,
  ];
}