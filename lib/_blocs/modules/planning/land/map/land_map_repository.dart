import 'package:cloud_firestore/cloud_firestore.dart';
import '../map/land_map_data.dart';

class LandMapRepository {
  LandMapRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<LandMapData>> fetchAll(String contractId) async {
    final properties = await _firestore
        .collection('land')
        .doc(contractId)
        .collection('imovel')
        .get();

    final owners = await _firestore
        .collection('land')
        .doc(contractId)
        .collection('proprietario')
        .get();

    final ownerById = <String, Map<String, dynamic>>{
      for (final doc in owners.docs) doc.id: doc.data(),
    };

    double readDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return properties.docs.map((doc) {
      final map = doc.data();
      final owner = ownerById[doc.id];

      return LandMapData(
        propertyId: doc.id,
        title: map['registryNumber'] ?? map['address'] ?? '',
        ownerName: owner?['ownerName'] ?? '',
        city: map['city'] ?? '',
        status: map['status'] ?? '',
        latitude: readDouble(map['latitude']),
        longitude: readDouble(map['longitude']),
        roadName: map['roadName'] ?? '',
        kmStart: readDouble(map['kmStart']),
        kmEnd: readDouble(map['kmEnd']),
      );
    }).toList();
  }
}