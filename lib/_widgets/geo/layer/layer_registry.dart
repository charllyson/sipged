import 'package:flutter/foundation.dart';

/// Centraliza a configuração de "conectar/importar" por layerId.
///
/// A ideia é: o Drawer só sabe o ID.
/// Quem decide:
/// - se suporta connect
/// - qual path Firestore
/// - (opcional) tipo de geometria / política
/// é este registry.
class LayerRegistry {
  LayerRegistry._();

  /// ✅ Ajuste aqui o "prefixo" base que você quer usar no Firestore.
  ///
  /// Exemplos comuns:
  /// - 'planning_geo' / 'layers' / etc.
  /// - 'temContracts' no seu outro módulo (aqui é geo, então provavelmente não)
  static const String baseCollection = 'geo_layers';

  /// Mapeamento: layerId -> path Firestore (coleção destino).
  ///
  /// IMPORTANTE:
  /// - Retorne um path de COLLECTION (não doc) para importar/ler features.
  /// - Se você usa subcoleção "features", padronize.
  static const Map<String, String> _pathsById = {
    // --- Recursos Naturais
    'sigmine': '$baseCollection/sigmine/features',
    'land_use_cover': '$baseCollection/land_use_cover/features',
    'deforestation': '$baseCollection/deforestation/features',

    // --- Unidades Produtivas
    'units_energy': '$baseCollection/units_energy/features',
    'units_agriculture': '$baseCollection/units_agriculture/features',

    // --- História e Cultura
    'ucs': '$baseCollection/ucs/features',
    'ti': '$baseCollection/ti/features',
    'sitios_arqueologicos': '$baseCollection/sitios_arqueologicos/features',

    // --- Transportes
    'federal_road': '$baseCollection/federal_road/features',
    'state_road': '$baseCollection/state_road/features',
    'municipal_road': '$baseCollection/municipal_road/features',
    'railways': '$baseCollection/railways/features',
    'airport': '$baseCollection/airport/features',
    'harbor': '$baseCollection/harbor/features',
    'urban_bus_lines': '$baseCollection/urban_bus_lines/features',
    'metro_lines': '$baseCollection/metro_lines/features',
    'transport_hubs': '$baseCollection/transport_hubs/features',
    'od_flows': '$baseCollection/od_flows/features',

    // --- Hidrografia
    'rain_gauge': '$baseCollection/rain_gauge/features',
    'weather_open_meteo': '$baseCollection/weather_open_meteo/features',
    'rives': '$baseCollection/rives/features',
    'dams': '$baseCollection/dams/features',

    // --- Limites / IBGE
    'ibge_cities': '$baseCollection/ibge_cities/features',
    'ibge_agregados': '$baseCollection/ibge_agregados/features',

    // --- Socioeconômico
    'ibge_population': '$baseCollection/ibge_population/features',
    'ibge_pib': '$baseCollection/ibge_pib/features',
    'ibge_education': '$baseCollection/ibge_education/features',
    'ibge_health': '$baseCollection/ibge_health/features',
    'ibge_social_vulnerability': '$baseCollection/ibge_social_vulnerability/features',
    'economic_activity_heatmap': '$baseCollection/economic_activity_heatmap/features',

    // --- Risco e Resiliência
    'flood_risk': '$baseCollection/flood_risk/features',
    'landslide_risk': '$baseCollection/landslide_risk/features',
    'critical_events_history': '$baseCollection/critical_events_history/features',

    // --- Infra
    'public_schools': '$baseCollection/public_schools/features',
    'health_units': '$baseCollection/health_units/features',
    'security_units': '$baseCollection/security_units/features',
    'urban_equipment': '$baseCollection/urban_equipment/features',
  };

  /// Layers que NÃO devem ter connect (ex.: base maps).
  static const Set<String> _noConnectIds = {
    'base_normal',
    'base_satellite',

    // pastas/grupos (por segurança, mesmo que nunca chegue como folha)
    'localidades',
    'obras_arte',
    'recursos_naturais',
    'general_units',
    'historia_cultura',
    'transports',
    'hidrografia',
    'limite_territorial',
    'socioeconomico',
    'risco_resiliencia',
    'infra_urbana',
  };

  /// Retorna o path Firestore (coleção) para um layerId.
  static String? pathFor(String layerId) => _pathsById[layerId];

  /// Se o layer suporta "connect".
  static bool supportsConnect(String layerId) {
    if (_noConnectIds.contains(layerId)) return false;
    return _pathsById.containsKey(layerId);
  }

  /// Útil para logs e debug rápido.
  static void debugDumpMissing(Set<String> layerIds) {
    final missing = <String>[];
    for (final id in layerIds) {
      if (!_noConnectIds.contains(id) && !_pathsById.containsKey(id)) {
        missing.add(id);
      }
    }
  }
}
