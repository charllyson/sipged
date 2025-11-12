import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'cotacao_repository.dart';

part 'cotacao_event.dart';
part 'cotacao_state.dart';

class CotacaoBloc extends Bloc<CotacaoEvent, CotacaoState> {
  final CotacaoRepository repo;
  CotacaoBloc(this.repo) : super(CotacaoState.initial()) {
    on<CotacaoLoadRequested>(_onLoad);
    on<CotacaoSaveRequested>(_onSaveAll);
    on<CotacaoSaveOneSectionRequested>(_onSaveOne);
    on<CotacaoClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });
  }

  // ================= LOAD =================
  Future<void> _onLoad(CotacaoLoadRequested e, Emitter<CotacaoState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        cotacaoId: ids.cotacaoId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        cotacaoId: ids.cotacaoId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  // ================= SAVE ALL =================
  Future<void> _onSaveAll(CotacaoSaveRequested e, Emitter<CotacaoState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        cotacaoId: state.cotacaoId!,
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
  Future<void> _onSaveOne(CotacaoSaveOneSectionRequested e, Emitter<CotacaoState> emit) async {
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
        cotacaoId: state.cotacaoId!,
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
