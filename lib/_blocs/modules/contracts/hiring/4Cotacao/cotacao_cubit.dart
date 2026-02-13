// lib/_blocs/modules/contracts/hiring/3Cotacao/cotacao_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class CotacaoCubit extends Cubit<CotacaoState> {
  final CotacaoRepository repo;

  CotacaoCubit(this.repo) : super(CotacaoState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter CotacaoData pelo contractId
  // ===========================================================
  Future<CotacaoData?> getDataForContract(String contractId) {
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
      // estrutura fixa: cotacaoId = "main", sectionIds = {sec: "main"}
      final ids = await repo.ensureStructure(contractId);

      final data = await repo.loadAllSections(
        contractId: contractId,
        cotacaoId: ids.cotacaoId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          cotacaoId: ids.cotacaoId,
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
        cotacaoId: state.cotacaoId!,
        sectionIds: state.sectionIds,
        sectionsData: sectionsData,
      );

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
        cotacaoId: state.cotacaoId!,
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
