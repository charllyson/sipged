import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_sections.dart';
import 'minuta_contrato_repository.dart';

part 'minuta_contrato_event.dart';
part 'minuta_contrato_state.dart';

class MinutaContratoBloc extends Bloc<MinutaEvent, MinutaState> {
  final MinutaContratoRepository repo;
  MinutaContratoBloc(this.repo) : super(MinutaState.initial()) {
    on<MinutaLoadRequested>(_onLoad);
    on<MinutaSaveRequested>(_onSaveAll);
    on<MinutaSaveOneSectionRequested>(_onSaveOne);
    on<MinutaClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  Future<void> _onLoad(MinutaLoadRequested e, Emitter<MinutaState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        minutaId: ids.minutaId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        minutaId: ids.minutaId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(MinutaSaveRequested e, Emitter<MinutaState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        minutaId: state.minutaId!,
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

  Future<void> _onSaveOne(MinutaSaveOneSectionRequested e, Emitter<MinutaState> emit) async {
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
        minutaId: state.minutaId!,
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
