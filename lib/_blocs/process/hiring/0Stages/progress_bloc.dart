// lib/_blocs/process/hiring/0Stages/progress_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';

import 'progress_state.dart';
import 'progress_repository.dart';

class ProgressCubit extends Cubit<ProgressState> {
  final ProgressRepository repo;
  StreamSubscription<Map<String, bool>>? _sub;

  // Bind atual (para evitar rebind desnecessário)
  String? _boundContractId;
  String? _boundCollection;

  ProgressCubit({required this.repo}) : super(ProgressState.initial());

  /// Faz o "bind" para UMA etapa (ex.: 'dfd', 'edital', 'publicacao')
  ///
  /// Observa sempre:
  ///   contracts/{contractId}/{collectionName}/main
  Future<void> bindToStage({
    required String contractId,
    required String collectionName,
  }) async {
    // evita rebind se já estamos observando o mesmo contrato/coleção
    if (_boundContractId == contractId &&
        _boundCollection == collectionName) {
      return;
    }

    await _sub?.cancel();
    emit(state.copyWith(loading: true, error: null));

    _boundContractId = contractId;
    _boundCollection = collectionName;

    try {
      _sub = repo
          .watchApprovalAndCompleted(
        contractId: contractId,
        collectionName: collectionName,
      )
          .listen((map) {
        final approved = map['approved'] ?? false;
        final completed = map['completed'] ?? false;

        emit(
          state.copyWith(
            loading: false,
            approved: approved,
            completed: completed,
            error: null,
          ),
        );
      });
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
