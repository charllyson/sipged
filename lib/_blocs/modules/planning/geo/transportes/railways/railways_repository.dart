import 'package:cloud_firestore/cloud_firestore.dart';

class RailwaysRepository {
  RailwaysRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col() {
    return _db.collection('geo').doc('transportes').collection('ferrovias');
  }

  Future<bool> hasData({required String uf}) async {
    final ufNorm = uf.trim().toUpperCase();

    final snap = await _col()
        .where('uf', isEqualTo: ufNorm)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return true;

    final any = await _col().limit(1).get();
    return any.docs.isNotEmpty;
  }
}
