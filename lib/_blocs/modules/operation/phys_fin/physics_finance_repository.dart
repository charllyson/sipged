// lib/_blocs/modules/operation/phys_fin/physics_finance_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'physics_finance_data.dart';

class PhysicsFinanceRepository {
  PhysicsFinanceRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _collection({
    required String contractId,
    required String additiveId,
  }) {
    return _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .doc(additiveId)
        .collection('schedules');
  }

  Future<List<PhysicsFinanceData>> list({
    required String contractId,
    required String additiveId,
  }) async {
    final snapshot = await _collection(
      contractId: contractId,
      additiveId: additiveId,
    ).orderBy('termOrder').get();

    return snapshot.docs.map((doc) {
      return PhysicsFinanceData.fromSnapshot(
        contractId: contractId,
        additiveId: additiveId,
        snap: doc,
      );
    }).toList();
  }

  Future<PhysicsFinanceData?> get({
    required String contractId,
    required String additiveId,
    required int termOrder,
  }) async {
    final String id = PhysicsFinanceData.docIdForTerm(termOrder);

    final doc = await _collection(
      contractId: contractId,
      additiveId: additiveId,
    ).doc(id).get();

    if (!doc.exists) return null;

    return PhysicsFinanceData.fromSnapshot(
      contractId: contractId,
      additiveId: additiveId,
      snap: doc,
    );
  }

  Future<void> upsert({
    required String contractId,
    required String additiveId,
    required PhysicsFinanceData schedule,
    String? updatedBy,
  }) async {
    final String uid = updatedBy ?? _auth.currentUser?.uid ?? '';

    final String docId = schedule.id.isNotEmpty
        ? schedule.id
        : PhysicsFinanceData.docIdForTerm(schedule.termOrder);

    await _collection(
      contractId: contractId,
      additiveId: additiveId,
    ).doc(docId).set(
      schedule.toMap(updatedByOverride: uid),
      SetOptions(merge: true),
    );
  }

  Future<void> delete({
    required String contractId,
    required String additiveId,
    required String scheduleId,
  }) async {
    await _collection(
      contractId: contractId,
      additiveId: additiveId,
    ).doc(scheduleId).delete();
  }
}