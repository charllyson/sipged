import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'revision_measurement_data.dart';
import 'revision_measurement_repository.dart';
import 'revision_measurement_state.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

class RevisionMeasurementCubit extends Cubit<RevisionMeasurementState> {
  final RevisionMeasurementRepository _repo;

  RevisionMeasurementCubit({RevisionMeasurementRepository? repository})
      : _repo = repository ?? RevisionMeasurementRepository(),
        super(RevisionMeasurementState.initial());

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadByContract(String contractId) async {
    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.loading,
        errorMessage: null,
        contractId: contractId,
        selected: null,
        selectedIndex: null,
        attachments: const [],
        selectedAttachmentIndex: null,
        isSaving: false,
      ),
    );

    try {
      final list = await _repo.getAllRevisionsOfContract(uidContract: contractId);

      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.loaded,
          revisions: list,
          errorMessage: null,
          contractId: contractId,
          isSaving: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
          errorMessage: e.toString(),
          isSaving: false,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CollectionGroup (Dashboard)
  // ---------------------------------------------------------------------------

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() {
    return _repo.getAllRevisionsCollectionGroup();
  }

  double sum(List<RevisionMeasurementData> list) => _repo.sumRevisions(list);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdate({
    required String contractId,
    required String revisionMeasurementId,
    required RevisionMeasurementData data,
  }) async {
    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.saveOrUpdateRevision(
        contractId: contractId,
        revisionMeasurementId: revisionMeasurementId,
        rev: data,
      );

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
      } else {
        emit(state.copyWith(status: RevisionMeasurementStatus.loaded, isSaving: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> delete({
    required String contractId,
    required String revisionId,
  }) async {
    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.deleteRevision(contractId: contractId, revisionId: revisionId);

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
      } else {
        emit(state.copyWith(status: RevisionMeasurementStatus.loaded, isSaving: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Seleção
  // ---------------------------------------------------------------------------

  void selectByIndex(int index) {
    if (index < 0 || index >= state.revisions.length) {
      emit(
        state.copyWith(
          selected: null,
          selectedIndex: null,
          attachments: const [],
          selectedAttachmentIndex: null,
        ),
      );
      return;
    }

    final sel = state.revisions[index];
    final atts = sel.attachments ?? const <Attachment>[];

    emit(
      state.copyWith(
        selected: sel,
        selectedIndex: index,
        attachments: atts,
        selectedAttachmentIndex: null,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selected: null,
        selectedIndex: null,
        attachments: const [],
        selectedAttachmentIndex: null,
      ),
    );
  }

  void selectAttachmentIndex(int index) {
    if (index < 0 || index >= state.attachments.length) {
      emit(state.copyWith(selectedAttachmentIndex: null));
      return;
    }
    emit(state.copyWith(selectedAttachmentIndex: index));
  }

  // ---------------------------------------------------------------------------
  // Attachments
  // ---------------------------------------------------------------------------

  Future<void> updateAttachments(List<Attachment> attachments) async {
    final selected = state.selected;
    final contractId = state.contractId;
    if (contractId == null || selected?.id == null) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected!.id!,
        attachments: attachments,
      );

      final updatedSelected = selected.copyWith(attachments: attachments);
      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: attachments,
          revisions: updatedList,
          selected: updatedSelected,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  Future<void> addAttachmentWithPicker({
    required ProcessData contract,
    String label = '',
    void Function(double progress)? onProgress,
  }) async {
    final selected = state.selected;
    final contractId = state.contractId;
    if (contractId == null || selected?.id == null) {
      throw Exception('Selecione uma revisão antes de anexar arquivos.');
    }

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final (bytes, originalName) = await _repo.pickFileBytes();

      final att = await _repo.uploadAttachmentBytes(
        contract: contract,
        revision: selected!,
        bytes: bytes,
        originalName: originalName,
        label: label,
        onProgress: onProgress,
      );

      final next = List<Attachment>.from(state.attachments)..add(att);

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected.id!,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);
      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          revisions: updatedList,
          selected: updatedSelected,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<void> deleteAttachmentAt(int index) async {
    final selected = state.selected;
    final contractId = state.contractId;
    if (contractId == null || selected?.id == null) return;

    if (index < 0 || index >= state.attachments.length) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final next = List<Attachment>.from(state.attachments);
      final removed = next.removeAt(index);

      // tenta remover no storage (se tiver path)
      final storagePath = removed.path;
      if (storagePath.trim().isNotEmpty) {
        await _repo.deleteStorageByPath(storagePath);
      }

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected!.id!,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);
      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          revisions: updatedList,
          selected: updatedSelected,
          selectedAttachmentIndex: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  /// Migração simples: zera pdfUrl legado (se quiser)
  Future<void> clearLegacyPdfUrl() async {
    final selected = state.selected;
    final contractId = state.contractId;
    if (contractId == null || selected?.id == null) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _repo.salvarUrlPdfDaRevisionMeasurement(
        contractId: contractId,
        revisionMeasurementId: selected!.id!,
        url: '',
      );

      final updatedSelected = selected.copyWith(pdfUrl: null);

      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          selected: updatedSelected,
          revisions: updatedList,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }
}
