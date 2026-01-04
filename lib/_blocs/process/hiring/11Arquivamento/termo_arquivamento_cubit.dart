// lib/_blocs/process/hiring/10Arquivamento/termo_arquivamento_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'termo_arquivamento_repository.dart';
import 'termo_arquivamento_state.dart';
import 'termo_arquivamento_data.dart'; // 🆕 modelo equivalente aos demais

class TermoArquivamentoCubit extends Cubit<TermoArquivamentoState> {
  final TermoArquivamentoRepository repo;

  TermoArquivamentoCubit(this.repo)
      : super(TermoArquivamentoState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter TermoArquivamentoData pelo contractId
  // ===========================================================
  ///
  /// Uso típico:
  ///   final ta = await context
  ///       .read<TermoArquivamentoCubit>()
  ///       .getDataForContract(contractId);
  ///
  Future<TermoArquivamentoData?> getDataForContract(String contractId) {
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
      // estrutura fixa: taId = "main", sectionIds = {sec: "main"}
      final ids = await repo.ensureStructure(contractId);

      final data = await repo.loadAllSections(
        contractId: contractId,
        taId: ids.taId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          taId: ids.taId,
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
  // SAVE ALL
  // ===========================================================
  Future<void> saveAll({
    required String contractId,
    required SectionsMap sectionsData,
  }) async {
    if (!state.hasValidPath) return;

    emit(
      state.copyWith(
        saving: true,
        error: null,
        saveSuccess: false,
      ),
    );

    try {
      await repo.saveSectionsBatch(
        contractId: contractId,
        taId: state.taId!,
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
          error: err.toString(),
          saveSuccess: false,
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

    final secId = state.sectionIds[sectionKey];
    if (secId == null) {
      // padrão dos outros: só seta o erro
      emit(state.copyWith(error: 'Seção inválida: $sectionKey'));
      return;
    }

    emit(
      state.copyWith(
        saving: true,
        error: null,
        saveSuccess: false,
      ),
    );

    try {
      await repo.saveSection(
        contractId: contractId,
        taId: state.taId!,
        sectionKey: sectionKey,
        sectionDocId: secId,
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
          sectionsData: merged,
          saveSuccess: true,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          error: err.toString(),
          saveSuccess: false,
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
