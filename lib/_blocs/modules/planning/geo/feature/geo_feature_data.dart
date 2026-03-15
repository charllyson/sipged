import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum GeoFeatureGeometryType {
  point,
  multiPoint,
  lineString,
  multiLineString,
  polygon,
  multiPolygon,
  unknown,
}

class GeoFeatureData extends Equatable {
  final String id;
  final String layerId;
  final Map<String, dynamic> properties;
  final GeoFeatureGeometryType geometryType;
  final Map<String, dynamic> rawGeometry;
  final List<LatLng> markerPoints;
  final List<List<LatLng>> lineParts;
  final List<List<LatLng>> polygonRings;

  const GeoFeatureData({
    required this.id,
    required this.layerId,
    required this.properties,
    required this.geometryType,
    required this.rawGeometry,
    this.markerPoints = const [],
    this.lineParts = const [],
    this.polygonRings = const [],
  });

  String get selectionKey => '$layerId::$id';

  String get title {
    const candidateKeys = [
      'title',
      'titulo',
      'name',
      'nome',
      'label',
      'descricao',
      'description',
      'id',
      'codigo',
      'processo',
    ];

    for (final key in candidateKeys) {
      final value = properties[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return id;
  }

  bool get hasGeometry =>
      markerPoints.isNotEmpty || lineParts.isNotEmpty || polygonRings.isNotEmpty;

  LatLng? get center {
    if (markerPoints.isNotEmpty) return markerPoints.first;

    if (lineParts.isNotEmpty) {
      final points = lineParts.expand((e) => e).toList(growable: false);
      if (points.isNotEmpty) return _centerFromPoints(points);
    }

    if (polygonRings.isNotEmpty) {
      final points = polygonRings.expand((e) => e).toList(growable: false);
      if (points.isNotEmpty) return _centerFromPoints(points);
    }

    return null;
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'editor': properties,
      'geometryType': geometryType.name,
      'geometry': rawGeometry,
      'searchTitle': title,
      'layerId': layerId,
    };
  }

  factory GeoFeatureData.fromFirestore({
    required String docId,
    required String layerId,
    required Map<String, dynamic> map,
  }) {
    final rawStoredGeometry = Map<String, dynamic>.from(
      (map['geometry'] as Map?) ?? const <String, dynamic>{},
    );

    final geometry = _normalizeFirestoreGeometry(rawStoredGeometry);
    final typeStr = (geometry['type'] ?? map['geometryType'] ?? '').toString();
    final resolvedType = _mapGeoJsonType(typeStr);

    final properties = _resolveProperties(map);

    final parsed = _parseGeometry(
      geometryType: resolvedType,
      geometry: geometry,
    );

    return GeoFeatureData(
      id: docId,
      layerId: layerId,
      properties: properties,
      geometryType: resolvedType,
      rawGeometry: geometry,
      markerPoints: parsed.markerPoints,
      lineParts: parsed.lineParts,
      polygonRings: parsed.polygonRings,
    );
  }

  static Map<String, dynamic> _resolveProperties(Map<String, dynamic> map) {
    final editor = map['editor'];
    if (editor is Map && editor.isNotEmpty) {
      return Map<String, dynamic>.from(editor);
    }

    final properties = map['properties'];
    if (properties is Map && properties.isNotEmpty) {
      return Map<String, dynamic>.from(properties);
    }

    final attributes = map['attributes'];
    if (attributes is Map && attributes.isNotEmpty) {
      return Map<String, dynamic>.from(attributes);
    }

    final ignoredKeys = <String>{
      'id',
      'docId',
      'layerId',
      'geometry',
      'geometryType',
      'searchTitle',
      'createdAt',
      'createdBy',
      'updatedAt',
      'updatedBy',
      'editor',
      'properties',
      'attributes',
    };

    final fallback = <String, dynamic>{};
    for (final entry in map.entries) {
      if (ignoredKeys.contains(entry.key)) continue;
      fallback[entry.key] = entry.value;
    }

    return fallback;
  }

  static Map<String, dynamic> _normalizeFirestoreGeometry(
      Map<String, dynamic> geometry,
      ) {
    final type = (geometry['type'] ?? '').toString();
    final coords = geometry['coordinates'];

    switch (type) {
      case 'Point':
        return {
          'type': 'Point',
          'coordinates': _decodePoint(coords),
        };
      case 'MultiPoint':
        return {
          'type': 'MultiPoint',
          'coordinates': _decodePointList(coords),
        };
      case 'LineString':
        return {
          'type': 'LineString',
          'coordinates': _decodePointList(coords),
        };
      case 'MultiLineString':
        return {
          'type': 'MultiLineString',
          'coordinates': _decodeLineList(coords),
        };
      case 'Polygon':
        return {
          'type': 'Polygon',
          'coordinates': _decodeRingList(coords),
        };
      case 'MultiPolygon':
        return {
          'type': 'MultiPolygon',
          'coordinates': _decodePolygonList(coords),
        };
      default:
        return geometry;
    }
  }

  static GeoFeatureGeometryType _mapGeoJsonType(String raw) {
    switch (raw.toLowerCase()) {
      case 'point':
        return GeoFeatureGeometryType.point;
      case 'multipoint':
        return GeoFeatureGeometryType.multiPoint;
      case 'linestring':
        return GeoFeatureGeometryType.lineString;
      case 'multilinestring':
        return GeoFeatureGeometryType.multiLineString;
      case 'polygon':
        return GeoFeatureGeometryType.polygon;
      case 'multipolygon':
        return GeoFeatureGeometryType.multiPolygon;
      default:
        return GeoFeatureGeometryType.unknown;
    }
  }

  static _ParsedGeometry _parseGeometry({
    required GeoFeatureGeometryType geometryType,
    required Map<String, dynamic> geometry,
  }) {
    final coords = geometry['coordinates'];

    switch (geometryType) {
      case GeoFeatureGeometryType.point:
        final p = _latLngFromDynamic(coords);
        return _ParsedGeometry(
          markerPoints: p == null ? const [] : [p],
        );

      case GeoFeatureGeometryType.multiPoint:
        final pts = <LatLng>[];
        if (coords is List) {
          for (final item in coords) {
            final p = _latLngFromDynamic(item);
            if (p != null) pts.add(p);
          }
        }
        return _ParsedGeometry(markerPoints: pts);

      case GeoFeatureGeometryType.lineString:
        final line = _latLngList(coords);
        return _ParsedGeometry(
          lineParts: line.isEmpty ? const [] : [line],
        );

      case GeoFeatureGeometryType.multiLineString:
        final lines = <List<LatLng>>[];
        if (coords is List) {
          for (final part in coords) {
            final parsed = _latLngList(part);
            if (parsed.isNotEmpty) lines.add(parsed);
          }
        }
        return _ParsedGeometry(lineParts: lines);

      case GeoFeatureGeometryType.polygon:
        final rings = <List<LatLng>>[];
        if (coords is List) {
          for (final ring in coords) {
            final parsed = _latLngList(ring);
            if (parsed.length >= 3) rings.add(parsed);
          }
        }
        return _ParsedGeometry(polygonRings: rings);

      case GeoFeatureGeometryType.multiPolygon:
        final rings = <List<LatLng>>[];
        if (coords is List) {
          for (final polygon in coords) {
            if (polygon is List) {
              for (final ring in polygon) {
                final parsed = _latLngList(ring);
                if (parsed.length >= 3) rings.add(parsed);
              }
            }
          }
        }
        return _ParsedGeometry(polygonRings: rings);

      case GeoFeatureGeometryType.unknown:
        return const _ParsedGeometry();
    }
  }

  static List<LatLng> _latLngList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <LatLng>[];
    for (final item in raw) {
      final p = _latLngFromDynamic(item);
      if (p != null) out.add(p);
    }
    return out;
  }

  static LatLng? _latLngFromDynamic(dynamic raw) {
    if (raw is! List || raw.length < 2) return null;

    final lng = _toDouble(raw[0]);
    final lat = _toDouble(raw[1]);

    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  static LatLng _centerFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    return LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
  }

  static List<dynamic> _decodePoint(dynamic raw) {
    if (raw is Map) {
      final lng = _toDouble(raw['lng']);
      final lat = _toDouble(raw['lat']);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }
    if (raw is List) return raw;
    return const [];
  }

  static List<List<dynamic>> _decodePointList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<dynamic>>[];
    for (final item in raw) {
      final point = _decodePoint(item);
      if (point.length >= 2) out.add(point);
    }
    return out;
  }

  static List<List<List<dynamic>>> _decodeLineList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<List<dynamic>>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(_decodePointList(item['points']));
      } else if (item is List) {
        out.add(_decodePointList(item));
      }
    }
    return out;
  }

  static List<List<List<dynamic>>> _decodeRingList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<List<dynamic>>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(_decodePointList(item['ring']));
      } else if (item is List) {
        out.add(_decodePointList(item));
      }
    }
    return out;
  }

  static List<List<List<List<dynamic>>>> _decodePolygonList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<List<List<dynamic>>>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(_decodeRingList(item['rings']));
      } else if (item is List) {
        out.add(_decodeRingList(item));
      }
    }
    return out;
  }

  @override
  List<Object?> get props => [
    id,
    layerId,
    properties,
    geometryType,
    rawGeometry,
    markerPoints,
    lineParts,
    polygonRings,
  ];
}

class _ParsedGeometry {
  final List<LatLng> markerPoints;
  final List<List<LatLng>> lineParts;
  final List<List<LatLng>> polygonRings;

  const _ParsedGeometry({
    this.markerPoints = const [],
    this.lineParts = const [],
    this.polygonRings = const [],
  });
}