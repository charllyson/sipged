import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'parecer_juridico_repository.dart';
import 'parecer_juridico_sections.dart';

part 'parecer_juridico_event.dart';
part 'parecer_juridico_state.dart';

class ParecerJuridicoBloc extends Bloc<ParecerEvent, ParecerState> {
  final ParecerJuridicoRepository repo;

  ParecerJuridicoBloc(this.repo) : super(ParecerState.initial()) {
    on<ParecerLoadRequested>(_onLoad);
    on<ParecerSaveRequested>(_onSaveAll);
    on<ParecerSaveOneSectionRequested>(_onSaveOne);
    on<ParecerClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  Future<void> _onLoad(ParecerLoadRequested e, Emitter<ParecerState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        parecerId: ids.parecerId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        parecerId: ids.parecerId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(ParecerSaveRequested e, Emitter<ParecerState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        parecerId: state.parecerId!,
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

  Future<void> _onSaveOne(ParecerSaveOneSectionRequested e, Emitter<ParecerState> emit) async {
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
        parecerId: state.parecerId!,
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
