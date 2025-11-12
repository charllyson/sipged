import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'habilitacao_repository.dart';
import 'habilitacao_sections.dart';

part 'habilitacao_event.dart';
part 'habilitacao_state.dart';

class HabilitacaoBloc extends Bloc<HabilitacaoEvent, HabilitacaoState> {
  final HabilitacaoRepository repo;
  HabilitacaoBloc(this.repo) : super(HabilitacaoState.initial()) {
    on<HabilitacaoLoadRequested>(_onLoad);
    on<HabilitacaoSaveRequested>(_onSaveAll);
    on<HabilitacaoSaveOneSectionRequested>(_onSaveOne);
    on<HabilitacaoClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  Future<void> _onLoad(HabilitacaoLoadRequested e, Emitter<HabilitacaoState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        habId: ids.habId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        habId: ids.habId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(HabilitacaoSaveRequested e, Emitter<HabilitacaoState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        habId: state.habId!,
        sectionIds: state.sectionIds,
        sectionsData: e.sectionsData,
      );
      final merged = {...state.sectionsData};
      e.sectionsData.forEach((k, v) {
        merged[k] = {...(merged[k] ?? const {}), ...v};
      });
      emit(state.copyWith(saving: false, saveSuccess: true, sectionsData: merged));
    } catch (err) {
      emit(state.copyWith(saving: false, saveSuccess: false, error: err.toString()));
    }
  }

  Future<void> _onSaveOne(HabilitacaoSaveOneSectionRequested e, Emitter<HabilitacaoState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      final sectionId = state.sectionIds[e.sectionKey];
      if (sectionId == null) {
        emit(state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Seção inválida: ${e.sectionKey}',
        ));
        return;
      }
      await repo.saveSection(
        contractId: e.contractId,
        habId: state.habId!,
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
