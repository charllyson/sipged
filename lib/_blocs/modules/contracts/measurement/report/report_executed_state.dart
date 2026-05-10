import 'package:equatable/equatable.dart';

import 'report_executed_data.dart';

enum ReportExecutedStatus {
  initial,
  loading,
  success,
  failure,
}

const Object _unset = Object();

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
    Object? error = _unset,
    Object? contractId = _unset,
    bool? uploading,
    Object? uploadProgress = _unset,
  }) {
    return ReportExecutedState(
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      error: identical(error, _unset) ? this.error : error as String?,
      contractId: identical(contractId, _unset)
          ? this.contractId
          : contractId as String?,
      uploading: uploading ?? this.uploading,
      uploadProgress: identical(uploadProgress, _unset)
          ? this.uploadProgress
          : uploadProgress as double?,
    );
  }

  @override
  List<Object?> get props {
    return <Object?>[
      status,
      measurements,
      error,
      contractId,
      uploading,
      uploadProgress,
    ];
  }
}