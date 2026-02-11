import 'package:equatable/equatable.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'revision_measurement_data.dart';

enum RevisionMeasurementStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

class RevisionMeasurementState extends Equatable {
  final RevisionMeasurementStatus status;

  /// Lista de revisões do contrato atual.
  final List<RevisionMeasurementData> revisions;

  /// Erro (se existir).
  final String? errorMessage;

  /// ContractId carregado.
  final String? contractId;

  /// Overlay de loading/saving.
  final bool isSaving;

  /// Seleção atual.
  final RevisionMeasurementData? selected;
  final int? selectedIndex;

  /// Anexos do item selecionado.
  final List<Attachment> attachments;
  final int? selectedAttachmentIndex;

  const RevisionMeasurementState({
    this.status = RevisionMeasurementStatus.initial,
    this.revisions = const [],
    this.errorMessage,
    this.contractId,
    this.isSaving = false,
    this.selected,
    this.selectedIndex,
    this.attachments = const [],
    this.selectedAttachmentIndex,
  });

  RevisionMeasurementState copyWith({
    RevisionMeasurementStatus? status,
    List<RevisionMeasurementData>? revisions,
    String? errorMessage,
    String? contractId,
    bool? isSaving,
    RevisionMeasurementData? selected,
    int? selectedIndex,
    List<Attachment>? attachments,
    int? selectedAttachmentIndex,
  }) {
    return RevisionMeasurementState(
      status: status ?? this.status,
      revisions: revisions ?? this.revisions,
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

  factory RevisionMeasurementState.initial() => const RevisionMeasurementState(
    status: RevisionMeasurementStatus.initial,
    revisions: [],
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
    revisions,
    errorMessage,
    contractId,
    isSaving,
    selected,
    selectedIndex,
    attachments,
    selectedAttachmentIndex,
  ];
}
