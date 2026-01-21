/*
// lib/_blocs/modules/planning/geo/osm_road/osm_road_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'osm_road_data.dart';

class OSMRoadService {
  const OSMRoadService();

  // Alguns mirrors ajudam MUITO quando um está congestionado.
  static const _endpoints = <String>[
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.nchc.org.tw/api/interpreter",
  ];

  Future<dynamic> _postOverpass(String endpoint, String query) async {
    final uri = Uri.parse(endpoint);

    final resp = await http
        .post(uri, body: {"data": query})
        .timeout(const Duration(seconds: 35));

    if (resp.statusCode != 200) {
      throw Exception("Overpass API erro: ${resp.statusCode}");
    }

    return jsonDecode(resp.body);
  }

  Future<dynamic> _postWithFallback(String query) async {
    Exception? last;
    for (final ep in _endpoints) {
      try {
        return await _postOverpass(ep, query);
      } catch (e) {
        last = e is Exception ? e : Exception(e.toString());
      }
    }
    throw last ?? Exception("Overpass indisponível");
  }

  List<OSMRoadData> _parseRoads(dynamic decoded) {
    final elements = (decoded["elements"] ?? []) as List<dynamic>;
    final roads = <OSMRoadData>[];

    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      if (e["type"] != "way") continue;
      if (e["geometry"] == null) continue;

      final id = (e["id"] ?? "").toString();
      final geom = (e["geometry"] as List<dynamic>).map((p) {
        final lat = (p["lat"] as num).toDouble();
        final lon = (p["lon"] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();

      if (geom.length < 2) continue;

      final tags = (e["tags"] ?? {}) as Map<String, dynamic>;

      roads.add(OSMRoadData(id: id, geometry: geom, tags: tags));
    }

    return roads;
  }

  // ✅ Carrega por viewport (BBOX) – muito mais estável que UF inteira.
  Future<List<OSMRoadData>> fetchRoadsFromBBox({
    required List<double> bbox, // [south, west, north, east]
    required String highwayRegex,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  way["highway"~"$highwayRegex"]
  (${bbox[0]},${bbox[1]},${bbox[2]},${bbox[3]});
);
out geom tags;
''';

    final decoded = await _postWithFallback(query);
    return _parseRoads(decoded);
  }
}
*/
