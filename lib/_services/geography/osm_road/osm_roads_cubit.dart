import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'osm_road_data.dart';
import 'osm_roads_state.dart';
import 'osm_roads_repository.dart';

class OSMRoadsCubit extends Cubit<OSMRoadsState> {
  final OSMRoadsRepository _repo;

  OSMRoadsCubit({OSMRoadsRepository? repo})
      : _repo = repo ?? OSMRoadsRepository(),
        super(OSMRoadsState.initial());

  // ---------------------------------------------------------------------------
  // CARREGAMENTO PRINCIPAL POR UF
  // ---------------------------------------------------------------------------
  Future<void> loadByUF(String ufSigla) async {
    // se já carregou esta UF uma vez, só reconstrói polylines (por filtro)
    if (state.uf == ufSigla && state.rawRoads.isNotEmpty) {
      _rebuildPolylines();
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final roads = await _repo.loadRoadsForUF(ufSigla);

      emit(
        state.copyWith(
          isLoading: false,
          rawRoads: roads,
          uf: ufSigla,
        ),
      );

      _rebuildPolylines();
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // VIEWPORT (hoje só refaz polylines – não chama Overpass)
  // ---------------------------------------------------------------------------
  void onViewportChanged(LatLng center, double zoom) {
    // Sem BBOX, apenas refaz lista com o filtro atual.
    _rebuildPolylines();
  }

  // ---------------------------------------------------------------------------
  // FILTRO (federal / estadual / municipal / outras / todas)
  // ---------------------------------------------------------------------------
  void updateFilter(RodoviaTipo? tipo) {
    if (tipo == null || tipo == state.filtro) return;

    emit(
      state.copyWith(
        filtro: tipo,
      ),
    );

    _rebuildPolylines();
  }

  // ---------------------------------------------------------------------------
  // RECONSTRUÇÃO DAS POLYLINES A PARTIR DO ESTADO ATUAL
  // ---------------------------------------------------------------------------
  void _rebuildPolylines() {
    if (state.rawRoads.isEmpty) {
      emit(state.copyWith(polylines: const []));
      return;
    }

    final lines = _repo.buildPolylines(
      roads: state.rawRoads,
      filtro: state.filtro,
    );

    emit(
      state.copyWith(
        polylines: lines,
      ),
    );
  }
}
