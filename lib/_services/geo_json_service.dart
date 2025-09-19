import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';

/// Constantes de chaves de propriedades
const String kPropertyRegionName = 'Limite';
const String kPropertyCityName = 'NM_MUN';
const String kPropertyRoadStatus = 'Superfície Estadual';



class GeoJsonService {
  static Future<List<PolygonChanged>> loadPolygonsRegionsOfDERAL({
    required String assetPath,
    Color borderColor = Colors.black,
    double borderStrokeWidth = 1.5,
    Color fillColor = const Color(0xFFCCCCCC),
    double fillOpacity = 0.1,
  }) {
    return _loadPolygons(
      assetPath: assetPath,
      nomePropriedade: kPropertyRegionName,
      fillColor: fillColor,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      fillOpacity: fillOpacity,
    );
  }

  static Future<List<PolygonChanged>> loadServicePolygonsOfCitiesAL({
    required String assetPath,
    Color borderColor = Colors.black,
    double borderStrokeWidth = 1.0,
    Color fillColor = const Color(0xFF009688),
    double fillOpacity = 0.1,
  }) {
    return _loadPolygons(
      assetPath: assetPath,
      nomePropriedade: kPropertyCityName,
      fillColor: fillColor,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      fillOpacity: fillOpacity,
    );
  }

  static Future<List<PolygonChanged>> _loadPolygons({
    required String assetPath,
    required String nomePropriedade,
    required Color fillColor,
    required Color borderColor,
    required double borderStrokeWidth,
    required double fillOpacity,
  }) async {
    try {
      final String data = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> geoJson = jsonDecode(data);
      final features = List<Map<String, dynamic>>.from(geoJson['features']);

      final List<PolygonChanged> polygons = [];

      for (final feature in features) {
        final geometry = feature['geometry'];
        if (geometry == null) continue;

        final coordinates = geometry['coordinates'];
        final props = Map<String, dynamic>.from(feature['properties'] ?? {});
        final nome = (props[nomePropriedade] ?? 'INDEFINIDO').toString().toUpperCase();

        if (geometry['type'] == 'MultiPolygon') {
          for (final polygon in coordinates) {
            for (final ring in polygon) {
              final points = List<LatLng>.from(ring.map((c) => LatLng(c[1], c[0])));
              if (points.isNotEmpty && !_isSamePoint(points.first, points.last)) {
                points.add(points.first);
              }
              polygons.add(
                PolygonChanged(
                  title: nome,
                  polygon: Polygon(
                    points: points,
                    color: fillColor.withOpacity(fillOpacity),
                    borderColor: borderColor,
                    borderStrokeWidth: borderStrokeWidth,
                  ),
                ),
              );
            }
          }
        }
      }

      polygons.sort((a, b) => a.title.compareTo(b.title));
      return polygons;
    } catch (e) {
      debugPrint('Erro ao carregar polígonos de $assetPath: $e');
      return [];
    }
  }


  static bool _isSamePoint(LatLng a, LatLng b, {double tolerance = 1e-6}) {
    return (a.latitude - b.latitude).abs() < tolerance &&
        (a.longitude - b.longitude).abs() < tolerance;
  }
}
