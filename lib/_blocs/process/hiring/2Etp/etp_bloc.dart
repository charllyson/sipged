import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'etp_repository.dart';

part 'etp_event.dart';
part 'etp_state.dart';

class EtpBloc extends Bloc<EtpEvent, EtpState> {
  final EtpRepository repo;
  EtpBloc(this.repo) : super(EtpState.initial()) {
    on<EtpLoadRequested>(_onLoad);
    on<EtpSaveRequested>(_onSaveAll);
    on<EtpSaveOneSectionRequested>(_onSaveOne);
    on<EtpClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) {
        emit(state.copyWith(saveSuccess: false));
      }
    });
  }

  Future<void> _onLoad(EtpLoadRequested e, Emitter<EtpState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        etpId: ids.etpId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        etpId: ids.etpId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(EtpSaveRequested e, Emitter<EtpState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        etpId: state.etpId!,
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

  Future<void> _onSaveOne(EtpSaveOneSectionRequested e, Emitter<EtpState> emit) async {
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
        etpId: state.etpId!,
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
