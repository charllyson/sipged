// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';
import 'parecer_juridico_repository.dart';
import 'parecer_juridico_state.dart';
import 'parecer_juridico_data.dart'; // 🆕 modelo equivalente a DfdData/HabilitacaoData

class ParecerJuridicoCubit extends Cubit<ParecerState> {
  final ParecerJuridicoRepository repo;

  ParecerJuridicoCubit(this.repo) : super(ParecerState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter ParecerJuridicoData pelo contractId
  // ===========================================================
  ///
  /// Uso típico:
  ///   final parecer = await context
  ///       .read<ParecerJuridicoCubit>()
  ///       .getDataForContract(contractId);
  ///
  Future<ParecerJuridicoData?> getDataForContract(String contractId) {
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
      // estrutura fixa: parecerId = "main", sectionIds = {sec: "main"}
      final ids = await repo.ensureStructure(contractId);

      // carrega todas as seções
      final data = await repo.loadAllSections(
        contractId: contractId,
        parecerId: ids.parecerId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          parecerId: ids.parecerId,
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
        parecerId: state.parecerId!,
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
      // segue o padrão dos outros cubits: só seta error
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
        parecerId: state.parecerId!,
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
