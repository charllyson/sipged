// lib/_blocs/modules/contracts/hiring/2Etp/etp_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';
import 'etp_data.dart';
import 'etp_repository.dart';
import 'etp_state.dart';

class EtpCubit extends Cubit<EtpState> {
  final EtpRepository repo;

  EtpCubit(this.repo) : super(EtpState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter EtpData pelo contractId (igual ao DfdCubit)
  // ===========================================================
  ///
  /// Uso típico:
  ///
  Future<EtpData?> getDataForContract(String contractId) {
    return repo.readDataForContract(contractId);
  }

  // ===========================================================
  // LOAD
  // ===========================================================
  Future<void> load(String contractId) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        saveSuccess: false,
      ),
    );

    try {
      // estrutura fixa: etpId = "main", sectionIds = {sec: "main"}
      final ids = await repo.ensureStructure(contractId);

      // carrega todas as seções
      final data = await repo.loadAllSections(
        contractId: contractId,
        etpId: ids.etpId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          etpId: ids.etpId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // SAVE ALL SECTIONS
  // ===========================================================
  Future<void> saveAll({
    required String contractId,
    required SectionsMap sectionsData,
  }) async {
    if (!state.hasValidPath) return;

    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
      ),
    );

    try {
      await repo.saveSectionsBatch(
        contractId: contractId,
        etpId: state.etpId!,
        sectionIds: state.sectionIds,
        sectionsData: sectionsData,
      );

      // Faz merge no estado local (igual ao DfdCubit)
      final merged = {...state.sectionsData};
      sectionsData.forEach((key, value) {
        merged[key] = {
          ...(merged[key] ?? const <String, dynamic>{}),
          ...value,
        };
      });

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          sectionsData: merged,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // SAVE ONE SECTION
  // ===========================================================
  Future<void> saveOneSection({
    required String contractId,
    required String sectionKey,
    required Map<String, dynamic> data,
  }) async {
    if (!state.hasValidPath) return;

    final sectionId = state.sectionIds[sectionKey];
    if (sectionId == null) {
      emit(state.copyWith(error: 'Seção inválida: $sectionKey'));
      return;
    }

    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
      ),
    );

    try {
      await repo.saveSection(
        contractId: contractId,
        etpId: state.etpId!,
        sectionKey: sectionKey,
        sectionDocId: sectionId,
        data: data,
      );

      final merged = {...state.sectionsData};
      merged[sectionKey] = {
        ...(merged[sectionKey] ?? const <String, dynamic>{}),
        ...data,
      };

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          sectionsData: merged,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // CLEAR SUCCESS FLAG
  // ===========================================================
  void clearSuccessFlag() {
    if (state.saveSuccess) {
      emit(state.copyWith(saveSuccess: false));
    }
  }
}
