// lib/screens/sectors/planning/miner/planning_layers_controller.dart

import 'package:siged/_services/geography/osm_road/osm_road_data.dart';

/// Controller simples para gerenciar o estado das camadas do PlanningNetwork.
///
/// Ele:
/// - guarda quais camadas estão ativas
/// - guarda qual mapa base está ativo
/// - sabe se SIGMINE / IBGE / Rodovias / Clima / Pluviometria estão visíveis
/// - devolve o filtro de rodovia adequado quando alguma camada é ligada/desligada.
class PlanningLayersController {
  final Set<String> _activeLayerIds;
  String? _activeBaseLayerId;

  PlanningLayersController(Set<String> initialIds)
      : _activeLayerIds = {...initialIds} {
    const baseMapIds = {'base_normal', 'base_satellite'};
    for (final id in _activeLayerIds) {
      if (baseMapIds.contains(id)) {
        _activeBaseLayerId = id;
        break;
      }
    }
  }

  Set<String> get activeLayerIds => _activeLayerIds;
  String? get activeBaseLayerId => _activeBaseLayerId;

  // ========= VISIBILIDADE =========

  bool get isSigMineVisible => _activeLayerIds.contains('sigmine');

  bool get isIbgeVisible => _activeLayerIds.contains('ibge_cities');

  bool get isAnyRoadVisible =>
      _activeLayerIds.contains('federal_road') ||
          _activeLayerIds.contains('state_road') ||
          _activeLayerIds.contains('municipal_road') ||
          _activeLayerIds.contains('outras_rodovias');

  /// Clima (Open-Meteo)
  bool get isWeatherVisible => _activeLayerIds.contains('weather_open_meteo');

  /// Pluviometria (interpolação mensal)
  bool get isRainVisible => _activeLayerIds.contains('rain_gauge');

  // ========= TOGGLE =========

  /// Liga/desliga uma camada e, se for camada de rodovia,
  /// devolve o [RodoviaTipo] a ser aplicado no Cubit.
  ///
  /// Para camadas que não são rodovias (ou mapa base), retorna `null`.
  RodoviaTipo? toggleLayer(String id, bool isActive) {
    const baseMapIds = {'base_normal', 'base_satellite'};

    // ================== MAPAS DE BASE ==================
    if (baseMapIds.contains(id)) {
      if (isActive) {
        for (final b in baseMapIds) {
          _activeLayerIds.remove(b);
        }
        _activeLayerIds.add(id);
        _activeBaseLayerId = id;
      } else {
        _activeLayerIds.remove(id);
        _activeBaseLayerId = null;
      }
      // alteração de base map não afeta rodovia
      return null;
    }

    // ================== CAMADAS NORMAIS ==================
    if (isActive) {
      _activeLayerIds.add(id);
    } else {
      _activeLayerIds.remove(id);
    }

    // ================== RODOVIAS OSM ==================
    final bool federal = _activeLayerIds.contains('federal_road');
    final bool estadual = _activeLayerIds.contains('state_road');
    final bool municipal = _activeLayerIds.contains('municipal_road');
    final bool outras = _activeLayerIds.contains('outras_rodovias');

    if (!federal && !estadual && !municipal && !outras) {
      // nenhuma específica marcada → mostra todas
      return RodoviaTipo.todas;
    }
    if (federal) return RodoviaTipo.federal;
    if (estadual) return RodoviaTipo.estadual;
    if (municipal) return RodoviaTipo.municipal;
    if (outras) return RodoviaTipo.outras;

    return null;
  }
}
