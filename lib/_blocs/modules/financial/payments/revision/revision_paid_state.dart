import 'package:equatable/equatable.dart';

import 'revision_paid_data.dart';

enum RevisionPaidStatus {
  initial,
  loading,
  success,
  failure,
}

class RevisionPaidState extends Equatable {
  const RevisionPaidState({
    this.status = RevisionPaidStatus.initial,
    this.payments = const <RevisionPaidData>[],
    this.selected,
    this.error,
    this.contractId,
    this.revisionId,
    this.selectedSideIndex,
    this.uploading = false,
    this.uploadProgress,
  });

  final RevisionPaidStatus status;
  final List<RevisionPaidData> payments;
  final RevisionPaidData? selected;
  final String? error;

  final String? contractId;
  final String? revisionId;

  final int? selectedSideIndex;

  final bool uploading;
  final double? uploadProgress;

  factory RevisionPaidState.initial() {
    return const RevisionPaidState();
  }

  RevisionPaidState copyWith({
    RevisionPaidStatus? status,
    List<RevisionPaidData>? payments,
    RevisionPaidData? selected,
    bool clearSelected = false,
    String? error,
    bool clearError = false,
    String? contractId,
    String? revisionId,
    int? selectedSideIndex,
    bool clearSelectedSideIndex = false,
    bool? uploading,
    double? uploadProgress,
    bool clearUploadProgress = false,
  }) {
    return RevisionPaidState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      selected: clearSelected ? null : selected ?? this.selected,
      error: clearError ? null : error ?? this.error,
      contractId: contractId ?? this.contractId,
      revisionId: revisionId ?? this.revisionId,
      selectedSideIndex: clearSelectedSideIndex
          ? null
          : selectedSideIndex ?? this.selectedSideIndex,
      uploading: uploading ?? this.uploading,
      uploadProgress:
      clearUploadProgress ? null : uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props {
    return [
      status,
      payments,
      selected,
      error,
      contractId,
      revisionId,
      selectedSideIndex,
      uploading,
      uploadProgress,
    ];
  }
}