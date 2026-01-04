import 'package:equatable/equatable.dart';
import 'revision_measurement_data.dart';

enum RevisionMeasurementStatus {
  initial,
  loading,
  success,
  failure,
}

class RevisionMeasurementState extends Equatable {
  final RevisionMeasurementStatus status;
  final List<RevisionMeasurementData> revisions;
  final String? error;
  final String? contractId;

  const RevisionMeasurementState({
    this.status = RevisionMeasurementStatus.initial,
    this.revisions = const [],
    this.error,
    this.contractId,
  });

  RevisionMeasurementState copyWith({
    RevisionMeasurementStatus? status,
    List<RevisionMeasurementData>? revisions,
    String? error,
    String? contractId,
  }) {
    return RevisionMeasurementState(
      status: status ?? this.status,
      revisions: revisions ?? this.revisions,
      error: error ?? this.error,
      contractId: contractId ?? this.contractId,
    );
  }

  factory RevisionMeasurementState.initial() =>
      const RevisionMeasurementState(
        status: RevisionMeasurementStatus.initial,
        revisions: [],
        error: null,
        contractId: null,
      );

  @override
  List<Object?> get props => [status, revisions, error, contractId];
}
