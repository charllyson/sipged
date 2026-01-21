// lib/_blocs/modules/planning/geo/localidades/ibge_localidade_repository.dart
import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_data.dart';
import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_location_service.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';

class IBGELocationRepository {
  final IBGELocationService _service;

  IBGELocationRepository({IBGELocationService? service})
      : _service = service ?? IBGELocationService();

  // Cache em memória: evita bater na API toda hora
  static final Map<int, List<PolygonChanged>> _cachePolygonsByUf = {};
  static List<IBGELocationStateData>? _cacheStates;

  // Cache de DETALHES de município: idIbge -> detail
  static final Map<String, IBGELocationDetailData>
  _cacheMunicipioDetailById = {};

  Future<List<IBGELocationStateData>> getStates() async {
    if (_cacheStates != null && _cacheStates!.isNotEmpty) {
      return _cacheStates!;
    }
    final list = await _service.fetchStates();
    _cacheStates = list;
    return list;
  }

  /// Verifica se já existem polígonos em cache para a UF.
  bool hasCachedPolygons(int ufCode) {
    final cached = _cachePolygonsByUf[ufCode];
    return cached != null && cached.isNotEmpty;
  }

  Future<List<PolygonChanged>> getMunicipioPolygonsByUf(int ufCode) async {
    final cached = _cachePolygonsByUf[ufCode];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final polys = await _service.fetchMunicipioPolygonsByUf(ufCode);
    _cachePolygonsByUf[ufCode] = polys;
    return polys;
  }

  /// Detalhes completos de um município, com cache por ID.
  Future<IBGELocationDetailData> getMunicipioDetails(
      String idIbge,
      ) async {
    final cached = _cacheMunicipioDetailById[idIbge];
    if (cached != null) return cached;

    final detail = await _service.fetchMunicipioDetails(idIbge);
    _cacheMunicipioDetailById[idIbge] = detail;
    return detail;
  }

  /// Wrapper para a inferência de UF pela lista de municípios.
  Future<int?> inferUfFromMunicipios(List<String> municipiosAlvo) {
    return _service.inferUfFromMunicipios(municipiosAlvo);
  }
}
