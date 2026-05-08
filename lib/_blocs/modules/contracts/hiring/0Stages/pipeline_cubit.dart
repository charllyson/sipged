// lib/_blocs/modules/contracts/hiring/0Stages/pipeline_cubit.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';
import 'pipeline_progress.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';

@immutable
class PipelineState {
  final bool loading;
  final Map<String, bool> completed;    // stageKey -> (approved||completed)
  final Map<String, bool> forceEnabled; // Overrides manuais por etapa
  final String? error;

  const PipelineState({
    required this.loading,
    required this.completed,
    required this.forceEnabled,
    this.error,
  });

  factory PipelineState.initial() =>
      const PipelineState(loading: false, completed: {}, forceEnabled: {});

  PipelineState copyWith({
    bool? loading,
    Map<String, bool>? completed,
    Map<String, bool>? forceEnabled,
    String? error,
  }) {
    return PipelineState(
      loading: loading ?? this.loading,
      completed: completed ?? this.completed,
      forceEnabled: forceEnabled ?? this.forceEnabled,
      error: error,
    );
  }
}

class PipelineCubit extends Cubit<PipelineState> {
  final PipelineProgress service;
  final ProgressRepository progressRepo;
  String contractId;

  // Subscrições por etapa (escuta approved/completed do doc raiz)
  final Map<String, StreamSubscription<Map<String, bool>>> _stageSubs = {};

  PipelineCubit({
    required this.service,
    required this.progressRepo,
    required this.contractId,
  }) : super(PipelineState.initial());

  Future<void> refresh() async {
    if (contractId.isEmpty) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      final all = await service.loadAll(contractId: contractId);
      emit(state.copyWith(loading: false, completed: all));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> setContract(String newId) async {
    if (newId == contractId) return;
    await _cancelAllWatches();
    contractId = newId;
    emit(PipelineState.initial().copyWith(loading: true));
    await refresh();
    await watchChain(); // agora escuta TODAS as etapas
  }

  bool isCompleted(String stageKey) => state.completed[stageKey] == true;

  bool _isEnabledByOrder(String stageKey) {
    final idx = HiringStageKey.ordered.indexOf(stageKey);
    if (idx < 0) return false;
    if (idx == 0) return true; // primeira etapa sempre liberada
    for (int i = 0; i < idx; i++) {
      final prev = HiringStageKey.ordered[i];
      if (!isCompleted(prev)) return false;
    }
    return true;
  }

  /// Uma etapa está habilitada se:
  /// - forceEnabled == true, ou
  /// - todas as anteriores concluídas (approved||completed).
  bool isStageEnabled(String stageKey) {
    if (state.forceEnabled[stageKey] == true) return true;
    return _isEnabledByOrder(stageKey);
  }

  void setStageEnabled(String stageKey, bool enabled) {
    final map = Map<String, bool>.from(state.forceEnabled);
    map[stageKey] = enabled;
    emit(state.copyWith(forceEnabled: map));
  }

  /// Assina TODAS as etapas na ordem.
  ///
  /// 🔑 Agora escutamos a *coleção* da etapa:
  /// - Quando o primeiro doc é criado (ex.: Dotação, Publicação),
  ///   o listener já está ativo e passa a refletir approved/completed.
  Future<void> watchChain() async {
    await _cancelAllWatches();
    if (contractId.isEmpty) return;

    for (final stageKey in HiringStageKey.ordered) {
      final collectionName = service.stageCollectionMap[stageKey];
      if (collectionName == null) continue;

      final sub = progressRepo
          .watchStageAutoDoc(
        contractId: contractId,
        collectionName: collectionName,
      )
          .listen((flags) {
        final approved  = flags['approved'] == true;
        final completed = flags['completed'] == true;
        final ok = approved || completed;

        final updated = Map<String, bool>.from(state.completed);
        updated[stageKey] = ok;
        emit(state.copyWith(completed: updated));
      });

      _stageSubs[stageKey] = sub;
    }
  }

  Future<void> _cancelAllWatches() async {
    for (final s in _stageSubs.values) {
      await s.cancel();
    }
    _stageSubs.clear();
  }

  @override
  Future<void> close() async {
    await _cancelAllWatches();
    return super.close();
  }
}
