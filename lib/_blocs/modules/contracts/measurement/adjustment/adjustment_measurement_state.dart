import 'package:equatable/equatable.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

enum AdjustmentMeasurementStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

const Object _unset = Object();

class AdjustmentMeasurementState extends Equatable {
  final AdjustmentMeasurementStatus status;

  final List<AdjustmentMeasurementData> adjustments;
  final String? errorMessage;
  final String? contractId;

  /// Loading geral: salvar, excluir, atualizar anexos etc.
  final bool isSaving;

  /// Upload de anexos.
  final bool uploading;
  final double? uploadProgress;

  final AdjustmentMeasurementData? selected;
  final int? selectedIndex;

  final List<Attachment> attachments;
  final int? selectedAttachmentIndex;

  const AdjustmentMeasurementState({
    this.status = AdjustmentMeasurementStatus.initial,
    this.adjustments = const [],
    this.errorMessage,
    this.contractId,
    this.isSaving = false,
    this.uploading = false,
    this.uploadProgress,
    this.selected,
    this.selectedIndex,
    this.attachments = const [],
    this.selectedAttachmentIndex,
  });

  AdjustmentMeasurementState copyWith({
    AdjustmentMeasurementStatus? status,
    List<AdjustmentMeasurementData>? adjustments,
    Object? errorMessage = _unset,
    Object? contractId = _unset,
    bool? isSaving,
    bool? uploading,
    Object? uploadProgress = _unset,
    Object? selected = _unset,
    Object? selectedIndex = _unset,
    List<Attachment>? attachments,
    Object? selectedAttachmentIndex = _unset,
  }) {
    return AdjustmentMeasurementState(
      status: status ?? this.status,
      adjustments: adjustments ?? this.adjustments,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      contractId:
      identical(contractId, _unset) ? this.contractId : contractId as String?,
      isSaving: isSaving ?? this.isSaving,
      uploading: uploading ?? this.uploading,
      uploadProgress: identical(uploadProgress, _unset)
          ? this.uploadProgress
          : uploadProgress as double?,
      selected: identical(selected, _unset)
          ? this.selected
          : selected as AdjustmentMeasurementData?,
      selectedIndex: identical(selectedIndex, _unset)
          ? this.selectedIndex
          : selectedIndex as int?,
      attachments: attachments ?? this.attachments,
      selectedAttachmentIndex: identical(selectedAttachmentIndex, _unset)
          ? this.selectedAttachmentIndex
          : selectedAttachmentIndex as int?,
    );
  }

  factory AdjustmentMeasurementState.initial() {
    return const AdjustmentMeasurementState(
      status: AdjustmentMeasurementStatus.initial,
      adjustments: [],
      errorMessage: null,
      contractId: null,
      isSaving: false,
      uploading: false,
      uploadProgress: null,
      selected: null,
      selectedIndex: null,
      attachments: [],
      selectedAttachmentIndex: null,
    );
  }

  @override
  List<Object?> get props => [
    status,
    adjustments,
    errorMessage,
    contractId,
    isSaving,
    uploading,
    uploadProgress,
    selected,
    selectedIndex,
    attachments,
    selectedAttachmentIndex,
  ];
}