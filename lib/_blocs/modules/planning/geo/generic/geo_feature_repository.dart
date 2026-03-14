import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_data.dart';

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