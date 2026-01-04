// lib/_services/geography/open_street_map_road/osm_road_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'osm_road_data.dart';

/// Serviço responsável por consultar a Overpass API.
class OSMRoadService {
  const OSMRoadService();

  // ---------------------------------------------------------------------------
  // POST genérico para Overpass
  // ---------------------------------------------------------------------------
  Future<dynamic> _postOverpass(String query) async {
    final uri = Uri.parse("https://overpass-api.de/api/interpreter");

    final resp = await http.post(uri, body: {"data": query});

    if (resp.statusCode != 200) {
      throw Exception("Overpass API erro: ${resp.statusCode}");
    }

    return jsonDecode(resp.body);
  }

  // Parser comum para respostas com elementos/ways
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

      roads.add(
        OSMRoadData(
          id: id,
          geometry: geom,
          tags: tags,
        ),
      );
    }

    return roads;
  }

  // ---------------------------------------------------------------------------
  // (opcional) Busca por BBOX – deixei aqui se vc quiser em outro lugar
  // ---------------------------------------------------------------------------
  Future<List<OSMRoadData>> fetchRoadsFromBBox({
    required List<double> bbox,
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

    final decoded = await _postOverpass(query);
    return _parseRoads(decoded);
  }

  // ---------------------------------------------------------------------------
  // Busca TODAS as rodovias dentro do BOUNDARY de um estado (UF)
  // ---------------------------------------------------------------------------
  Future<List<OSMRoadData>> fetchRoadsForState(String ufSigla) async {
    // Ex.: UF = "AL" -> ISO3166-2 = "BR-AL"
    final query = '''
[out:json][timeout:60];

// boundary administrativo do estado
rel["admin_level"="4"]["ISO3166-2"="BR-$ufSigla"];
map_to_area->.a;

// todas as rodovias (highway) dentro da área do estado
(
  way["highway"](area.a);
);
out geom tags;
''';

    final decoded = await _postOverpass(query);
    return _parseRoads(decoded);
  }
}
