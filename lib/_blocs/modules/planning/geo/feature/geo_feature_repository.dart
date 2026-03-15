import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';

class GeoFeatureRepository {
  GeoFeatureRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<GeoFeatureData>> loadFeatures({
    required String layerId,
    required String collectionPath,
    int limit = 5000,
    String orderByField = 'updatedAt',
    bool orderDescending = false,
  }) async {
    final query = _firestore.collection(collectionPath);

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await query
          .orderBy(orderByField, descending: orderDescending)
          .limit(limit)
          .get();
    } catch (_) {
      snap = await query.limit(limit).get();
    }

    final features = <GeoFeatureData>[];

    for (final doc in snap.docs) {
      try {
        final feature = GeoFeatureData.fromFirestore(
          docId: doc.id,
          layerId: layerId,
          map: doc.data(),
        );

        if (feature.hasGeometry) {
          features.add(feature);
        }
      } catch (_) {
        // ignora documentos inválidos
      }
    }

    return features;
  }

  Future<List<String>> loadFieldNames({
    required String collectionPath,
    int limit = 300,
    String orderByField = 'updatedAt',
    bool orderDescending = false,
  }) async {
    final query = _firestore.collection(collectionPath);

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await query
          .orderBy(orderByField, descending: orderDescending)
          .limit(limit)
          .get();
    } catch (_) {
      snap = await query.limit(limit).get();
    }

    final keys = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final props = _resolveProperties(data);
      keys.addAll(props.keys);
    }

    final result = keys.toList()..sort();
    return result;
  }

  Future<void> addPointFeaturesBatch({
    required String layerId,
    required String collectionPath,
    required List<LatLng> points,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    if (points.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _firestore.collection(collectionPath);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final doc = collection.doc();

      batch.set(doc, {
        'editor': {
          ...commonProperties,
          'draftIndex': i + 1,
        },
        'geometryType': 'Point',
        'geometry': {
          'type': 'Point',
          'coordinates': [point.longitude, point.latitude],
        },
        'searchTitle': '${commonProperties['title'] ?? 'Ponto'} ${i + 1}',
        'layerId': layerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> addLineFeaturesBatch({
    required String layerId,
    required String collectionPath,
    required List<List<LatLng>> lines,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final validLines = lines.where((e) => e.length >= 2).toList(growable: false);
    if (validLines.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _firestore.collection(collectionPath);

    for (int i = 0; i < validLines.length; i++) {
      final line = validLines[i];
      final doc = collection.doc();

      batch.set(doc, {
        'editor': {
          ...commonProperties,
          'draftIndex': i + 1,
        },
        'geometryType': 'LineString',
        'geometry': {
          'type': 'LineString',
          'coordinates': line
              .map((p) => [p.longitude, p.latitude])
              .toList(growable: false),
        },
        'searchTitle': '${commonProperties['title'] ?? 'Linha'} ${i + 1}',
        'layerId': layerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> addPolygonFeaturesBatch({
    required String layerId,
    required String collectionPath,
    required List<List<LatLng>> polygons,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final validPolygons =
    polygons.where((e) => e.length >= 3).toList(growable: false);
    if (validPolygons.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _firestore.collection(collectionPath);

    for (int i = 0; i < validPolygons.length; i++) {
      final polygon = validPolygons[i];
      final doc = collection.doc();

      final closedRing = List<LatLng>.from(polygon);
      final first = closedRing.first;
      final last = closedRing.last;

      if (first.latitude != last.latitude || first.longitude != last.longitude) {
        closedRing.add(first);
      }

      batch.set(doc, {
        'editor': {
          ...commonProperties,
          'draftIndex': i + 1,
        },
        'geometryType': 'Polygon',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            closedRing
                .map((p) => [p.longitude, p.latitude])
                .toList(growable: false),
          ],
        },
        'searchTitle': '${commonProperties['title'] ?? 'Polígono'} ${i + 1}',
        'layerId': layerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Map<String, dynamic> _resolveProperties(Map<String, dynamic> map) {
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
}