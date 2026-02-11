import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

import 'report_measurement_state.dart';
import 'report_measurement_data.dart';
import 'report_measurement_repository.dart';

class ReportMeasurementCubit extends Cubit<ReportMeasurementState> {
  final ReportMeasurementRepository _repo;

  ReportMeasurementCubit({ReportMeasurementRepository? repository})
      : _repo = repository ?? ReportMeasurementRepository(),
        super(ReportMeasurementState.initial());

  // ---------------------------------------------------------------------------
  // Carregar medições de um contrato
  // ---------------------------------------------------------------------------

  Future<void> loadByContract(String contractId) async {
    emit(state.copyWith(
      status: ReportMeasurementStatus.loading,
      error: null,
      contractId: contractId,
    ));
    try {
      final list = await _repo.getAllMeasurementsOfContract(uidContract: contractId);
      emit(
        state.copyWith(
          status: ReportMeasurementStatus.success,
          measurements: list,
          error: null,
          contractId: contractId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportMeasurementStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CollectionGroup (para dashboards)
  // ---------------------------------------------------------------------------

  Future<List<ReportMeasurementData>> getAllMeasurementsCollectionGroup() {
    return _repo.getAllMeasurementsCollectionGroup();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdate(ReportMeasurementData data) async {
    await _repo.saveOrUpdateReport(data);
    if (state.contractId != null && data.contractId == state.contractId) {
      await loadByContract(state.contractId!);
    }
  }

  Future<void> delete({
    required String contractId,
    required String measurementId,
  }) async {
    await _repo.deleteMeasurement(contractId: contractId, measurementId: measurementId);
    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  double sum(List<ReportMeasurementData> list) => _repo.somarValorMedicoes(list);

  // ---------------------------------------------------------------------------
  // ✅ Attachments (SideListBox)
  // ---------------------------------------------------------------------------

  Future<Attachment> pickAndUploadAttachment({
    required String contractId,
    required String measurementId,
  }) async {
    emit(state.copyWith(uploading: true, uploadProgress: 0.0, error: null));

    try {
      final att = await _repo.pickAndUploadAttachment(
        contractId: contractId,
        measurementId: measurementId,
        onProgress: (p) {
          emit(state.copyWith(uploading: true, uploadProgress: p));
        },
      );

      // recarrega lista para refletir attachments
      if (state.contractId == contractId) {
        await loadByContract(contractId);
      }

      emit(state.copyWith(uploading: false, uploadProgress: null));
      return att;
    } catch (e) {
      emit(state.copyWith(uploading: false, uploadProgress: null, error: e.toString()));
      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    await _repo.deleteAttachment(
      contractId: contractId,
      measurementId: measurementId,
      attachment: attachment,
    );
    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String measurementId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    await _repo.renameAttachmentLabel(
      contractId: contractId,
      measurementId: measurementId,
      oldItem: oldItem,
      newItem: newItem,
    );
    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }
}
