import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'tr_repository.dart';

part 'tr_event.dart';
part 'tr_state.dart';

class TrBloc extends Bloc<TrEvent, TrState> {
  final TrRepository repo;
  TrBloc(this.repo) : super(TrState.initial()) {
    on<TrLoadRequested>(_onLoad);
    on<TrSaveRequested>(_onSaveAll);
    on<TrSaveOneSectionRequested>(_onSaveOne);
    on<TrClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  // ================= LOAD =================
  Future<void> _onLoad(TrLoadRequested e, Emitter<TrState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        trId: ids.trId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        trId: ids.trId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  // ================= SAVE ALL =================
  Future<void> _onSaveAll(TrSaveRequested e, Emitter<TrState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        trId: state.trId!,
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

  // ================= SAVE ONE SECTION =================
  Future<void> _onSaveOne(TrSaveOneSectionRequested e, Emitter<TrState> emit) async {
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
        trId: state.trId!,
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
