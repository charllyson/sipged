// lib/_repository/geoJson/geo_json_manager.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/widgets/map/regional_geo_json_class.dart';
import 'geo_json_service.dart';

class GeoJsonManager {
  /// Polígonos regionais carregados do GeoJSON
  final List<PolygonChanged> regionalPolygons = [];

  /// Cores por região (chave normalizada)
  final Map<String, Color> regionColors = {};

  /// Carrega limites regionais do DER/AL e gera um mapa de cores
  Future<void> loadLimitsRegionalsDERAL() async {
    final data = await GeoJsonService.loadPolygonsRegionsOfDERAL(
      assetPath: 'assets/geojson/limits/limites_regionais_der_al.geojson',
    );

    regionalPolygons
      ..clear()
      ..addAll(data);

    _buildDefaultRegionColors();
  }

  // =========== Helpers ===========

  /// Normaliza a chave de região (sem dependência de diacríticos).
  /// Se quiser, troque por removeDiacritics(...).toUpperCase().
  String _norm(String s) => s.trim().toUpperCase();

  /// Define uma paleta básica e atribui cores às regiões carregadas
  void _buildDefaultRegionColors() {
    regionColors.clear();

    // Paleta neutra e legível (pode ajustar ao seu tema)
    final palette = <Color>[
      Colors.blue.shade300,
      Colors.orange.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
      Colors.amber.shade300,
      Colors.cyan.shade300,
      Colors.pink.shade300,
    ];

    var i = 0;
    for (final poly in regionalPolygons) {
      final name = poly.regionName;
      if (name.isEmpty) continue;
      final key = _norm(name);
      regionColors[key] = palette[i % palette.length];
      i++;
    }
  }

  /// Permite sobrescrever as cores por região (ex.: vindo de regras da app)
  void applyRegionColors(Map<String, Color> colors) {
    regionColors
      ..clear()
      ..addAll({
        for (final e in colors.entries) _norm(e.key): e.value,
      });
  }

  /// Obtém a cor para uma região; retorna um fallback se não mapeada
  Color colorForRegion(String regionName, {Color? fallback}) {
    return regionColors[_norm(regionName)] ?? (fallback ?? Colors.white70);
  }
}
