// lib/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'habilitacao_data.dart';       // 🆕 igual ao dfd_data.dart
import 'habilitacao_repository.dart';
import 'habilitacao_state.dart';

class HabilitacaoCubit extends Cubit<HabilitacaoState> {
  final HabilitacaoRepository repo;

  HabilitacaoCubit(this.repo) : super(HabilitacaoState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter HabilitacaoData pelo contractId
  // (mesma ideia do DfdCubit.getDataForContract)
  // ===========================================================
  ///
  /// Uso típico:
  ///   final hab = await context
  ///       .getDataForContract(contractId);
  ///
  Future<HabilitacaoData?> getDataForContract(String contractId) {
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
      // estrutura fixa: habId = "main", sectionIds = {sec: "main"}
      final ids = await repo.ensureStructure(contractId);

      // carrega todas as seções
      final data = await repo.loadAllSections(
        contractId: contractId,
        habId: ids.habId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          habId: ids.habId,
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
        habId: state.habId!,
        sectionIds: state.sectionIds,
        sectionsData: sectionsData,
      );

      // Faz merge no estado local (igual DfdCubit)
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
      // mesmo padrão do DfdCubit: só seta error e retorna
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
        habId: state.habId!,
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
