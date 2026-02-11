import 'package:flutter_bloc/flutter_bloc.dart';

import 'aerodromes_repository.dart';
import 'aerodromes_state.dart';

class AerodromesCubit extends Cubit<AerodromesState> {
  AerodromesCubit({required AerodromesRepository repository})
      : _repo = repository,
        super(const AerodromesState());

  final AerodromesRepository _repo;

  final Map<String, List<AerodromeMarkerData>> _cacheByUf = {};
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

      final out = <AerodromeMarkerData>[];

      for (final r in rows) {
        final docId = (r['_id'] ?? '').toString();

        final name = (r['name'] ?? r['nome'] ?? r['NomAerodromo'] ?? '')
            .toString()
            .trim();
        final code = (r['code'] ?? r['codigo'] ?? r['CodOACI'] ?? r['icao'] ?? '')
            .toString()
            .trim();
        final owner = (r['owner'] ?? r['operator'] ?? r['administrador'] ?? '')
            .toString()
            .trim();

        final ufRow = (r['uf'] ?? ufNorm).toString().trim().toUpperCase();

        var point = _repo.parsePoint(r['point'] ?? r['latLng'] ?? r['location']);
        point ??= _repo.parsePointFromRow(r);

        if (point == null) {
          continue;
        }

        if (point.latitude == 0 || point.longitude == 0) {
          continue;
        }

        if (!_repo.isValidLatLng(point.latitude, point.longitude)) {
          continue;
        }

        out.add(
          AerodromeMarkerData(
            docId: docId,
            uf: ufRow,
            name: name.isEmpty ? 'Aeródromo' : name,
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
