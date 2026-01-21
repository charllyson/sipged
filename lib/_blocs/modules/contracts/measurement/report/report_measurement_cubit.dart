import 'package:flutter_bloc/flutter_bloc.dart';

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
      final list = await _repo.getAllMeasurementsOfContract(
        uidContract: contractId,
      );
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
  // CollectionGroup (para dashboards) – retorna direto
  // ---------------------------------------------------------------------------

  Future<List<ReportMeasurementData>> getAllMeasurementsCollectionGroup() {
    return _repo.getAllMeasurementsCollectionGroup();
  }

  // ---------------------------------------------------------------------------
  // CRUD delegando para o Repository
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
    await _repo.deleteMeasurement(
      contractId: contractId,
      measurementId: measurementId,
    );
    if (state.contractId == contractId) {
      await loadByContract(contractId);
    }
  }

  double sum(List<ReportMeasurementData> list) =>
      _repo.somarValorMedicoes(list);
}
