import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sisged/_blocs/actives/oaes/active_oaes_data.dart';

class ActiveOaesRepository {
  final _ref = FirebaseFirestore.instance.collection('actives_oaes');

  Future<List<ActiveOaesData>> fetchAll() async {
    final snapshot = await _ref.orderBy('order').get();
    return snapshot.docs.map((doc) => ActiveOaesData.fromDocument(doc)).toList();
  }

  Future<List<ActiveOaesData>> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _ref.orderBy('order').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ActiveOaesData.fromDocument(doc)).toList();
  }

  Future<ActiveOaesData> upsert(ActiveOaesData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final docRef = data.id != null ? _ref.doc(data.id) : _ref.doc();
    data.id ??= docRef.id;

    final json = data.toMap()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    final snapshot = await docRef.get();
    final isNew = !snapshot.exists || snapshot.data()?['createdAt'] == null;
    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));

    final snap = await docRef.get();
    return ActiveOaesData.fromDocument(snap);
  }

  Future<void> deleteById(String id) async {
    await _ref.doc(id).delete();
  }

  Future<ActiveOaesData?> getById(String id) async {
    final snap = await _ref.doc(id).get();
    if (!snap.exists) return null;
    return ActiveOaesData.fromDocument(snap);
  }
}
