// lib/_blocs/modules/financial/payments/adjustment/adjustment_paid_state.dart

import 'package:equatable/equatable.dart';

import 'adjustment_paid_data.dart';

enum AdjustmentPaidStatus {
  initial,
  loading,
  success,
  failure,
}

const Object _unset = Object();

class AdjustmentPaidState extends Equatable {
  const AdjustmentPaidState({
    this.status = AdjustmentPaidStatus.initial,
    this.payments = const <AdjustmentPaidData>[],
    this.selected,
    this.error,
    this.contractId,
    this.adjustmentId,
    this.selectedSideIndex,
    this.uploading = false,
    this.uploadProgress,
  });

  final AdjustmentPaidStatus status;
  final List<AdjustmentPaidData> payments;
  final AdjustmentPaidData? selected;
  final String? error;

  final String? contractId;
  final String? adjustmentId;

  final int? selectedSideIndex;

  final bool uploading;
  final double? uploadProgress;

  factory AdjustmentPaidState.initial() {
    return const AdjustmentPaidState();
  }

  AdjustmentPaidState copyWith({
    AdjustmentPaidStatus? status,
    List<AdjustmentPaidData>? payments,
    Object? selected = _unset,
    Object? error = _unset,
    Object? contractId = _unset,
    Object? adjustmentId = _unset,
    Object? selectedSideIndex = _unset,
    bool? uploading,
    Object? uploadProgress = _unset,
  }) {
    return AdjustmentPaidState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      selected: identical(selected, _unset)
          ? this.selected
          : selected as AdjustmentPaidData?,
      error: identical(error, _unset) ? this.error : error as String?,
      contractId:
      identical(contractId, _unset) ? this.contractId : contractId as String?,
      adjustmentId: identical(adjustmentId, _unset)
          ? this.adjustmentId
          : adjustmentId as String?,
      selectedSideIndex: identical(selectedSideIndex, _unset)
          ? this.selectedSideIndex
          : selectedSideIndex as int?,
      uploading: uploading ?? this.uploading,
      uploadProgress: identical(uploadProgress, _unset)
          ? this.uploadProgress
          : uploadProgress as double?,
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
      adjustmentId,
      selectedSideIndex,
      uploading,
      uploadProgress,
    ];
  }
}