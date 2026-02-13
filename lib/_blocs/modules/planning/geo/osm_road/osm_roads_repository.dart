/*
// lib/_blocs/modules/planning/geo/osm_road/osm_roads_repository.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'osm_road_service.dart';
import 'osm_road_data.dart';
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class OSMRoadsRepository {
  final OSMRoadService _service = const OSMRoadService();

  // Cache por "tileKey" -> RoadGeometry
  final Map<String, List<RoadGeometry>> _cache = {};

  void clearCache() => _cache.clear();

  // Regex “segura” para não puxar micro-ruas demais.
  // Se quiser mais detalhes, você amplia depois.
  String highwayRegexForFiltro(RodoviaTipo filtro) {
    // principais tipos (reduz volume e melhora performance/timeout)
    const base = r'^(motorway|trunk|primary|secondary|tertiary)$';

    // você pode diferenciar depois; por enquanto o filtro por tipo
    // (federal/estadual/municipal) será via tags/ref na classify().
    return base;
  }

  RodoviaTipo classify(Map<String, dynamic> tags) {
    final ref = (tags['ref'] as String? ?? '').toUpperCase().trim();
    final highway = (tags['highway'] as String? ?? '').toLowerCase();

    if (ref.startsWith('BR-')) return RodoviaTipo.federal;

    // Ex.: AL-101, PE-060 etc. (você pode melhorar com SetupData.ufs)
    if (RegExp(r'^[A-Z]{2}-\d+').hasMatch(ref)) return RodoviaTipo.estadual;

    if (ref.isNotEmpty) return RodoviaTipo.municipal;

    // fallback
    const municip = [
      'tertiary',
      'secondary',
      'primary',
    ];
    if (municip.contains(highway)) return RodoviaTipo.municipal;

    return RodoviaTipo.outras;
  }

  // Gera uma chave “estável” por bbox+zoomBucket (pra cache)
  String tileKey({
    required LatLng center,
    required double zoom,
    required RodoviaTipo filtro,
  }) {
    // bucket de zoom para evitar recarregar a cada pequeno zoom
    final zb = (zoom * 2).floor(); // 0.5 zoom bucket

    // arredonda coordenadas: quanto menor o zoom, mais grosseiro
    final factor = zoom < 8 ? 0.5 : zoom < 10 ? 0.2 : 0.1;
    double snap(double v) => (v / factor).round() * factor;

    final lat = snap(center.latitude);
    final lon = snap(center.longitude);

    return "z$zb:${filtro.name}:$lat,$lon";
  }

  // BBOX em graus aproximada por zoom (simples, suficiente)
  List<double> bboxFromViewport({
    required LatLng center,
    required double zoom,
  }) {
    // quanto maior zoom, menor área
    final span = zoom < 7
        ? 3.0
        : zoom < 9
        ? 1.8
        : zoom < 11
        ? 1.0
        : zoom < 13
        ? 0.6
        : 0.35;

    final south = center.latitude - span;
    final north = center.latitude + span;
    final west = center.longitude - span;
    final east = center.longitude + span;

    return [south, west, north, east];
  }

  Future<List<RoadGeometry>> loadRoadsForViewport({
    required LatLng center,
    required double zoom,
    required RodoviaTipo filtro,
  }) async {
    final key = tileKey(center: center, zoom: zoom, filtro: filtro);

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final bbox = bboxFromViewport(center: center, zoom: zoom);

    final regex = highwayRegexForFiltro(filtro);

    final raw = await _service.fetchRoadsFromBBox(bbox: bbox, highwayRegex: regex);

    final roads = raw.map((r) {
      final tipo = classify(r.tags);
      return RoadGeometry(points: r.geometry, tipo: tipo);
    }).toList();

    _cache[key] = roads;
    return roads;
  }

  Color _color(RodoviaTipo t) {
    switch (t) {
      case RodoviaTipo.federal:
        return const Color(0xFFE53935);
      case RodoviaTipo.estadual:
        return const Color(0xFF43A047);
      case RodoviaTipo.municipal:
        return const Color(0xFF546E7A);
      case RodoviaTipo.outras:
        return const Color(0xFFFFA726);
      case RodoviaTipo.todas:
        return const Color(0xFFAB47BC);
    }
  }

  List<TappableChangedPolyline> buildPolylines({
    required List<RoadGeometry> roads,
    required RodoviaTipo filtro,
  }) {
    final list = <TappableChangedPolyline>[];

    for (final r in roads) {
      // filtro “real” por tipo (federal/estadual/municipal/outras)
      if (filtro != RodoviaTipo.todas && filtro != r.tipo) continue;

      if (r.points.length < 2) continue;
      final tagStr = r.tipo.name.toUpperCase();

      list.add(
        TappableChangedPolyline(
          points: r.points,
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
*/
