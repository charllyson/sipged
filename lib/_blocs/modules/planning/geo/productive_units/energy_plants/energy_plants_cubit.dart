// lib/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'energy_plants_repository.dart';
import 'energy_plants_state.dart';

class EnergyPlantsCubit extends Cubit<EnergyPlantsState> {
  EnergyPlantsCubit({required EnergyPlantsRepository repository})
      : _repo = repository,
        super(const EnergyPlantsState());

  final EnergyPlantsRepository _repo;

  // Cache de markers por UF
  final Map<String, List<EnergyPlantMarkerData>> _cacheByUf = {};

  // Controle de concorrência (mesma ideia do RoadsFederal)
  int _requestSeq = 0;

  Future<void> loadByUF(
      String uf, {
        bool forceRefresh = false,
      }) async {
    final ufNorm = uf.trim().toUpperCase();
    final reqId = ++_requestSeq;

    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      if (!forceRefresh && _cacheByUf.containsKey(ufNorm)) {
        emit(state.copyWith(isLoading: false, markers: _cacheByUf[ufNorm]!));
        return;
      }

      final rows = await _repo.fetchByUF(ufNorm);

      if (reqId != _requestSeq) return;

      final out = <EnergyPlantMarkerData>[];

      for (final r in rows) {
        final docId = (r['_id'] ?? '').toString();

        final name = (r['name'] ?? r['nome'] ?? '').toString().trim();
        final code = (r['code'] ?? r['codigo'] ?? '').toString().trim();
        final owner = (r['owner'] ??
            r['operator'] ??
            r['concessionaria'] ??
            '')
            .toString()
            .trim();

        final ufRow = (r['uf'] ?? ufNorm).toString().trim().toUpperCase();

        // 1) tenta padrões (GeoPoint / latLng / location / GeoJSON etc.)
        var point = _repo.parsePoint(r['point'] ?? r['latLng'] ?? r['location']);

        // 2) fallback: tenta ler do "row" (NumCoordN/NumCoordE etc.)
        point ??= _repo.parsePointFromRow(r);

        if (point == null) {
          continue;
        }

        // filtros básicos para evitar "sumir" no mapa por dados ruins
        if (point.latitude == 0 || point.longitude == 0) {
          continue;
        }

        if (!_repo.isValidLatLng(point.latitude, point.longitude)) {
          continue;
        }

        out.add(
          EnergyPlantMarkerData(
            docId: docId,
            uf: ufRow,
            name: name.isEmpty ? 'Usina de Energia' : name,
            code: code.isEmpty ? null : code,
            owner: owner.isEmpty ? null : owner,
            point: point,
          ),
        );
      }

      _cacheByUf[ufNorm] = out;

      if (reqId != _requestSeq) return;

      emit(state.copyWith(isLoading: false, markers: out));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearCache() => _cacheByUf.clear();


}
