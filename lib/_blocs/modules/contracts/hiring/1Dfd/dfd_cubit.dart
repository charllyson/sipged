// lib/_blocs/modules/contracts/hiring/dfd/dfd_cubit.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'dfd_data.dart';
import 'dfd_repository.dart';
import 'dfd_state.dart';

class DfdCubit extends Cubit<DfdState> {
  DfdCubit({DfdRepository? repository})
      : repo = repository ?? DfdRepository(),
        super(DfdState.initial());

  final DfdRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  Future<DfdData?> getDataForContract(String contractId) {
    return repo.readDataForContract(contractId);
  }

  Future<void> load(String contractId) async {
    final reqId = ++_loadSeq;

    emit(
      state.copyWith(
        loading: true,
        saving: false,
        error: null,
        saveSuccess: false,
        contractId: contractId,
      ),
    );

    try {
      final ids = await repo.ensureStructure(contractId);

      // Se um novo load foi disparado, ignora este resultado
      if (!_alive || reqId != _loadSeq) return;

      final data = await repo.loadAllSections(
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
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

  Future<void> saveAll({
    required String contractId,
    required SectionsMap sectionsData,
  }) async {
    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        saving: true,
        loading: false,
        saveSuccess: false,
        error: null,
        contractId: contractId,
      ),
    );

    try {
      final ids = await repo.ensureStructure(contractId);

      if (!_alive || reqId != _saveSeq) return;

      emit(
        state.copyWith(
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
        ),
      );

      await repo.saveSectionsBatch(
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
        sectionsData: sectionsData,
      );

      if (!_alive || reqId != _saveSeq) return;

      final merged = <String, Map<String, dynamic>>{...state.sectionsData};
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
          sectionsData: merged,
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

  /// Salva o DFD e, se necessário, cria/resolve o contractId automaticamente.
  /// Retorna o contractId final (ou null se falhar).
  Future<String?> saveAllWithAutoContract({
    String? contractId,
    required DfdData data,
  }) async {
    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        saving: true,
        loading: false,
        saveSuccess: false,
        error: null,
      ),
    );

    try {
      final baseContractId = contractId ?? state.contractId;
      final finalContractId = await repo.ensureContractAndSaveDfd(
        contractId: baseContractId,
        data: data,
      );

      if (!_alive || reqId != _saveSeq) return finalContractId;

      final ids = await repo.ensureStructure(finalContractId);

      if (!_alive || reqId != _saveSeq) return finalContractId;

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          contractId: finalContractId,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: data.toSectionsMap(),
        ),
      );

      return finalContractId;
    } catch (err) {
      if (!_alive || reqId != _saveSeq) return null;

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> saveOneSection({
    required String contractId,
    required String sectionKey,
    required Map<String, dynamic> data,
  }) async {
    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        saving: true,
        loading: false,
        saveSuccess: false,
        error: null,
        contractId: contractId,
      ),
    );

    try {
      final ids = await repo.ensureStructure(contractId);
      final sectionId = ids.sectionIds[sectionKey];

      if (sectionId == null) {
        if (!_alive || reqId != _saveSeq) return;

        emit(
          state.copyWith(
            saving: false,
            saveSuccess: false,
            error: 'Seção inválida: $sectionKey',
            dfdId: ids.dfdId,
            sectionIds: ids.sectionIds,
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      emit(
        state.copyWith(
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
        ),
      );

      await repo.saveSection(
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionKey: sectionKey,
        sectionDocId: sectionId,
        data: data,
      );

      if (!_alive || reqId != _saveSeq) return;

      final merged = <String, Map<String, dynamic>>{...state.sectionsData};
      merged[sectionKey] = <String, dynamic>{
        ...(merged[sectionKey] ?? const <String, dynamic>{}),
        ...data,
      };

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          sectionsData: merged,
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

  void clearSuccessFlag() {
    if (state.saveSuccess) {
      emit(state.copyWith(saveSuccess: false));
    }
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(error: null));
    }
  }
}
