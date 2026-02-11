import 'package:equatable/equatable.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

enum AdjustmentMeasurementStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

class AdjustmentMeasurementState extends Equatable {
  final AdjustmentMeasurementStatus status;

  final List<AdjustmentMeasurementData> adjustments;
  final String? errorMessage;
  final String? contractId;

  /// loading geral (salvar / delete / setAttachments etc.)
  final bool isSaving;

  /// ✅ NOVO: upload/anexo
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
    String? errorMessage,
    String? contractId,
    bool? isSaving,
    bool? uploading,
    double? uploadProgress,
    AdjustmentMeasurementData? selected,
    int? selectedIndex,
    List<Attachment>? attachments,
    int? selectedAttachmentIndex,
  }) {
    return AdjustmentMeasurementState(
      status: status ?? this.status,
      adjustments: adjustments ?? this.adjustments,
      errorMessage: errorMessage ?? this.errorMessage,
      contractId: contractId ?? this.contractId,
      isSaving: isSaving ?? this.isSaving,
      uploading: uploading ?? this.uploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      selected: selected ?? this.selected,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      attachments: attachments ?? this.attachments,
      selectedAttachmentIndex:
      selectedAttachmentIndex ?? this.selectedAttachmentIndex,
    );
  }

  factory AdjustmentMeasurementState.initial() =>
      const AdjustmentMeasurementState(
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
