// lib/_blocs/process/hiring/5Edital/edital_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'edital_sections.dart';
import 'edital_repository.dart';
import 'edital_data.dart'; // 👈 modelo tipado do Edital
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

part 'edital_event.dart';
part 'edital_state.dart';

class EditalBloc extends Bloc<EditalEvent, EditalState> {
  final EditalRepository repo;

  EditalBloc(this.repo) : super(EditalState.initial()) {
    on<EditalLoadRequested>(_onLoad);
    on<EditalSaveRequested>(_onSaveAll);
    on<EditalSaveOneSectionRequested>(_onSaveOne);

    on<EditalClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) {
        emit(state.copyWith(saveSuccess: false));
      }
    });
  }

  // ===========================================================
  // HELPER PÚBLICO: obter EditalData pelo contractId
  // ===========================================================
  ///
  /// Uso:
  ///   final edital = await context.read<EditalBloc>()
  ///                               .getDataForContract(contractId);
  ///
  Future<EditalData?> getDataForContract(String contractId) {
    return repo.readDataForContract(contractId);
  }

  Future<void> _onLoad(
      EditalLoadRequested e,
      Emitter<EditalState> emit,
      ) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        saveSuccess: false,
      ),
    );

    try {
      // Garante estrutura com doc raiz fixo (ex.: "main") + seções "main"
      final ids = await repo.ensureEditalStructure(e.contractId);

      // Carrega todos os mapas por seção
      final data = await repo.loadAllSections(
        contractId: e.contractId,
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

  Future<void> _onSaveAll(
      EditalSaveRequested e,
      Emitter<EditalState> emit,
      ) async {
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
        contractId: e.contractId,
        editalId: state.editalId!,
        sectionIds: state.sectionIds,
        sectionsData: e.sectionsData,
      );

      final merged = {...state.sectionsData};
      e.sectionsData.forEach((k, v) {
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

  Future<void> _onSaveOne(
      EditalSaveOneSectionRequested e,
      Emitter<EditalState> emit,
      ) async {
    if (!state.hasValidPath) return;

    final sectionId = state.sectionIds[e.sectionKey];
    if (sectionId == null) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Seção inválida: ${e.sectionKey}',
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
        contractId: e.contractId,
        editalId: state.editalId!,
        sectionKey: e.sectionKey,
        sectionDocId: sectionId,
        data: e.data,
      );

      final merged = {...state.sectionsData};
      merged[e.sectionKey] = {
        ...(merged[e.sectionKey] ?? const <String, dynamic>{}),
        ...e.data,
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
}
