// lib/_blocs/modules/financial/payments/report_paid_state.dart

import 'package:equatable/equatable.dart';

import 'report_paid_data.dart';

enum ReportPaidStatus {
  initial,
  loading,
  success,
  failure,
}

class ReportPaidState extends Equatable {
  const ReportPaidState({
    this.status = ReportPaidStatus.initial,
    this.payments = const <ReportPaidData>[],
    this.selected,
    this.error,
    this.contractId,
    this.measurementId,
    this.selectedSideIndex,
    this.uploading = false,
    this.uploadProgress,
  });

  final ReportPaidStatus status;
  final List<ReportPaidData> payments;
  final ReportPaidData? selected;
  final String? error;

  final String? contractId;
  final String? measurementId;

  final int? selectedSideIndex;

  final bool uploading;
  final double? uploadProgress;

  factory ReportPaidState.initial() {
    return const ReportPaidState();
  }

  ReportPaidState copyWith({
    ReportPaidStatus? status,
    List<ReportPaidData>? payments,
    ReportPaidData? selected,
    bool clearSelected = false,
    String? error,
    bool clearError = false,
    String? contractId,
    String? measurementId,
    int? selectedSideIndex,
    bool clearSelectedSideIndex = false,
    bool? uploading,
    double? uploadProgress,
    bool clearUploadProgress = false,
  }) {
    return ReportPaidState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      selected: clearSelected ? null : selected ?? this.selected,
      error: clearError ? null : error ?? this.error,
      contractId: contractId ?? this.contractId,
      measurementId: measurementId ?? this.measurementId,
      selectedSideIndex:
      clearSelectedSideIndex ? null : selectedSideIndex ?? this.selectedSideIndex,
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
      measurementId,
      selectedSideIndex,
      uploading,
      uploadProgress,
    ];
  }
}