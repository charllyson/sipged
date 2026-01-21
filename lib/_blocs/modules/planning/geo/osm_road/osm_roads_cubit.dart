/*
// lib/_blocs/modules/planning/geo/osm_road/osm_roads_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'osm_road_data.dart';
import 'osm_roads_state.dart';
import 'osm_roads_repository.dart';

class OSMRoadsCubit extends Cubit<OSMRoadsState> {
  final OSMRoadsRepository _repo;

  Timer? _debounce;
  LatLng? _lastCenter;
  double? _lastZoom;

  OSMRoadsCubit({OSMRoadsRepository? repo})
      : _repo = repo ?? OSMRoadsRepository(),
        super(OSMRoadsState.initial());

  // ✅ quando a UF muda, você só limpa cache e estado.
  void setUF(String ufSigla) {
    _repo.clearCache();
    emit(state.copyWith(uf: ufSigla, rawRoads: const [], polylines: const []));
  }

  void updateFilter(RodoviaTipo? tipo) {
    final next = tipo ?? RodoviaTipo.todas;
    if (next == state.filtro) return;

    emit(state.copyWith(filtro: next));

    // refaz com última viewport, se existir
    if (_lastCenter != null && _lastZoom != null) {
      onViewportChanged(_lastCenter!, _lastZoom!);
    }
  }

  void onViewportChanged(LatLng center, double zoom) {
    _lastCenter = center;
    _lastZoom = zoom;

    // debounce para pan/zoom
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      await _loadForViewport(center, zoom);
    });
  }

  Future<void> _loadForViewport(LatLng center, double zoom) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // carrega e cacheia por tileKey internamente
      final roads = await _repo.loadRoadsForViewport(
        center: center,
        zoom: zoom,
        filtro: state.filtro,
      );

      // guarda raw e monta polylines (polylines respeitam filtro)
      final polylines = _repo.buildPolylines(
        roads: roads,
        filtro: state.filtro,
      );

      emit(
        state.copyWith(
          isLoading: false,
          rawRoads: roads,
          polylines: polylines,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
*/
