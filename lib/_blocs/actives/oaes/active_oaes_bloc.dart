// lib/_blocs/actives/oaes/active_oaes_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/widgets/map/geo_json_manager.dart';
import 'active_oaes_data.dart';
import 'active_oaes_event.dart';
import 'active_oaes_repository.dart';
import 'active_oaes_state.dart';

class ActiveOaesBloc extends Bloc<ActiveOaesEvent, ActiveOaesState> {
  // Repositório e GeoJSON internos (não são passados por parâmetro)
  final ActiveOaesRepository _repo = ActiveOaesRepository();
  final GeoJsonManager _geo = GeoJsonManager();

  ActiveOaesBloc() : super(ActiveOaesState()) {
    // Loaders
    on<ActiveOaesWarmupRequested>(_onWarmup);
    on<ActiveOaesRefreshRequested>(_onRefresh);

    // Seleção / Form
    on<ActiveOaesSelectByIndex>(_onSelectByIndex);
    on<ActiveOaesClearSelection>(_onClearSelection);
    on<ActiveOaesFormPatched>(_onFormPatched);

    // Upsert / Delete
    on<ActiveOaesUpsertRequested>(_onUpsert);
    on<ActiveOaesDeleteRequested>(_onDelete);

    // Filtros (pie / região)
    on<ActiveOaesPieFilterChanged>(_onPieFilterChanged);
    on<ActiveOaesRegionFilterChanged>(_onRegionFilterChanged);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<ActiveOaesState> _ensureGeoLoaded(ActiveOaesState st) async {
    if (st.geoLoaded) return st;
    return await ActiveOaesState.loadGeoRegionals(st, _geo);
  }

  // ---------------------------------------------------------------------------
  // Loaders
  // ---------------------------------------------------------------------------
  Future<void> _onWarmup(
      ActiveOaesWarmupRequested e,
      Emitter<ActiveOaesState> emit,
      ) async {
    emit(state.copyWith(loadStatus: ActiveOaesLoadStatus.loading, error: null));
    try {
      final list = await _repo.fetchAll();

      var next = state.copyWith(
        initialized: true,
        all: list,
        loadStatus: ActiveOaesLoadStatus.success,
        error: null,
      );

      // carrega GeoJSON (se ainda não carregado)
      next = await _ensureGeoLoaded(next);

      emit(next);
    } catch (err) {
      emit(state.copyWith(
        loadStatus: ActiveOaesLoadStatus.failure,
        error: err.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      ActiveOaesRefreshRequested e,
      Emitter<ActiveOaesState> emit,
      ) async {
    emit(state.copyWith(loadStatus: ActiveOaesLoadStatus.loading, error: null));
    try {
      final list = await _repo.fetchAll();

      var next = state.copyWith(
        all: list,
        loadStatus: ActiveOaesLoadStatus.success,
        error: null,
      );

      // garante GeoJSON disponível
      next = await _ensureGeoLoaded(next);

      emit(next);
    } catch (err) {
      emit(state.copyWith(
        loadStatus: ActiveOaesLoadStatus.failure,
        error: err.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Seleção / Form
  // ---------------------------------------------------------------------------
  void _onSelectByIndex(
      ActiveOaesSelectByIndex e,
      Emitter<ActiveOaesState> emit,
      ) {
    if (e.index < 0 || e.index >= state.all.length) return;
    final selected = state.all[e.index];
    emit(state.copyWith(
      selectedIndex: e.index,
      form: ActiveOaesData.fromData(selected),
    ));
  }

  void _onClearSelection(
      ActiveOaesClearSelection e,
      Emitter<ActiveOaesState> emit,
      ) {
    emit(state.copyWith(
      selectedIndex: null,
      form: ActiveOaesData(),
    ));
  }

  void _onFormPatched(
      ActiveOaesFormPatched e,
      Emitter<ActiveOaesState> emit,
      ) {
    emit(state.copyWith(form: e.data));
  }

  // ---------------------------------------------------------------------------
  // Upsert / Delete
  // ---------------------------------------------------------------------------
  Future<void> _onUpsert(
      ActiveOaesUpsertRequested e,
      Emitter<ActiveOaesState> emit,
      ) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      final saved = await _repo.upsert(e.data);

      final all = List<ActiveOaesData>.from(state.all);
      final idx = all.indexWhere((a) => a.id == saved.id);
      if (idx == -1) {
        all.add(saved);
      } else {
        all[idx] = saved;
      }

      emit(state.copyWith(
        all: all,
        form: ActiveOaesData(),
        selectedIndex: null,
        saving: false,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        saving: false,
        error: err.toString(),
      ));
    }
  }

  Future<void> _onDelete(
      ActiveOaesDeleteRequested e,
      Emitter<ActiveOaesState> emit,
      ) async {
    emit(state.copyWith(saving: true, error: null));
    try {
      await _repo.deleteById(e.id);
      final all = List<ActiveOaesData>.from(state.all)
        ..removeWhere((a) => a.id == e.id);

      emit(state.copyWith(
        all: all,
        saving: false,
        form: ActiveOaesData(),
        selectedIndex: null,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        saving: false,
        error: err.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Filtros (impactam o mapa e as contagens)
  // ---------------------------------------------------------------------------
  void _onPieFilterChanged(
      ActiveOaesPieFilterChanged e,
      Emitter<ActiveOaesState> emit,
      ) {
    // e.pieIndex pode ser null -> limpa filtro
    emit(state.copyWith(selectedPieIndexFilter: e.pieIndex));
  }

  void _onRegionFilterChanged(
      ActiveOaesRegionFilterChanged e,
      Emitter<ActiveOaesState> emit,
      ) {
    // e.region pode ser null -> limpa filtro
    emit(state.copyWith(selectedRegionFilter: e.region));
  }
}
