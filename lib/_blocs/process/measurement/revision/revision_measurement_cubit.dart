import 'package:flutter_bloc/flutter_bloc.dart';

import 'revision_measurement_state.dart';
import 'revision_measurement_data.dart';
import 'revision_measurement_repository.dart';

class RevisionMeasurementCubit extends Cubit<RevisionMeasurementState> {
  final RevisionMeasurementRepository _repo;

  RevisionMeasurementCubit({RevisionMeasurementRepository? repository})
      : _repo = repository ?? RevisionMeasurementRepository(),
        super(RevisionMeasurementState.initial());

  // ---------------------------------------------------------------------------
  // Carregar revisões por contrato
  // ---------------------------------------------------------------------------

  Future<void> loadByContract(String contractId) async {
    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.loading,
        error: null,
        contractId: contractId,
      ),
    );
    try {
      final list = await _repo.getAllRevisionsOfContract(
        uidContract: contractId,
      );
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.success,
          revisions: list,
          error: null,
          contractId: contractId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CollectionGroup – usado no Dashboard
  // ---------------------------------------------------------------------------

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() {
    return _repo.getAllRevisionsCollectionGroup();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdate({
    required String contractId,
    required String revisionMeasurementId,
    required RevisionMeasurementData data,
  }) async {
    await _repo.saveOrUpdateRevision(
      contractId: contractId,
      revisionMeasurementId: revisionMeasurementId,
      rev: data,
    );
    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  Future<void> delete({
    required String contractId,
    required String revisionId,
  }) async {
    await _repo.deleteRevision(
      contractId: contractId,
      revisionId: revisionId,
    );
    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  double sum(List<RevisionMeasurementData> list) =>
      _repo.sumRevisions(list);
}
