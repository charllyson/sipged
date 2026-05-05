// lib/_blocs/modules/contracts/hiring/10Arquivamento/termo_arquivamento_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'termo_arquivamento_data.dart';
import 'termo_arquivamento_repository.dart';
import 'termo_arquivamento_state.dart';

class TermoArquivamentoCubit extends Cubit<TermoArquivamentoState> {
  TermoArquivamentoCubit(TermoArquivamentoRepository repo)
      : repo = repo,
        super(TermoArquivamentoState.initial());

  final TermoArquivamentoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  // ===========================================================
  // HELPER PÚBLICO: obter TermoArquivamentoData pelo contractId
  // ===========================================================
  Future<TermoArquivamentoData?> getDataForContract(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<TermoArquivamentoData?>.value(null);
    }

    return repo.readDataForContract(cleanContractId);
  }

  // ===========================================================
  // LOAD
  // ===========================================================
  Future<void> load(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          error: 'Contrato não informado.',
          clearContractId: true,
          clearTaId: true,
          sectionIds: const <String, String>{},
          sectionsData: const <String, Map<String, dynamic>>{},
        ),
      );
      return;
    }

    final reqId = ++_loadSeq;

    emit(
      state.copyWith(
        loading: true,
        saving: false,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);

      if (!_alive || reqId != _loadSeq) return;

      final data = await repo.loadAllSections(
        contractId: cleanContractId,
        taId: ids.taId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          taId: ids.taId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
          clearError: true,
        ),
      );
    } catch (err) {
      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // SAVE ALL
  // ===========================================================
  Future<void> saveAll({
    required String contractId,
    required SectionsMap sectionsData,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Contrato não informado.',
        ),
      );
      return;
    }

    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        loading: false,
        saving: true,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSectionsBatch(
        contractId: cleanContractId,
        taId: ids.taId,
        sectionIds: ids.sectionIds,
        sectionsData: sectionsData,
      );

      if (!_alive || reqId != _saveSeq) return;

      final merged = <String, Map<String, dynamic>>{
        ...state.sectionsData,
      };

      sectionsData.forEach((key, value) {
        merged[key] = <String, dynamic>{
          ...(merged[key] ?? const <String, dynamic>{}),
          ...value,
        };
      });

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          contractId: cleanContractId,
          taId: ids.taId,
          sectionIds: ids.sectionIds,
          sectionsData: merged,
          clearError: true,
        ),
      );
    } catch (err) {
      if (!_alive || reqId != _saveSeq) return;

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // SAVE ONE SECTION
  // ===========================================================
  Future<void> saveOneSection({
    required String contractId,
    required String sectionKey,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanSectionKey = sectionKey.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Contrato não informado.',
        ),
      );
      return;
    }

    if (cleanSectionKey.isEmpty) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Seção não informada.',
        ),
      );
      return;
    }

    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        loading: false,
        saving: true,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);
      final sectionDocId = ids.sectionIds[cleanSectionKey];

      if (sectionDocId == null || sectionDocId.trim().isEmpty) {
        if (!_alive || reqId != _saveSeq) return;

        emit(
          state.copyWith(
            saving: false,
            saveSuccess: false,
            taId: ids.taId,
            sectionIds: ids.sectionIds,
            error: 'Seção inválida: $cleanSectionKey',
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        taId: ids.taId,
        sectionKey: cleanSectionKey,
        sectionDocId: sectionDocId,
        data: data,
      );

      if (!_alive || reqId != _saveSeq) return;

      final merged = <String, Map<String, dynamic>>{
        ...state.sectionsData,
      };

      merged[cleanSectionKey] = <String, dynamic>{
        ...(merged[cleanSectionKey] ?? const <String, dynamic>{}),
        ...data,
      };

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          contractId: cleanContractId,
          taId: ids.taId,
          sectionIds: ids.sectionIds,
          sectionsData: merged,
          clearError: true,
        ),
      );
    } catch (err) {
      if (!_alive || reqId != _saveSeq) return;

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // CLEAR FLAGS
  // ===========================================================
  void clearSuccessFlag() {
    if (state.saveSuccess) {
      emit(state.copyWith(saveSuccess: false));
    }
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }
}