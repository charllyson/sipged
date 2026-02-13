import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_state.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

class AdjustmentMeasurementCubit extends Cubit<AdjustmentMeasurementState> {
  final AdjustmentMeasurementRepository _repo;

  AdjustmentMeasurementCubit({AdjustmentMeasurementRepository? repository})
      : _repo = repository ?? AdjustmentMeasurementRepository(),
        super(AdjustmentMeasurementState.initial());

  Future<void> loadByContract(String contractId) async {
    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.loading,
        errorMessage: null,
        contractId: contractId,
        selected: null,
        selectedIndex: null,
        attachments: const [],
        selectedAttachmentIndex: null,
        isSaving: false,
        uploading: false,
        uploadProgress: null,
      ),
    );

    try {
      final list = await _repo.getAllAdjustmentsOfContract(uidContract: contractId);

      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.loaded,
          adjustments: list,
          errorMessage: null,
          contractId: contractId,
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          errorMessage: e.toString(),
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );
    }
  }

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsCollectionGroup() {
    return _repo.getAllAdjustmentsCollectionGroup();
  }

  double sum(List<AdjustmentMeasurementData> list) => _repo.sumAdjustments(list);

  Future<void> saveOrUpdate(AdjustmentMeasurementData data) async {
    final contractId = data.contractId ?? state.contractId;
    if (contractId == null) {
      throw Exception('contractId é obrigatório em AdjustmentMeasurementData');
    }

    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.saveOrUpdateAdjustment(
        contractId: contractId,
        adj: data.copyWith(contractId: contractId),
      );

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
      } else {
        emit(
          state.copyWith(
            status: AdjustmentMeasurementStatus.loaded,
            isSaving: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> delete({
    required String contractId,
    required String adjustmentId,
  }) async {
    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.deleteAdjustment(contractId: contractId, adjustmentId: adjustmentId);

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
      } else {
        emit(
          state.copyWith(
            status: AdjustmentMeasurementStatus.loaded,
            isSaving: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
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
    if (index < 0 || index >= state.adjustments.length) {
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

    final sel = state.adjustments[index];
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
  // Anexos (multi)
  // ---------------------------------------------------------------------------

  Future<void> updateAttachments(List<Attachment> attachments) async {
    final selected = state.selected;
    final contractId = state.contractId;
    if (contractId == null || selected?.id == null) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.setAttachments(
        contractId: contractId,
        adjustmentId: selected!.id!,
        attachments: attachments,
      );

      final updatedSelected = selected.copyWith(attachments: attachments);

      final updatedList = state.adjustments.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: attachments,
          adjustments: updatedList,
          selected: updatedSelected,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// ✅ + real: picker -> upload -> append -> setAttachments
  Future<Attachment> pickAndUploadAttachment({
    required ProcessData contract,
    required String contractId,
    required String adjustmentId,
  }) async {
    final selected = state.selected;
    if (selected == null || selected.id == null || selected.id!.isEmpty) {
      throw Exception('Selecione/salve o reajuste antes de anexar arquivos.');
    }

    emit(state.copyWith(uploading: true, uploadProgress: 0.0));

    try {
      final (bytes, name) = await _repo.pickFileBytes();

      final att = await _repo.uploadAttachmentBytes(
        contract: contract,
        adjustment: selected.copyWith(id: adjustmentId, contractId: contractId),
        bytes: bytes,
        originalName: name,
        label: '',
        onProgress: (p) => emit(state.copyWith(uploadProgress: p)),
      );

      final next = [...state.attachments, att];

      await _repo.setAttachments(
        contractId: contractId,
        adjustmentId: adjustmentId,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);
      final updatedList = state.adjustments.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          attachments: next,
          selected: updatedSelected,
          adjustments: updatedList,
        ),
      );

      return att;
    } catch (e) {
      emit(state.copyWith(uploading: false, uploadProgress: null));
      rethrow;
    }
  }

  /// ✅ delete real: Storage + Firestore
  Future<void> deleteAttachment({
    required String contractId,
    required String adjustmentId,
    required Attachment attachment,
  }) async {
    final selected = state.selected;
    if (selected == null) return;

    final next = List<Attachment>.from(state.attachments)
      ..removeWhere((a) => a.id == attachment.id && a.url == attachment.url);

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _repo.deleteAttachment(
        contractId: contractId,
        adjustmentId: adjustmentId,
        attachment: attachment,
        nextAttachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);
      final updatedList = state.adjustments.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          selected: updatedSelected,
          adjustments: updatedList,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  /// ✅ rename persistido (somente Firestore attachments[])
  Future<void> renameAttachmentLabel({
    required String contractId,
    required String adjustmentId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final selected = state.selected;
    if (selected == null) return;

    final next = List<Attachment>.from(state.attachments);
    final idx = next.indexWhere((a) => a.id == oldItem.id && a.url == oldItem.url);
    if (idx < 0) return;
    next[idx] = newItem;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _repo.renameAttachmentLabel(
        contractId: contractId,
        adjustmentId: adjustmentId,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);
      final updatedList = state.adjustments.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          selected: updatedSelected,
          adjustments: updatedList,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  /// Migração simples: zera o pdfUrl legado
  Future<void> clearLegacyPdfUrl() async {
    final selected = state.selected;
    final contractId = state.contractId;
    if (contractId == null || selected?.id == null) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.salvarUrlPdfDaAdjustmentMeasurement(
        contractId: contractId,
        adjustmentId: selected!.id!,
        url: '',
      );

      final updatedSelected = selected.copyWith(pdfUrl: null);

      final updatedList = state.adjustments.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          selected: updatedSelected,
          adjustments: updatedList,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
