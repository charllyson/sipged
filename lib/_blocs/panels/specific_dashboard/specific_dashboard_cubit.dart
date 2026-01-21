import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:siged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:siged/_blocs/modules/contracts/measurement/report/report_measurement_repository.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustments_measurement_repository.dart';
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

import 'specific_dashboard_state.dart';

class SpecificDashboardCubit extends Cubit<SpecificDashboardState> {
  final DfdRepository dfdRepository;
  final AdditivesRepository additivesRepository;
  final ApostillesRepository apostillesRepository;

  final ReportMeasurementRepository reportRepository;
  final AdjustmentMeasurementRepository adjustmentRepository;
  final RevisionMeasurementRepository revisionRepository;

  SpecificDashboardCubit({
    required this.dfdRepository,
    required this.additivesRepository,
    required this.apostillesRepository,
    required this.reportRepository,
    required this.adjustmentRepository,
    required this.revisionRepository,
  }) : super(const SpecificDashboardState());

  // ===========================================================
  // LOAD (Resumo do contrato via DFD + Aditivos + Medições + Apostilamentos + Reajustes/Revisões)
  // ===========================================================
  Future<void> loadForContract(String contractId) async {
    final id = contractId.trim();
    if (id.isEmpty) return;

    emit(
      state.copyWith(
        resumeLoading: true,
        resumeError: null,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        dfdRepository.readDataForContract(id),
        additivesRepository.getAllAdditivesValue(id),
        apostillesRepository.getAllApostillesValue(id),
        reportRepository.getAllMeasurementsOfContract(uidContract: id),
        adjustmentRepository.getAllAdjustmentsOfContract(uidContract: id),
        revisionRepository.getAllRevisionsOfContract(uidContract: id),
      ]);

      final DfdData? dfd = results[0] as DfdData?;

      final double totalAditivos = (results[1] as double?) ?? 0.0;
      final double totalApostilamentos = (results[2] as double?) ?? 0.0;

      final reportList = results[3];
      final adjustmentList = results[4];
      final revisionList = results[5];

      // Valor Contratado vem do DFD
      final double valorContratado =
      (dfd?.valorDemanda ?? dfd?.estimativaValor ?? 0).toDouble();

      // ✅ Extensão (km) vem do DFD
      final double extensaoKm = (dfd?.extensaoKm ?? 0).toDouble();

      // ✅ Natureza da intervenção vem do DFD (localizacao/main)
      final String? natureza = (dfd?.naturezaIntervencao ?? '').trim().isEmpty
          ? null
          : dfd!.naturezaIntervencao!.trim();

      // report = total medições
      final double totalMedicoes =
      reportRepository.somarValorMedicoes((reportList as List).cast());

      // adjustment + revision
      final double totalAdjustments =
      adjustmentRepository.sumAdjustments((adjustmentList as List).cast());

      final double totalRevisions =
      revisionRepository.sumRevisions((revisionList as List).cast());

      final double totalReajustesERevisoes = totalAdjustments + totalRevisions;

      // saldos
      final double saldoContrato =
          (valorContratado + totalAditivos) - totalMedicoes;

      final double saldoApostilamentos =
          totalApostilamentos - totalReajustesERevisoes;

      final List<double> contractValues = <double>[
        valorContratado,
        totalAditivos,
        totalMedicoes,
        saldoContrato,
      ];

      final List<double> apostillesValues = <double>[
        totalApostilamentos,
        totalReajustesERevisoes,
        saldoApostilamentos,
      ];

      // LEGADO
      final List<double> resumeValuesLegacy = <double>[
        valorContratado,
        totalAditivos,
        totalMedicoes,
        saldoContrato,
        totalApostilamentos,
        totalReajustesERevisoes,
        saldoApostilamentos,
      ];

      emit(
        state.copyWith(
          resumeLoading: false,
          dfdExtensaoKm: extensaoKm,
          dfdNaturezaIntervencao: natureza, // ✅ AQUI
          contractValues: contractValues,
          apostillesValues: apostillesValues,
          resumeValues: resumeValuesLegacy,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          resumeLoading: false,
          resumeError: e.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // ACOMPANHAMENTO FÍSICO
  // ===========================================================
  void toggleScheduleSlice({
    required int rowIndex,
    required int sliceIndex,
  }) {
    final sameRow = state.selectedScheduleRowIndex == rowIndex;
    final sameSlice = state.selectedScheduleSliceIndex == sliceIndex;

    if (sameRow && sameSlice) {
      emit(state.copyWith(clearScheduleSelection: true));
    } else {
      emit(
        state.copyWith(
          selectedScheduleRowIndex: rowIndex,
          selectedScheduleSliceIndex: sliceIndex,
        ),
      );
    }
  }

  void clearScheduleSelection() {
    emit(state.copyWith(clearScheduleSelection: true));
  }

  // ===========================================================
  // NOVO: RESUMO CONTRATO (4 slices)
  // ===========================================================
  void toggleContractSlice({required int sliceIndex}) {
    final same = state.selectedContractSliceIndex == sliceIndex;
    if (same) {
      emit(state.copyWith(clearContractSlice: true));
    } else {
      emit(state.copyWith(selectedContractSliceIndex: sliceIndex));
    }
    emit(state.copyWith(clearApostillesSlice: true));
  }

  void clearContractSelection() {
    emit(state.copyWith(clearContractSlice: true));
  }

  // ===========================================================
  // NOVO: RESUMO APOSTILAMENTOS (3 slices)
  // ===========================================================
  void toggleApostillesSlice({required int sliceIndex}) {
    final same = state.selectedApostillesSliceIndex == sliceIndex;
    if (same) {
      emit(state.copyWith(clearApostillesSlice: true));
    } else {
      emit(state.copyWith(selectedApostillesSliceIndex: sliceIndex));
    }
    emit(state.copyWith(clearContractSlice: true));
  }

  void clearApostillesSelection() {
    emit(state.copyWith(clearApostillesSlice: true));
  }

  // ===========================================================
  // LEGADO
  // ===========================================================
  void toggleResumeSlice({
    required int rowIndex,
    required int sliceIndex,
  }) {
    final sameRow = state.selectedResumeRowIndex == rowIndex;
    final sameSlice = state.selectedResumeSliceIndex == sliceIndex;

    if (sameRow && sameSlice) {
      emit(state.copyWith(clearLegacyResumeSelection: true));
      emit(state.copyWith(clearContractSlice: true, clearApostillesSlice: true));
      return;
    }

    emit(
      state.copyWith(
        selectedResumeRowIndex: rowIndex,
        selectedResumeSliceIndex: sliceIndex,
      ),
    );

    if (sliceIndex <= 3) {
      emit(
        state.copyWith(
          selectedContractSliceIndex: sliceIndex,
          clearApostillesSlice: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedApostillesSliceIndex: sliceIndex - 4,
          clearContractSlice: true,
        ),
      );
    }
  }

  void clearResumeSelection() {
    emit(state.copyWith(clearLegacyResumeSelection: true));
    emit(state.copyWith(clearContractSlice: true, clearApostillesSlice: true));
  }
}
