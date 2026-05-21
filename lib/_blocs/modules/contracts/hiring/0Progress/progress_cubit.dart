import 'dart:async';

import 'package:bloc/bloc.dart';

import 'progress_repository.dart';
import 'progress_state.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required this.repo,
  }) : super(
    ProgressState.initial(
      tenantId: repo.tenantId,
    ),
  );

  final ProgressRepository repo;

  StreamSubscription<Map<String, bool>>? _currentStageSub;

  final Map<String, StreamSubscription<Map<String, bool>>> _pipelineSubs =
  <String, StreamSubscription<Map<String, bool>>>{};

  String? _boundContractId;
  String? _boundCollectionName;
  String? _pipelineContractId;

  bool get _alive => !isClosed;

  String get tenantId => repo.tenantId;

  // ===========================================================================
  // BIND DA ETAPA ATUAL
  // ===========================================================================

  Future<void> bindToStage({
    required String contractId,
    required String collectionName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();

    if (cleanContractId.isEmpty || cleanCollectionName.isEmpty) {
      emit(
        state.copyWith(
          loading: false,
          approved: false,
          completed: false,
          error: 'Contrato ou coleção da etapa não informados.',
          clearContractId: cleanContractId.isEmpty,
          clearCollectionName: cleanCollectionName.isEmpty,
        ),
      );
      return;
    }

    if (_boundContractId == cleanContractId &&
        _boundCollectionName == cleanCollectionName) {
      return;
    }

    await _currentStageSub?.cancel();

    _boundContractId = cleanContractId;
    _boundCollectionName = cleanCollectionName;

    emit(
      state.copyWith(
        loading: true,
        tenantId: tenantId,
        contractId: cleanContractId,
        collectionName: cleanCollectionName,
        clearError: true,
      ),
    );

    try {
      _currentStageSub = repo
          .watchApprovalAndCompleted(
        contractId: cleanContractId,
        collectionName: cleanCollectionName,
      )
          .listen(
            (flags) {
          if (!_alive) return;

          emit(
            state.copyWith(
              loading: false,
              approved: flags['approved'] == true,
              completed: flags['completed'] == true,
              tenantId: tenantId,
              contractId: cleanContractId,
              collectionName: cleanCollectionName,
              clearError: true,
            ),
          );
        },
        onError: (Object error) {
          if (!_alive) return;

          emit(
            state.copyWith(
              loading: false,
              error: error.toString(),
            ),
          );
        },
      );
    } catch (error) {
      if (!_alive) return;

      emit(
        state.copyWith(
          loading: false,
          error: error.toString(),
        ),
      );
    }
  }

  // ===========================================================================
  // PIPELINE / CADEIA DE ETAPAS
  // ===========================================================================

  Future<void> setContractForPipeline(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      await _cancelPipelineWatches();

      _pipelineContractId = null;

      emit(
        state.copyWith(
          completedByStage: const <String, bool>{},
          forceEnabledByStage: const <String, bool>{},
          clearContractId: true,
        ),
      );

      return;
    }

    if (_pipelineContractId == cleanContractId && _pipelineSubs.isNotEmpty) {
      return;
    }

    await _cancelPipelineWatches();

    _pipelineContractId = cleanContractId;

    emit(
      state.copyWith(
        loading: true,
        tenantId: tenantId,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    await refreshPipeline();
    await watchPipeline();
  }

  Future<void> refreshPipeline() async {
    final contractId = (_pipelineContractId ?? state.contractId ?? '').trim();

    if (contractId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        tenantId: tenantId,
        contractId: contractId,
        clearError: true,
      ),
    );

    try {
      final completed = await repo.loadAllStages(
        contractId: contractId,
      );

      if (!_alive) return;

      emit(
        state.copyWith(
          loading: false,
          tenantId: tenantId,
          contractId: contractId,
          completedByStage: completed,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!_alive) return;

      emit(
        state.copyWith(
          loading: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> watchPipeline() async {
    final contractId = (_pipelineContractId ?? state.contractId ?? '').trim();

    if (contractId.isEmpty) {
      return;
    }

    await _cancelPipelineWatches();

    for (final stageKey in ProgressRepository.orderedStages) {
      final collectionName = repo.collectionNameOf(stageKey);

      if (collectionName == null) {
        continue;
      }

      final sub = repo
          .watchApprovalAndCompleted(
        contractId: contractId,
        collectionName: collectionName,
      )
          .listen(
            (flags) {
          if (!_alive) return;

          final ok = flags['approved'] == true || flags['completed'] == true;

          final updated = Map<String, bool>.from(state.completedByStage);
          updated[stageKey] = ok;

          emit(
            state.copyWith(
              loading: false,
              tenantId: tenantId,
              contractId: contractId,
              completedByStage: updated,
              clearError: true,
            ),
          );
        },
        onError: (Object error) {
          if (!_alive) return;

          emit(
            state.copyWith(
              loading: false,
              error: error.toString(),
            ),
          );
        },
      );

      _pipelineSubs[stageKey] = sub;
    }
  }

  bool isCompleted(String stageKey) {
    return state.completedByStage[stageKey.trim()] == true;
  }

  bool isStageEnabled(String stageKey) {
    final cleanStageKey = stageKey.trim();

    if (state.forceEnabledByStage[cleanStageKey] == true) {
      return true;
    }

    final index = ProgressRepository.orderedStages.indexOf(cleanStageKey);

    if (index < 0) {
      return false;
    }

    if (index == 0) {
      return true;
    }

    for (int i = 0; i < index; i++) {
      final previousStage = ProgressRepository.orderedStages[i];

      if (!isCompleted(previousStage)) {
        return false;
      }
    }

    return true;
  }

  void setStageEnabled(String stageKey, bool enabled) {
    final cleanStageKey = stageKey.trim();

    if (cleanStageKey.isEmpty) {
      return;
    }

    final updated = Map<String, bool>.from(state.forceEnabledByStage);
    updated[cleanStageKey] = enabled;

    emit(
      state.copyWith(
        forceEnabledByStage: updated,
      ),
    );
  }

  Future<void> _cancelPipelineWatches() async {
    for (final sub in _pipelineSubs.values) {
      await sub.cancel();
    }

    _pipelineSubs.clear();
  }

  @override
  Future<void> close() async {
    await _currentStageSub?.cancel();
    await _cancelPipelineWatches();

    return super.close();
  }
}