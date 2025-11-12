import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_sections.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'dotacao_repository.dart';

part 'dotacao_event.dart';
part 'dotacao_state.dart';

class DotacaoBloc extends Bloc<DotacaoEvent, DotacaoState> {
  final DotacaoRepository repo;
  DotacaoBloc(this.repo) : super(DotacaoState.initial()) {
    on<DotacaoLoadRequested>(_onLoad);
    on<DotacaoSaveRequested>(_onSaveAll);
    on<DotacaoSaveOneSectionRequested>(_onSaveOne);
    on<DotacaoClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  Future<void> _onLoad(DotacaoLoadRequested e, Emitter<DotacaoState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        dotacaoId: ids.dotacaoId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        dotacaoId: ids.dotacaoId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(DotacaoSaveRequested e, Emitter<DotacaoState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        dotacaoId: state.dotacaoId!,
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

  Future<void> _onSaveOne(DotacaoSaveOneSectionRequested e, Emitter<DotacaoState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      final sectionId = state.sectionIds[e.sectionKey];
      if (sectionId == null) {
        emit(state.copyWith(saving: false, saveSuccess: false, error: 'Seção inválida: ${e.sectionKey}'));
        return;
      }

      await repo.saveSection(
        contractId: e.contractId,
        dotacaoId: state.dotacaoId!,
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
