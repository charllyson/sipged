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
}