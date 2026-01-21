// lib/_blocs/planning/highway_domain/planning_highway_domain_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'planning_highway_domain_event.dart';
import 'planning_highway_domain_state.dart';
import 'planning_highway_domain_repository.dart';

class PlanningHighwayDomainBloc
    extends Bloc<PlanningHighwayDomainEvent, PlanningHighwayDomainState> {
  final PlanningHighwayDomainRepository _repo;

  PlanningHighwayDomainBloc({PlanningHighwayDomainRepository? repository})
      : _repo = repository ?? PlanningHighwayDomainRepository(),
        super(const PlanningHighwayDomainState()) {
    on<PlanningHighwayDomainRefreshRequested>(_onRefresh);
    on<PlanningHighwayDomainImportBatchRequested>(_onImportBatch);
    on<PlanningHighwayDomainDeleteAllRequested>(_onDeleteAll);
    on<PlanningHighwayDomainVisibilityToggled>(_onToggleVisible);
    on<PlanningHighwayDomainFeatureSelected>(
          (e, emit) => emit(state.copyWith(selectedId: e.id)),
    );
  }

  Future<void> _onRefresh(
      PlanningHighwayDomainRefreshRequested e, Emitter<PlanningHighwayDomainState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repo.fetchAll(contractId: e.contractId);
      emit(state.copyWith(
        initialized: true,
        loading: false,
        items: items,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  Future<void> _onImportBatch(
      PlanningHighwayDomainImportBatchRequested e, Emitter<PlanningHighwayDomainState> emit) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      await _repo.importBatch(
        contractId: e.contractId,
        linhas: e.linhasPrincipais,
        geometrias: e.geometrias,
      );
      // Recarrega após import
      final items = await _repo.fetchAll(contractId: e.contractId);
      emit(state.copyWith(
        saving: false,
        items: items,
        initialized: true,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  Future<void> _onDeleteAll(
      PlanningHighwayDomainDeleteAllRequested e, Emitter<PlanningHighwayDomainState> emit) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      await _repo.deleteAll(contractId: e.contractId);
      emit(state.copyWith(saving: false, items: const []));
    } catch (err) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  void _onToggleVisible(
      PlanningHighwayDomainVisibilityToggled e, Emitter<PlanningHighwayDomainState> emit) {
    final next = e.visible ?? !state.visible;
    emit(state.copyWith(visible: next));
  }
}
