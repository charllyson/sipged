// lib/_blocs/sectors/operation/road/physics_finance/physics_finance_bloc.dart
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'physics_finance_data.dart';
import 'physics_finance_repository.dart';

class PhysicsFinanceBloc extends BlocBase implements PhysicsFinanceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col({
    required String contractId,
    required String additiveId,
  }) {
    return _db
        .collection('contracts').doc(contractId)
        .collection('additives').doc(additiveId)
        .collection('schedules');
  }

  @override
  Future<List<PhysicsFinanceData>> list({
    required String contractId,
    required String additiveId,
  }) async {
    final qs = await _col(contractId: contractId, additiveId: additiveId)
        .orderBy('termOrder')
        .get();
    return qs.docs.map((d) => PhysicsFinanceData.fromSnapshot(
      contractId: contractId,
      additiveId: additiveId,
      snap: d,
    )).toList();
  }

  @override
  Future<PhysicsFinanceData?> get({
    required String contractId,
    required String additiveId,
    required int termOrder,
  }) async {
    final id = PhysicsFinanceData.docIdForTerm(termOrder);
    final doc = await _col(contractId: contractId, additiveId: additiveId).doc(id).get();
    if (!doc.exists) return null;
    return PhysicsFinanceData.fromSnapshot(
      contractId: contractId,
      additiveId: additiveId,
      snap: doc,
    );
  }

  @override
  Future<void> upsert({
    required String contractId,
    required String additiveId,
    required PhysicsFinanceData schedule,
    String? updatedBy,
  }) async {
    final uid = updatedBy ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final doc = _col(contractId: contractId, additiveId: additiveId)
        .doc(schedule.id.isNotEmpty ? schedule.id : PhysicsFinanceData.docIdForTerm(schedule.termOrder));

    await doc.set(
      schedule.toMap(updatedByOverride: uid),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> delete({
    required String contractId,
    required String additiveId,
    required String scheduleId,
  }) async {
    await _col(contractId: contractId, additiveId: additiveId).doc(scheduleId).delete();
  }
}
