import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';

import 'osm_road_service.dart';
import 'osm_road_data.dart';

import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

class OSMRoadsRepository {
  final OSMRoadService _service = const OSMRoadService();

  /// Cache por UF → lista de geometrias já classificadas
  final Map<String, List<RoadGeometry>> _cacheByUF = {};

  // ---------------------------------------------------------------------------
  // CLASSIFICAÇÃO
  // ---------------------------------------------------------------------------

  RodoviaTipo classify(Map<String, dynamic> tags) {
    final ref = (tags['ref'] as String? ?? '').toUpperCase().trim();
    final highway = (tags['highway'] as String? ?? '').toLowerCase();

    // BR-101, BR-316, etc.
    if (ref.startsWith('BR-')) return RodoviaTipo.federal;

    if (SetupData.ufs.any((uf) => ref.startsWith('$uf-'))) {
      return RodoviaTipo.estadual;
    }

    // Se tem ref mas não é federal nem estadual → tratamos como municipal
    if (ref.isNotEmpty) return RodoviaTipo.municipal;

    // Alguns tipos de highway tipicamente municipais
    const municip = [
      'residential',
      'living_street',
      'unclassified',
      'service',
      'tertiary',
      'secondary',
      'primary',
      'track',
    ];
    if (municip.contains(highway)) return RodoviaTipo.municipal;

    return RodoviaTipo.outras;
  }

  // ---------------------------------------------------------------------------
  // LOAD POR UF (BOUNDARY COMPLETO)
  // ---------------------------------------------------------------------------

  Future<List<RoadGeometry>> loadRoadsForUF(String ufSigla) async {
    // 1) Cache já tem esta UF
    if (_cacheByUF.containsKey(ufSigla)) {
      return _cacheByUF[ufSigla]!;
    }

    // 2) Consulta Overpass para o boundary do estado
    final raw = await _service.fetchRoadsForState(ufSigla);

    // 3) Converte para RoadGeometry com tipo
    final roads = raw.map((r) {
      final tipo = classify(r.tags);
      return RoadGeometry(points: r.geometry, tipo: tipo);
    }).toList();

    // 4) Guarda no cache
    _cacheByUF[ufSigla] = roads;
    return roads;
  }

  // ---------------------------------------------------------------------------
  // BUILD (retorna TappableChangedPolyline)
  // ---------------------------------------------------------------------------

  Color _color(RodoviaTipo t) {
    switch (t) {
      case RodoviaTipo.federal:
        return const Color(0xFFE53935); // vermelho forte
      case RodoviaTipo.estadual:
        return const Color(0xFF43A047); // verde
      case RodoviaTipo.municipal:
        return const Color(0xFF546E7A); // cinza azulado
      case RodoviaTipo.outras:
        return const Color(0xFFFFA726); // laranja
      case RodoviaTipo.todas:
      default:
        return const Color(0xFFAB47BC); // roxo genérico
    }
  }

  /// Constrói a lista final de polylines tocáveis para o mapa.
  ///
  /// - Aplica filtro por tipo (`filtro`)
  /// - NÃO simplifica: usa a geometria integral da rodovia.
  List<TappableChangedPolyline> buildPolylines({
    required List<RoadGeometry> roads,
    required RodoviaTipo filtro,
  }) {
    final list = <TappableChangedPolyline>[];

    for (final r in roads) {
      if (filtro != RodoviaTipo.todas && filtro != r.tipo) continue;

      final pts = r.points; // 🔹 sem simplificação
      if (pts.length < 2) continue;

      // tag como String (pra tooltips, etc.)
      final String tagStr = r.tipo.toString().split('.').last.toUpperCase();

      list.add(
        TappableChangedPolyline(
          points: pts,
          tag: tagStr,
          color: _color(r.tipo),
          defaultColor: _color(r.tipo),
          strokeWidth: 3,
          hitTestable: true,
        ),
      );
    }

    return list;
  }
}
