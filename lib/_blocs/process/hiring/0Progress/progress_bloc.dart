import 'dart:async';
import 'package:bloc/bloc.dart';

import 'progress_event.dart';
import 'progress_state.dart';
import 'progress_repository.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepository repo;
  StreamSubscription? _sub;

  // Bind atual (para evitar rebind desnecessário)
  String? _boundContractId;
  String? _boundCollection;
  String? _boundStageId;

  ProgressBloc({required this.repo}) : super(ProgressState.initial()) {
    on<ProgressBindRequested>(_onBindRequested);
    on<ProgressSnapshotChanged>(_onSnapshotChanged);
    on<ProgressErrorOccurred>((e, emit) {
      emit(state.copyWith(loading: false, error: e.message));
    });
  }

  Future<void> _onBindRequested(
      ProgressBindRequested event,
      Emitter<ProgressState> emit,
      ) async {
    if (_boundContractId == event.contractId &&
        _boundCollection == event.collectionName &&
        _boundStageId == event.stageId) {
      return;
    }

    await _sub?.cancel();
    emit(state.copyWith(loading: true, error: null));

    _boundContractId = event.contractId;
    _boundCollection = event.collectionName;
    _boundStageId = event.stageId;

    try {
      _sub = repo
          .watchApprovalAndCompleted(
        contractId: event.contractId,
        collectionName: event.collectionName,
        stageId: event.stageId,
      )
          .listen((map) {
        add(ProgressSnapshotChanged(
          approved: map['approved'] ?? false,
          completed: map['completed'] ?? false,
        ));
      });
    } catch (e) {
      add(ProgressErrorOccurred(e.toString()));
    }
  }

  void _onSnapshotChanged(
      ProgressSnapshotChanged event,
      Emitter<ProgressState> emit,
      ) {
    emit(state.copyWith(
      loading: false,
      approved: event.approved,
      completed: event.completed,
      error: null,
    ));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
