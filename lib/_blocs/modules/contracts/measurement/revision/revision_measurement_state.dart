import 'package:equatable/equatable.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'revision_measurement_data.dart';

enum RevisionMeasurementStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

const Object _unset = Object();

class RevisionMeasurementState extends Equatable {
  final RevisionMeasurementStatus status;

  /// Lista de revisões do contrato atual.
  final List<RevisionMeasurementData> revisions;

  /// Erro, se existir.
  final String? errorMessage;

  /// ContractId carregado.
  final String? contractId;

  /// Loading geral: salvar, excluir, atualizar anexos etc.
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
    Object? errorMessage = _unset,
    Object? contractId = _unset,
    bool? isSaving,
    Object? selected = _unset,
    Object? selectedIndex = _unset,
    List<Attachment>? attachments,
    Object? selectedAttachmentIndex = _unset,
  }) {
    return RevisionMeasurementState(
      status: status ?? this.status,
      revisions: revisions ?? this.revisions,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      contractId:
      identical(contractId, _unset) ? this.contractId : contractId as String?,
      isSaving: isSaving ?? this.isSaving,
      selected: identical(selected, _unset)
          ? this.selected
          : selected as RevisionMeasurementData?,
      selectedIndex: identical(selectedIndex, _unset)
          ? this.selectedIndex
          : selectedIndex as int?,
      attachments: attachments ?? this.attachments,
      selectedAttachmentIndex: identical(selectedAttachmentIndex, _unset)
          ? this.selectedAttachmentIndex
          : selectedAttachmentIndex as int?,
    );
  }

  factory RevisionMeasurementState.initial() {
    return const RevisionMeasurementState(
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
  }

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