import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'termo_arquivamento_repository.dart';

part 'termo_arquivamento_event.dart';
part 'termo_arquivamento_state.dart';

class TermoArquivamentoBloc extends Bloc<TermoArquivamentoEvent, TermoArquivamentoState> {
  final TermoArquivamentoRepository repo;

  TermoArquivamentoBloc(this.repo) : super(TermoArquivamentoState.initial()) {
    on<TermoArquivamentoLoadRequested>(_onLoad);
    on<TermoArquivamentoSaveRequested>(_onSaveAll);
    on<TermoArquivamentoSaveOneSectionRequested>(_onSaveOne);
    on<TermoArquivamentoClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  Future<void> _onLoad(
      TermoArquivamentoLoadRequested e,
      Emitter<TermoArquivamentoState> emit,
      ) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        taId: ids.taId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        taId: ids.taId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(
      TermoArquivamentoSaveRequested e,
      Emitter<TermoArquivamentoState> emit,
      ) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, error: null, saveSuccess: false));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        taId: state.taId!,
        sectionIds: state.sectionIds,
        sectionsData: e.sectionsData,
      );

      final merged = {...state.sectionsData};
      e.sectionsData.forEach((k, v) {
        merged[k] = {...(merged[k] ?? const {}), ...v};
      });

      emit(state.copyWith(saving: false, saveSuccess: true, sectionsData: merged));
    } catch (err) {
      emit(state.copyWith(saving: false, error: err.toString(), saveSuccess: false));
    }
  }

  Future<void> _onSaveOne(
      TermoArquivamentoSaveOneSectionRequested e,
      Emitter<TermoArquivamentoState> emit,
      ) async {
    if (!state.hasValidPath) return;

    final secId = state.sectionIds[e.sectionKey];
    if (secId == null) {
      emit(state.copyWith(error: 'Seção inválida: ${e.sectionKey}'));
      return;
    }

    emit(state.copyWith(saving: true, error: null, saveSuccess: false));
    try {
      await repo.saveSection(
        contractId: e.contractId,
        taId: state.taId!,
        sectionKey: e.sectionKey,
        sectionDocId: secId,
        data: e.data,
      );

      final merged = {...state.sectionsData};
      merged[e.sectionKey] = {...(merged[e.sectionKey] ?? const {}), ...e.data};

      emit(state.copyWith(saving: false, sectionsData: merged, saveSuccess: true));
    } catch (err) {
      emit(state.copyWith(saving: false, error: err.toString(), saveSuccess: false));
    }
  }
}
