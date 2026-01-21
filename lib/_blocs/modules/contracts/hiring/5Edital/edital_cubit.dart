// lib/_blocs/modules/contracts/hiring/5Edital/edital_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'edital_repository.dart';
import 'edital_data.dart';
import 'edital_state.dart';
import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class EditalCubit extends Cubit<EditalState> {
  final EditalRepository repo;

  EditalCubit(this.repo) : super(EditalState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter EditalData pelo contractId
  // ===========================================================
  ///
  /// Uso:
  ///   final edital = await context.read<EditalCubit>()
  ///                               .getDataForContract(contractId);
  ///
  Future<EditalData?> getDataForContract(String contractId) {
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
      // Estrutura fixa: doc raiz "main" + docs "main" nas subcoleções
      final ids = await repo.ensureEditalStructure(contractId);

      // Carrega todos os mapas por seção
      final data = await repo.loadAllSections(
        contractId: contractId,
        editalId: ids.editalId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          editalId: ids.editalId,
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
        editalId: state.editalId!,
        sectionIds: state.sectionIds,
        sectionsData: sectionsData,
      );

      final merged = {...state.sectionsData};
      sectionsData.forEach((k, v) {
        merged[k] = {
          ...(merged[k] ?? const <String, dynamic>{}),
          ...v,
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
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Seção inválida: $sectionKey',
        ),
      );
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
        editalId: state.editalId!,
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
