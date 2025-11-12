// lib/_blocs/process/hiring/1Dfd/dfd_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'dfd_repository.dart';

part 'dfd_event.dart';
part 'dfd_state.dart';

class DfdBloc extends Bloc<DfdEvent, DfdState> {
  final DfdRepository repo;

  DfdBloc(this.repo) : super(DfdState.initial()) {
    on<DfdLoadRequested>(_onLoad);
    on<DfdSaveRequested>(_onSaveAll);
    on<DfdSaveOneSectionRequested>(_onSaveOne);
    on<DfdClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  Future<void> _onLoad(DfdLoadRequested e, Emitter<DfdState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureDfdStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(DfdSaveRequested e, Emitter<DfdState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        dfdId: state.dfdId!,
        sectionIds: state.sectionIds,
        sectionsData: e.sectionsData,
      );

      // merge local para refletir imediatamente
      final merged = {...state.sectionsData};
      e.sectionsData.forEach((k, v) {
        merged[k] = {...(merged[k] ?? const {}), ...v};
      });

      emit(state.copyWith(saving: false, saveSuccess: true, sectionsData: merged));
    } catch (err) {
      emit(state.copyWith(saving: false, saveSuccess: false, error: err.toString()));
    }
  }

  Future<void> _onSaveOne(DfdSaveOneSectionRequested e, Emitter<DfdState> emit) async {
    if (!state.hasValidPath) return;
    final sectionId = state.sectionIds[e.sectionKey];
    if (sectionId == null) {
      emit(state.copyWith(error: 'Seção inválida: ${e.sectionKey}'));
      return;
    }

    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSection(
        contractId: e.contractId,
        dfdId: state.dfdId!,
        sectionKey: e.sectionKey,
        sectionDocId: sectionId,
        data: e.data,
      );

      final merged = {...state.sectionsData};
      merged[e.sectionKey] = {...(merged[e.sectionKey] ?? const {}), ...e.data};

      emit(state.copyWith(saving: false, saveSuccess: true, sectionsData: merged));
    } catch (err) {
      emit(state.copyWith(saving: false, saveSuccess: false, error: err.toString()));
    }
  }
}
