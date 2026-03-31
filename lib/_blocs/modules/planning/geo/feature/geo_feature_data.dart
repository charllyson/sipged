import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
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

enum GeoFeatureGeometryFamily {
  point,
  line,
  polygon,
  unknown,
}

enum TypeFieldGeoJson {
  string,
  integer,
  double_,
  boolean,
  datetime,
}

class ImportColumnMeta extends Equatable {
  final String name;
  final bool selected;
  final TypeFieldGeoJson type;

  const ImportColumnMeta({
    required this.name,
    required this.selected,
    required this.type,
  });

  ImportColumnMeta copyWith({
    String? name,
    bool? selected,
    TypeFieldGeoJson? type,
  }) {
    return ImportColumnMeta(
      name: name ?? this.name,
      selected: selected ?? this.selected,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [name, selected, type];
}

class GeoFeatureParsedGeometry {
  final List<LatLng> markerPoints;
  final List<List<LatLng>> lineParts;
  final List<List<LatLng>> polygonRings;

  const GeoFeatureParsedGeometry({
    this.markerPoints = const [],
    this.lineParts = const [],
    this.polygonRings = const [],
  });
}

class GeoFeatureData extends Equatable {
  final String? id;
  final String? layerId;

  final Map<String, dynamic> originalProperties;
  final Map<String, dynamic> editedProperties;
  final Map<String, TypeFieldGeoJson> columnTypes;
  final bool selected;

  final GeoFeatureGeometryType geometryType;
  final Map<String, dynamic> rawGeometry;

  final List<LatLng> markerPoints;
  final List<List<LatLng>> lineParts;
  final List<List<LatLng>> polygonRings;

  const GeoFeatureData({
    this.id,
    this.layerId,
    required this.originalProperties,
    required this.editedProperties,
    required this.columnTypes,
    required this.selected,
    required this.geometryType,
    required this.rawGeometry,
    this.markerPoints = const [],
    this.lineParts = const [],
    this.polygonRings = const [],
  });

  factory GeoFeatureData.fromFirestore({
    required String docId,
    required String layerId,
    required Map<String, dynamic> map,
    bool selected = false,
  }) {
    final rawStoredGeometry = Map<String, dynamic>.from(
      (map['geometry'] as Map?) ?? const <String, dynamic>{},
    );

    final normalizedGeometry = normalizeFirestoreGeometry(rawStoredGeometry);
    final geometryType = mapGeoJsonType(
      (normalizedGeometry['type'] ?? map['geometryType'] ?? '').toString(),
    );

    final parsed = parseGeometry(
      geometryType: geometryType,
      geometry: normalizedGeometry,
    );

    final props = resolveProperties(map);
    final columnTypes = {
      for (final entry in props.entries) entry.key: inferFieldType(entry.value),
    };

    return GeoFeatureData(
      id: docId,
      layerId: layerId,
      originalProperties: props,
      editedProperties: Map<String, dynamic>.from(props),
      columnTypes: columnTypes,
      selected: selected,
      geometryType: geometryType,
      rawGeometry: normalizedGeometry,
      markerPoints: parsed.markerPoints,
      lineParts: parsed.lineParts,
      polygonRings: parsed.polygonRings,
    );
  }

  factory GeoFeatureData.fromImportedRawFeature(
      Map<String, dynamic> rawFeature, {
        bool selected = true,
      }) {
    final props = resolveProperties(rawFeature);
    final geometry = Map<String, dynamic>.from(
      (rawFeature['geometry'] as Map?) ?? const <String, dynamic>{},
    );

    final geometryType =
    mapGeoJsonType((geometry['type'] ?? '').toString());

    final parsed = parseGeometry(
      geometryType: geometryType,
      geometry: geometry,
    );

    final allKeys = props.keys.toList()..sort();

    final edited = <String, dynamic>{
      for (final key in allKeys) key: props[key],
    };

    final columnTypes = <String, TypeFieldGeoJson>{
      for (final key in allKeys) key: inferFieldType(props[key]),
    };

    return GeoFeatureData(
      id: null,
      layerId: null,
      originalProperties: props,
      editedProperties: edited,
      columnTypes: columnTypes,
      selected: selected,
      geometryType: geometryType,
      rawGeometry: geometry,
      markerPoints: parsed.markerPoints,
      lineParts: parsed.lineParts,
      polygonRings: parsed.polygonRings,
    );
  }

  GeoFeatureData copyWith({
    String? id,
    String? layerId,
    Map<String, dynamic>? originalProperties,
    Map<String, dynamic>? editedProperties,
    Map<String, TypeFieldGeoJson>? columnTypes,
    bool? selected,
    GeoFeatureGeometryType? geometryType,
    Map<String, dynamic>? rawGeometry,
    List<LatLng>? markerPoints,
    List<List<LatLng>>? lineParts,
    List<List<LatLng>>? polygonRings,
  }) {
    return GeoFeatureData(
      id: id ?? this.id,
      layerId: layerId ?? this.layerId,
      originalProperties: originalProperties ?? this.originalProperties,
      editedProperties: editedProperties ?? this.editedProperties,
      columnTypes: columnTypes ?? this.columnTypes,
      selected: selected ?? this.selected,
      geometryType: geometryType ?? this.geometryType,
      rawGeometry: rawGeometry ?? this.rawGeometry,
      markerPoints: markerPoints ?? this.markerPoints,
      lineParts: lineParts ?? this.lineParts,
      polygonRings: polygonRings ?? this.polygonRings,
    );
  }

  String get selectionKey => '${layerId ?? ''}::${id ?? ''}';

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
      final value = editedProperties[key] ?? originalProperties[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return (id != null && id!.trim().isNotEmpty) ? id! : 'Feature';
  }

  GeoFeatureGeometryFamily get geometryFamily {
    switch (geometryType) {
      case GeoFeatureGeometryType.point:
      case GeoFeatureGeometryType.multiPoint:
        return GeoFeatureGeometryFamily.point;

      case GeoFeatureGeometryType.lineString:
      case GeoFeatureGeometryType.multiLineString:
        return GeoFeatureGeometryFamily.line;

      case GeoFeatureGeometryType.polygon:
      case GeoFeatureGeometryType.multiPolygon:
        return GeoFeatureGeometryFamily.polygon;

      case GeoFeatureGeometryType.unknown:
        return GeoFeatureGeometryFamily.unknown;
    }
  }

  bool get isPointFamily => geometryFamily == GeoFeatureGeometryFamily.point;
  bool get isLineFamily => geometryFamily == GeoFeatureGeometryFamily.line;
  bool get isPolygonFamily =>
      geometryFamily == GeoFeatureGeometryFamily.polygon;

  bool get hasGeometry =>
      markerPoints.isNotEmpty ||
          lineParts.isNotEmpty ||
          polygonRings.isNotEmpty;

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

  String get geometryTypeName => geometryTypeToGeoJsonName(geometryType);

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'layerId': layerId,
      'editor': editedProperties,
      'geometryType': geometryTypeName,
      'geometry': rawGeometry,
      'searchTitle': title,
    };
  }

  static Map<String, dynamic> resolveProperties(Map<String, dynamic> map) {
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

  static GeoFeatureGeometryType mapGeoJsonType(String raw) {
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

  static String geometryTypeToGeoJsonName(
      GeoFeatureGeometryType geometryType,
      ) {
    switch (geometryType) {
      case GeoFeatureGeometryType.point:
        return 'Point';
      case GeoFeatureGeometryType.multiPoint:
        return 'MultiPoint';
      case GeoFeatureGeometryType.lineString:
        return 'LineString';
      case GeoFeatureGeometryType.multiLineString:
        return 'MultiLineString';
      case GeoFeatureGeometryType.polygon:
        return 'Polygon';
      case GeoFeatureGeometryType.multiPolygon:
        return 'MultiPolygon';
      case GeoFeatureGeometryType.unknown:
        return 'Unknown';
    }
  }

  static GeoFeatureParsedGeometry parseGeometry({
    required GeoFeatureGeometryType geometryType,
    required Map<String, dynamic> geometry,
  }) {
    final coords = geometry['coordinates'];

    switch (geometryType) {
      case GeoFeatureGeometryType.point:
        final p = _latLngFromDynamic(coords);
        return GeoFeatureParsedGeometry(
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
        return GeoFeatureParsedGeometry(markerPoints: pts);

      case GeoFeatureGeometryType.lineString:
        final line = _latLngList(coords);
        return GeoFeatureParsedGeometry(
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
        return GeoFeatureParsedGeometry(lineParts: lines);

      case GeoFeatureGeometryType.polygon:
        final rings = <List<LatLng>>[];
        if (coords is List) {
          for (final ring in coords) {
            final parsed = _latLngList(ring);
            if (parsed.length >= 3) rings.add(parsed);
          }
        }
        return GeoFeatureParsedGeometry(polygonRings: rings);

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
        return GeoFeatureParsedGeometry(polygonRings: rings);

      case GeoFeatureGeometryType.unknown:
        return const GeoFeatureParsedGeometry();
    }
  }

  static Map<String, dynamic> normalizeFirestoreGeometry(
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

  static Map<String, dynamic> encodeGeometryForFirestore(
      Map<String, dynamic> geometry,
      ) {
    final type = (geometry['type'] ?? '').toString();
    final coords = geometry['coordinates'];

    switch (type) {
      case 'Point':
        return {
          'type': 'Point',
          'coordinates': _encodePoint(coords),
        };

      case 'MultiPoint':
        return {
          'type': 'MultiPoint',
          'coordinates': _encodePointList(coords),
        };

      case 'LineString':
        return {
          'type': 'LineString',
          'coordinates': _encodePointList(coords),
        };

      case 'MultiLineString':
        return {
          'type': 'MultiLineString',
          'coordinates': _encodeLineList(coords),
        };

      case 'Polygon':
        return {
          'type': 'Polygon',
          'coordinates': _encodeRingList(coords),
        };

      case 'MultiPolygon':
        return {
          'type': 'MultiPolygon',
          'coordinates': _encodePolygonList(coords),
        };

      default:
        return geometry;
    }
  }

  static TypeFieldGeoJson inferFieldType(dynamic value) {
    if (value == null) return TypeFieldGeoJson.string;
    if (value is bool) return TypeFieldGeoJson.boolean;
    if (value is int) return TypeFieldGeoJson.integer;
    if (value is double || value is num) return TypeFieldGeoJson.double_;
    if (value is DateTime || value is Timestamp) {
      return TypeFieldGeoJson.datetime;
    }

    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return TypeFieldGeoJson.string;

      final lower = v.toLowerCase();

      if (lower == 'true' ||
          lower == 'false' ||
          lower == 'sim' ||
          lower == 'não' ||
          lower == 'nao') {
        return TypeFieldGeoJson.boolean;
      }

      if (int.tryParse(v) != null) return TypeFieldGeoJson.integer;
      if (double.tryParse(v.replaceAll(',', '.')) != null) {
        return TypeFieldGeoJson.double_;
      }
      if (DateTime.tryParse(v) != null) return TypeFieldGeoJson.datetime;
    }

    return TypeFieldGeoJson.string;
  }

  static TypeFieldGeoJson mergeInferredType(
      TypeFieldGeoJson? current,
      TypeFieldGeoJson next,
      ) {
    if (current == null) return next;
    if (current == next) return current;

    if ((current == TypeFieldGeoJson.integer &&
        next == TypeFieldGeoJson.double_) ||
        (current == TypeFieldGeoJson.double_ &&
            next == TypeFieldGeoJson.integer)) {
      return TypeFieldGeoJson.double_;
    }

    return TypeFieldGeoJson.string;
  }

  static double? toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  static LatLng? _latLngFromDynamic(dynamic raw) {
    if (raw is! List || raw.length < 2) return null;

    final lng = toDouble(raw[0]);
    final lat = toDouble(raw[1]);

    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
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

  static Map<String, dynamic>? _encodePoint(dynamic raw) {
    if (raw is! List || raw.length < 2) return null;

    final lng = toDouble(raw[0]);
    final lat = toDouble(raw[1]);
    if (lat == null || lng == null) return null;

    return {'lng': lng, 'lat': lat};
  }

  static List<Map<String, dynamic>> _encodePointList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      final p = _encodePoint(item);
      if (p != null) out.add(p);
    }
    return out;
  }

  static List<Map<String, dynamic>> _encodeLineList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final line in raw) {
      out.add({'points': _encodePointList(line)});
    }
    return out;
  }

  static List<Map<String, dynamic>> _encodeRingList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final ring in raw) {
      out.add({'ring': _encodePointList(ring)});
    }
    return out;
  }

  static List<Map<String, dynamic>> _encodePolygonList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final polygon in raw) {
      out.add({'rings': _encodeRingList(polygon)});
    }
    return out;
  }

  static List<dynamic> _decodePoint(dynamic raw) {
    if (raw is Map) {
      final lng = toDouble(raw['lng']);
      final lat = toDouble(raw['lat']);
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
    originalProperties,
    editedProperties,
    columnTypes,
    selected,
    geometryType,
    rawGeometry,
    markerPoints,
    lineParts,
    polygonRings,
  ];
}