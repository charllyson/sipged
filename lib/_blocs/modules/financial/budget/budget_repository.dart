import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'budget_data.dart';

class BudgetRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  BudgetRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _col() =>
      _db.collection(BudgetData.collectionName);

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col().doc(id);

  bool _isMissingIndexError(Object e) {
    if (e is FirebaseException) {
      // Firestore usa failed-precondition em falta de índice
      if (e.code == 'failed-precondition') return true;
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('requires an index')) return true;
    }
    final s = e.toString().toLowerCase();
    return s.contains('requires an index') || s.contains('failed-precondition');
  }



  /// Ordenação local: year desc, updatedAt desc
  List<BudgetData> _sortLocal(List<BudgetData> list) {
    list.sort((a, b) {
      final ay = a.year;
      final by = b.year;
      if (ay != by) return by.compareTo(ay);

      final au = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bu = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bu.compareTo(au);
    });
    return list;
  }

  /// =========================
  /// GET ALL
  /// =========================
  Future<List<BudgetData>> getAll() async {
    try {
      // ✅ Se existir índice composto, ótimo (year + updatedAt)
      final qs = await _col()
          .orderBy('year', descending: true)
          .orderBy('updatedAt', descending: true)
          .get();

      return qs.docs.map((d) => BudgetData.fromDocument(d)).toList();
    } catch (e) {
      if (!_isMissingIndexError(e)) rethrow;

      // ✅ Fallback SEM índice composto:
      // - pega sem 2 orderBy (ou sem orderBy)
      final qs = await _col().get();
      final list = qs.docs.map((d) => BudgetData.fromDocument(d)).toList();
      return _sortLocal(list);
    }
  }

  /// =========================
  /// GET BY CONTRACT
  /// =========================
  Future<List<BudgetData>> getAllByContract({required String contractId}) async {
    final cid = contractId.trim();

    try {
      // ✅ Query ideal (exige índice composto)
      final qs = await _col()
          .where('contractId', isEqualTo: cid)
          .orderBy('year', descending: true)
          .orderBy('updatedAt', descending: true)
          .get();

      return qs.docs.map((d) => BudgetData.fromDocument(d)).toList();
    } catch (e) {
      if (!_isMissingIndexError(e)) rethrow;

      // ✅ Fallback SEM índice composto:
      // - mantém o filtro por contrato
      // - remove os orderBy
      final qs = await _col()
          .where('contractId', isEqualTo: cid)
          .get();

      final list = qs.docs.map((d) => BudgetData.fromDocument(d)).toList();
      return _sortLocal(list);
    }
  }

  /// =========================
  /// SAVE/UPDATE
  /// =========================
  Future<void> saveOrUpdate(BudgetData e) async {
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
    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['createdBy'] = uid;
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteById(String budgetId) async {
    await _doc(budgetId).delete();
  }
}
