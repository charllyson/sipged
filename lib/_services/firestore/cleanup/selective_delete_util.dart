import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

enum WhereOp { eq, lt, lte, gt, gte, arrayContains, whereIn }

class WhereFilter {
  final String field;
  final WhereOp op;
  final dynamic value; // bool/num/String/List/Timestamp

  WhereFilter(this.field, this.op, this.value);

  Query<Map<String, dynamic>> apply(Query<Map<String, dynamic>> q) {
    switch (op) {
      case WhereOp.eq:
        return q.where(field, isEqualTo: value);
      case WhereOp.lt:
        return q.where(field, isLessThan: value);
      case WhereOp.lte:
        return q.where(field, isLessThanOrEqualTo: value);
      case WhereOp.gt:
        return q.where(field, isGreaterThan: value);
      case WhereOp.gte:
        return q.where(field, isGreaterThanOrEqualTo: value);
      case WhereOp.arrayContains:
        return q.where(field, arrayContains: value);
      case WhereOp.whereIn:
        final list = (value is List) ? value : <dynamic>[value];
        return q.where(field, whereIn: list);
    }
  }
}

class SubcollectionSelectiveDeleter {
  final FirebaseFirestore _db;
  SubcollectionSelectiveDeleter({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Apaga IDs específicos em **cada pai**
  Future<int> deleteIdsUnderEachParent({
    required String parentCollectionPath,
    required String subcollection,
    required List<String> docIds,
    bool dryRun = false,
    int batchSize = 300,
  }) async {
    int total = 0;
    final parents = await _db.collection(parentCollectionPath).get();

    for (final p in parents.docs) {
      final col = p.reference.collection(subcollection);

      WriteBatch? batch;
      int inBatch = 0;

      for (final id in docIds) {
        final docRef = col.doc(id);
        final snap = await docRef.get();
        if (!snap.exists) continue;

        if (dryRun) {
          total++;
        } else {
          batch ??= _db.batch();
          batch.delete(docRef);
          inBatch++;
          if (inBatch >= batchSize) {
            await batch.commit();
            total += inBatch;
            inBatch = 0;
            batch = null;
            await Future.delayed(const Duration(milliseconds: 15));
          }
        }
      }

      if (!dryRun && batch != null && inBatch > 0) {
        await batch.commit();
        total += inBatch;
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
    return total;
  }

  /// Apaga por filtro usando collectionGroup(subcollection)
  Future<int> deleteWhereInCollectionGroup({
    required String subcollection,
    required List<WhereFilter> filters,
    bool dryRun = false,
    int pageSize = 200,
  }) async {
    Query<Map<String, dynamic>> q = _db.collectionGroup(subcollection);
    for (final f in filters) {
      q = f.apply(q);
    }

    int deleted = 0;
    DocumentSnapshot? last;

    while (true) {
      var qp = q.limit(pageSize);
      if (last != null) qp = qp.startAfterDocument(last);

      final snap = await qp.get();
      if (snap.docs.isEmpty) break;

      if (!dryRun) {
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }

      deleted += snap.docs.length;
      last = snap.docs.last;

      await Future.delayed(const Duration(milliseconds: 20));
    }
    return deleted;
  }

  /// Apaga por filtro **em cada pai** (você informa a coleção principal)
  Future<int> deleteWhereUnderEachParent({
    required String parentCollectionPath,
    required String subcollection,
    required List<WhereFilter> filters,
    bool dryRun = false,
    int pageSize = 200,
  }) async {
    int total = 0;
    final parents = await _db.collection(parentCollectionPath).get();

    for (final p in parents.docs) {
      Query<Map<String, dynamic>> q = p.reference.collection(subcollection);
      for (final f in filters) {
        q = f.apply(q);
      }

      DocumentSnapshot? last;
      while (true) {
        var qp = q.limit(pageSize);
        if (last != null) qp = qp.startAfterDocument(last);

        final snap = await qp.get();
        if (snap.docs.isEmpty) break;

        if (!dryRun) {
          final batch = _db.batch();
          for (final d in snap.docs) {
            batch.delete(d.reference);
          }
          await batch.commit();
        }

        total += snap.docs.length;
        last = snap.docs.last;
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
    return total;
  }
}

/// Parser simples para valores vindos da UI
class FieldValueParser {
  static dynamic parse(String raw, {bool tryList = false}) {
    final s = raw.trim();
    if (s.isEmpty) return s;

    if (s.toLowerCase() == 'true') return true;
    if (s.toLowerCase() == 'false') return false;

    final numVal = num.tryParse(s);
    if (numVal != null) return numVal;

    DateTime? dt;
    try { dt = DateTime.tryParse(s); } catch (_) {}
    if (dt != null) return Timestamp.fromDate(dt);

    if (tryList && s.contains(',')) {
      return s.split(',').map((e) => parse(e, tryList: false)).toList();
    }

    return s;
  }
}
