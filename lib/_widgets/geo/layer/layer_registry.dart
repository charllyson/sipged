import 'package:flutter/material.dart';

enum LayerGeometryKind { point, line, polygon, mixed }

class LayerRegistryEntry {
  final String layerId;
  final String collectionPath;
  final String importTitle;
  final String firestoreTitle;
  final String description;
  final List<String> targetFields;
  final LayerGeometryKind geometryKind;
  final bool supportsConnect;

  const LayerRegistryEntry({
    required this.layerId,
    required this.collectionPath,
    required this.importTitle,
    required this.firestoreTitle,
    required this.description,
    required this.targetFields,
    required this.geometryKind,
    this.supportsConnect = true,
  });
}

class LayerRegistry {
  LayerRegistry._();

  static const Set<String> _noConnectIds = {
    'base_normal',
    'base_satellite',
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

  static const Map<String, String> _aliases = {
    'energy_plants': 'units_energy',
    'usinas_de_energia': 'units_energy',
    'energyPlants': 'units_energy',
    'energy_plant': 'units_energy',
    'usinas_energia': 'units_energy',
    'aeroportos': 'airport',
    'airports': 'airport',
  };

  static const Map<String, LayerRegistryEntry> _entries = {
    'federal_road': LayerRegistryEntry(
      layerId: 'federal_road',
      collectionPath: 'geo/transportes/rodovias_federais',
      importTitle: 'Importar Rodovias Federais',
      firestoreTitle: 'Tabela de atributos - Rodovias Federais',
      description:
      'Importe GeoJSON / KML / KMZ contendo rodovias federais (linhas).',
      targetFields: ['uf', 'name', 'code', 'owner', 'points'],
      geometryKind: LayerGeometryKind.line,
    ),
    'state_road': LayerRegistryEntry(
      layerId: 'state_road',
      collectionPath: 'geo/transportes/rodovias_estaduais',
      importTitle: 'Importar Rodovias Estaduais',
      firestoreTitle: 'Tabela de atributos - Rodovias Estaduais',
      description:
      'Importe GeoJSON / KML / KMZ contendo rodovias estaduais (linhas).',
      targetFields: ['uf', 'name', 'code', 'owner', 'points'],
      geometryKind: LayerGeometryKind.line,
    ),
    'municipal_road': LayerRegistryEntry(
      layerId: 'municipal_road',
      collectionPath: 'geo/transportes/rodovias_municipais',
      importTitle: 'Importar Rodovias Municipais',
      firestoreTitle: 'Tabela de atributos - Rodovias Municipais',
      description:
      'Importe GeoJSON / KML / KMZ contendo rodovias municipais (linhas).',
      targetFields: ['uf', 'name', 'code', 'owner', 'points'],
      geometryKind: LayerGeometryKind.line,
    ),
    'railways': LayerRegistryEntry(
      layerId: 'railways',
      collectionPath: 'geo/transportes/ferrovias',
      importTitle: 'Importar Ferrovias',
      firestoreTitle: 'Tabela de atributos - Ferrovias',
      description: 'Importe GeoJSON / KML / KMZ para cadastro de ferrovias.',
      targetFields: ['uf', 'name', 'code', 'owner', 'points'],
      geometryKind: LayerGeometryKind.line,
    ),
    'units_energy': LayerRegistryEntry(
      layerId: 'units_energy',
      collectionPath: 'geo/productive_units/usinas_de_energia',
      importTitle: 'Importar Usinas de Energia',
      firestoreTitle: 'Tabela de atributos - Usinas de Energia',
      description:
      'Importe GeoJSON / KML / KMZ contendo pontos de usinas de energia.',
      targetFields: ['uf', 'name', 'code', 'owner', 'point'],
      geometryKind: LayerGeometryKind.point,
    ),
    'airport': LayerRegistryEntry(
      layerId: 'airport',
      collectionPath: 'geo/transportes/aeroportos',
      importTitle: 'Importar Aeroportos',
      firestoreTitle: 'Tabela de atributos - Aeroportos',
      description: 'Importe GeoJSON / KML / KMZ contendo pontos de aeroportos.',
      targetFields: ['uf', 'name', 'code', 'owner', 'point'],
      geometryKind: LayerGeometryKind.point,
    ),
  };

  static String normalizeLayerId(String layerId) {
    return _aliases[layerId] ?? layerId;
  }

  static LayerRegistryEntry? entryFor(String layerId) {
    final normalized = normalizeLayerId(layerId);
    return _entries[normalized];
  }

  static String? pathFor(String layerId) {
    return entryFor(layerId)?.collectionPath;
  }

  static bool supportsConnect(String layerId) {
    final normalized = normalizeLayerId(layerId);
    if (_noConnectIds.contains(normalized)) return false;
    return _entries[normalized]?.supportsConnect == true;
  }

  static bool isRegistered(String layerId) {
    final normalized = normalizeLayerId(layerId);
    return _entries.containsKey(normalized);
  }

  static List<String> get registeredLayerIds =>
      _entries.keys.toList(growable: false);

  static IconData iconForGeometry(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return Icons.location_on_outlined;
      case LayerGeometryKind.line:
        return Icons.timeline;
      case LayerGeometryKind.polygon:
        return Icons.hexagon_outlined;
      case LayerGeometryKind.mixed:
        return Icons.category_outlined;
    }
  }
}