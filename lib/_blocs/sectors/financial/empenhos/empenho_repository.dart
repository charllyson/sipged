import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'empenho_data.dart';

class EmpenhoRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  EmpenhoRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _col() =>
      _db.collection(EmpenhoData.collectionName);

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col().doc(id);

  Future<List<EmpenhoData>> getAll() async {
    final qs = await _col().orderBy('date', descending: true).get();
    return qs.docs.map((d) => EmpenhoData.fromDocument(d)).toList();
  }

  Future<List<EmpenhoData>> getAllByContract({required String contractId}) async {
    final qs = await _col()
        .where('contractId', isEqualTo: contractId)
        .orderBy('date', descending: true)
        .get();

    return qs.docs.map((d) => EmpenhoData.fromDocument(d)).toList();
  }

  Future<void> saveOrUpdate(EmpenhoData e) async {
    final uid = _auth.currentUser?.uid ?? '';

    final docRef =
    (e.id != null && e.id!.isNotEmpty) ? _doc(e.id!) : _col().doc();
    e.id ??= docRef.id;

    final payload = e.toFirestore()
      ..addAll({
        'id': e.id,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      });

    final cid = e.contractId?.trim() ?? '';
    if (cid.isNotEmpty) {
      payload['contractId'] = cid;
    } else {
      payload.remove('contractId');
    }

    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['createdBy'] = uid;
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteById(String empenhoId) async {
    await _doc(empenhoId).delete();
  }
}
