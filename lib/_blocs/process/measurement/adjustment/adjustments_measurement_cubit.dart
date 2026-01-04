// lib/_blocs/process/measurement/adjustment/adjustments_measurement_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/process/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:siged/_blocs/process/measurement/adjustment/adjustments_measurement_state.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_blocs/process/measurement/adjustment/adjustment_measurement_data.dart';

class AdjustmentMeasurementCubit extends Cubit<AdjustmentMeasurementState> {
  final AdjustmentMeasurementRepository _repo;

  AdjustmentMeasurementCubit({AdjustmentMeasurementRepository? repository})
      : _repo = repository ?? AdjustmentMeasurementRepository(),
        super(AdjustmentMeasurementState.initial());

  // ---------------------------------------------------------------------------
  // Carregar reajustes de um contrato
  // ---------------------------------------------------------------------------

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
        isSaving: false, // 🔴 GARANTE QUE O LOADING SOME
      ),
    );

    try {
      final list = await _repo.getAllAdjustmentsOfContract(
        uidContract: contractId,
      );

      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.loaded,
          adjustments: list,
          errorMessage: null,
          contractId: contractId,
          isSaving: false, // 🔴 AQUI TAMBÉM
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          errorMessage: e.toString(),
          isSaving: false, // 🔴 EM CASO DE ERRO TAMBÉM
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CollectionGroup (para dashboards)
  // ---------------------------------------------------------------------------

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsCollectionGroup() {
    return _repo.getAllAdjustmentsCollectionGroup();
  }

  double sum(List<AdjustmentMeasurementData> list) =>
      _repo.sumAdjustments(list);

  // ---------------------------------------------------------------------------
  // CRUD principal delegando para o Repository
  // ---------------------------------------------------------------------------

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

      // Recarrega lista para o mesmo contrato
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
      // Se der erro, garante que o loading some e repassa o erro
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
      await _repo.deleteAdjustment(
        contractId: contractId,
        adjustmentId: adjustmentId,
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
  // Anexos
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
