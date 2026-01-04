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

  /// Lista de medições do contrato corrente (quando usado em telas de contrato).
  final List<ReportMeasurementData> measurements;

  /// Opcional: erro.
  final String? error;

  /// Opcional: id do contrato carregado.
  final String? contractId;

  const ReportMeasurementState({
    this.status = ReportMeasurementStatus.initial,
    this.measurements = const [],
    this.error,
    this.contractId,
  });

  ReportMeasurementState copyWith({
    ReportMeasurementStatus? status,
    List<ReportMeasurementData>? measurements,
    String? error,
    String? contractId,
  }) {
    return ReportMeasurementState(
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      error: error ?? this.error,
      contractId: contractId ?? this.contractId,
    );
  }

  factory ReportMeasurementState.initial() => const ReportMeasurementState(
    status: ReportMeasurementStatus.initial,
    measurements: [],
    error: null,
    contractId: null,
  );

  @override
  List<Object?> get props => [status, measurements, error, contractId];
}
