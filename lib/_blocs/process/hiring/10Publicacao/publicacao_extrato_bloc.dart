// lib/_blocs/process/hiring/10Publicacao/publicacao_extrato_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'publicacao_extrato_repository.dart';
import 'publicacao_extrato_sections.dart';
import 'publicacao_extrato_data.dart'; // 👈 modelo tipado

part 'publicacao_extrato_event.dart';
part 'publicacao_extrato_state.dart';

class PublicacaoExtratoBloc
    extends Bloc<PublicacaoExtratoEvent, PublicacaoExtratoState> {
  final PublicacaoExtratoRepository repo;

  PublicacaoExtratoBloc(this.repo)
      : super(PublicacaoExtratoState.initial()) {
    on<PublicacaoExtratoLoadRequested>(_onLoad);
    on<PublicacaoExtratoSaveRequested>(_onSaveAll);
    on<PublicacaoExtratoSaveOneSectionRequested>(_onSaveOne);
    on<PublicacaoExtratoClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) {
        emit(state.copyWith(saveSuccess: false));
      }
    });
  }

  // ===========================================================
  // HELPER PÚBLICO: obter PublicacaoExtratoData pelo contractId
  // ===========================================================
  ///
  /// Uso:
  ///   final pub = await context.read<PublicacaoExtratoBloc>()
  ///                            .getDataForContract(contractId);
  ///
  Future<PublicacaoExtratoData?> getDataForContract(String contractId) {
    return repo.readDataForContract(contractId);
  }

  Future<void> _onLoad(
      PublicacaoExtratoLoadRequested e,
      Emitter<PublicacaoExtratoState> emit,
      ) async {
    emit(state.copyWith(
      loading: true,
      error: null,
      saveSuccess: false,
    ));

    try {
      final ids = await repo.ensureStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        pubId: ids.pubId,
        sectionIds: ids.sectionIds,
      );
      emit(state.copyWith(
        loading: false,
        pubId: ids.pubId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: err.toString(),
      ));
    }
  }

  Future<void> _onSaveAll(
      PublicacaoExtratoSaveRequested e,
      Emitter<PublicacaoExtratoState> emit,
      ) async {
    if (!state.hasValidPath) return;

    emit(state.copyWith(
      saving: true,
      error: null,
      saveSuccess: false,
    ));

    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        pubId: state.pubId!,
        sectionIds: state.sectionIds,
        sectionsData: e.sectionsData,
      );

      final merged = {...state.sectionsData};
      e.sectionsData.forEach((k, v) {
        merged[k] = {...(merged[k] ?? const {}), ...v};
      });

      emit(state.copyWith(
        saving: false,
        saveSuccess: true,
        sectionsData: merged,
      ));
    } catch (err) {
      emit(state.copyWith(
        saving: false,
        error: err.toString(),
        saveSuccess: false,
      ));
    }
  }

  Future<void> _onSaveOne(
      PublicacaoExtratoSaveOneSectionRequested e,
      Emitter<PublicacaoExtratoState> emit,
      ) async {
    if (!state.hasValidPath) return;

    final secId = state.sectionIds[e.sectionKey];
    if (secId == null) {
      emit(state.copyWith(error: 'Seção inválida: ${e.sectionKey}'));
      return;
    }

    emit(state.copyWith(
      saving: true,
      error: null,
      saveSuccess: false,
    ));

    try {
      await repo.saveSection(
        contractId: e.contractId,
        pubId: state.pubId!,
        sectionKey: e.sectionKey,
        sectionDocId: secId,
        data: e.data,
      );

      final merged = {...state.sectionsData};
      merged[e.sectionKey] = {
        ...(merged[e.sectionKey] ?? const {}),
        ...e.data,
      };

      emit(state.copyWith(
        saving: false,
        sectionsData: merged,
        saveSuccess: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        saving: false,
        error: err.toString(),
        saveSuccess: false,
      ));
    }
  }
}
