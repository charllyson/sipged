import 'package:equatable/equatable.dart';
import 'report_measurement_data.dart';

enum ReportMeasurementStatus {
  initial,
  loading,
  success,
  failure,
}

class ReportMeasurementState extends Equatable {
  final ReportMeasurementStatus status;

  /// Lista de medições do contrato corrente
  final List<ReportMeasurementData> measurements;

  /// Opcional: erro.
  final String? error;

  /// Opcional: id do contrato carregado.
  final String? contractId;

  /// ✅ Upload (SideListBox)
  final bool uploading;
  final double? uploadProgress; // 0..1

  const ReportMeasurementState({
    this.status = ReportMeasurementStatus.initial,
    this.measurements = const [],
    this.error,
    this.contractId,
    this.uploading = false,
    this.uploadProgress,
  });

  ReportMeasurementState copyWith({
    ReportMeasurementStatus? status,
    List<ReportMeasurementData>? measurements,
    String? error,
    String? contractId,
    bool? uploading,
    double? uploadProgress,
  }) {
    return ReportMeasurementState(
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      error: error ?? this.error,
      contractId: contractId ?? this.contractId,
      uploading: uploading ?? this.uploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  factory ReportMeasurementState.initial() => const ReportMeasurementState(
    status: ReportMeasurementStatus.initial,
    measurements: [],
    error: null,
    contractId: null,
    uploading: false,
    uploadProgress: null,
  );

  @override
  List<Object?> get props =>
      [status, measurements, error, contractId, uploading, uploadProgress];
}
