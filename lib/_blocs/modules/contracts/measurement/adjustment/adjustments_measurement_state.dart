// lib/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_state.dart
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

  /// Lista de reajustes do contrato corrente (quando usado em telas de contrato).
  final List<AdjustmentMeasurementData> adjustments;

  /// Opcional: erro.
  final String? errorMessage;

  /// Opcional: id do contrato carregado.
  final String? contractId;

  /// Se há operação de salvamento em andamento.
  final bool isSaving;

  /// Seleção de linha (para tela de contrato).
  final AdjustmentMeasurementData? selected;
  final int? selectedIndex;

  /// Lista de anexos do registro selecionado.
  final List<Attachment> attachments;
  final int? selectedAttachmentIndex;

  const AdjustmentMeasurementState({
    this.status = AdjustmentMeasurementStatus.initial,
    this.adjustments = const [],
    this.errorMessage,
    this.contractId,
    this.isSaving = false,
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
    selected,
    selectedIndex,
    attachments,
    selectedAttachmentIndex,
  ];
}
