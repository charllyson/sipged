import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoFilterSubcollectionCleaner {
  final FirebaseFirestore _db;
  NoFilterSubcollectionCleaner({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ---------- JÁ EXISTENTES ----------
  // _countCollectionDocs(...), _deleteCollectionBatched(...),
  // dryCountAllUnderEachParent(...), deleteAllUnderEachParent(...),
  // deleteIdsUnderEachParent(...)

  // ---------- NOVOS: apagar um CAMPO em todos os docs da subcoleção ----------

  /// Conta, em modo dry-run, **quantos documentos possuem o campo**.
  Future<int> countDocsWithFieldUnderEachParent({
    required String parentCollectionPath,
    required String subcollection,
    required String fieldName,
    int pageSize = 300,
  }) async {
    int total = 0;
    final parents = await _db.collection(parentCollectionPath).get();

    for (final p in parents.docs) {
      DocumentSnapshot? last;
      while (true) {
        Query<Map<String, dynamic>> q =
        p.reference.collection(subcollection).orderBy(FieldPath.documentId).limit(pageSize);
        if (last != null) q = q.startAfterDocument(last);
        final snap = await q.get();
        if (snap.docs.isEmpty) break;

        for (final d in snap.docs) {
          final data = d.data();
          if (data.containsKey(fieldName)) total++;
        }
        last = snap.docs.last;
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }
    return total;
  }

  /// Remove o [fieldName] de todos os docs da subcoleção (para cada pai).
  /// Se [dryRun] = true, apenas contabiliza quantos seriam afetados.
  Future<int> deleteFieldFromAllDocsUnderEachParent({
    required String parentCollectionPath,
    required String subcollection,
    required String fieldName,
    bool dryRun = false,
    int pageSize = 300,
    int batchSize = 400,
  }) async {
    int affected = 0;
    final parents = await _db.collection(parentCollectionPath).get();

    for (final p in parents.docs) {
      DocumentSnapshot? last;

      WriteBatch? batch;
      int inBatch = 0;

      Future<void> _flush() async {
        if (batch != null && inBatch > 0) {
          await batch!.commit();
          batch = null;
          inBatch = 0;
          await Future.delayed(const Duration(milliseconds: 15));
        }
      }

      while (true) {
        Query<Map<String, dynamic>> q =
        p.reference.collection(subcollection).orderBy(FieldPath.documentId).limit(pageSize);
        if (last != null) q = q.startAfterDocument(last);

        final snap = await q.get();
        if (snap.docs.isEmpty) break;

        for (final d in snap.docs) {
          final data = d.data();
          if (!data.containsKey(fieldName)) continue;

          if (dryRun) {
            affected++;
          } else {
            batch ??= _db.batch();
            batch!.update(d.reference, {fieldName: FieldValue.delete()});
            inBatch++;
            affected++;
            if (inBatch >= batchSize) {
              await _flush();
            }
          }
        }

        last = snap.docs.last;
      }

      if (!dryRun) await _flush();
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return affected;
  }
}
