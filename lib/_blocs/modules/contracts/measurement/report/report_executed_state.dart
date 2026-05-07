// lib/_blocs/modules/contracts/measurement/report/report_executed_state.dart

import 'package:equatable/equatable.dart';
import 'report_executed_data.dart';

enum ReportExecutedStatus {
  initial,
  loading,
  success,
  failure,
}

class ReportExecutedState extends Equatable {
  const ReportExecutedState({
    this.status = ReportExecutedStatus.initial,
    this.measurements = const <ReportExecutedData>[],
    this.error,
    this.contractId,
    this.uploading = false,
    this.uploadProgress,
  });

  final ReportExecutedStatus status;

  final List<ReportExecutedData> measurements;

  final String? error;

  final String? contractId;

  final bool uploading;
  final double? uploadProgress;

  factory ReportExecutedState.initial() {
    return const ReportExecutedState(
      status: ReportExecutedStatus.initial,
      measurements: <ReportExecutedData>[],
      error: null,
      contractId: null,
      uploading: false,
      uploadProgress: null,
    );
  }

  ReportExecutedState copyWith({
    ReportExecutedStatus? status,
    List<ReportExecutedData>? measurements,
    String? error,
    bool clearError = false,
    String? contractId,
    bool clearContractId = false,
    bool? uploading,
    double? uploadProgress,
    bool clearUploadProgress = false,
  }) {
    return ReportExecutedState(
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      error: clearError ? null : error ?? this.error,
      contractId: clearContractId ? null : contractId ?? this.contractId,
      uploading: uploading ?? this.uploading,
      uploadProgress:
      clearUploadProgress ? null : uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props {
    return [
      status,
      measurements,
      error,
      contractId,
      uploading,
      uploadProgress,
    ];
  }
}