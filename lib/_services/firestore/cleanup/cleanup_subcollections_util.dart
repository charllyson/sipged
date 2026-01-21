import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilitário genérico para remover subcoleções de todos os documentos
/// de uma coleção arbitrária (ex.: 'contracts' ou 'orgs/abc/contracts').
///
/// Exemplo de uso:
///   final cleaner = SubcollectionCleaner();
///   await cleaner.deleteForCollectionPath(
///     'contracts',
///     ['measurements', 'adjustmentMeasurement', 'revisionMeasurement'],
///     dryRun: true, // primeiro veja a prévia
///   );
class SubcollectionCleaner {
  final FirebaseFirestore _db;

  SubcollectionCleaner({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // -------- helpers --------

  Future<int> _deleteCollectionBatched(
      CollectionReference<Map<String, dynamic>> col, {
        int batchSize = 200,
      }) async {
    int deleted = 0;

    while (true) {
      final snap = await col.limit(batchSize).get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snap.docs.length;

      await Future.delayed(const Duration(milliseconds: 30));
    }

    return deleted;
  }

  Future<int> _countCollectionDocs(
      CollectionReference<Map<String, dynamic>> col, {
        int page = 300,
      }) async {
    int count = 0;
    DocumentSnapshot<Map<String, dynamic>>? last;

    while (true) {
      Query<Map<String, dynamic>> q =
      col.orderBy(FieldPath.documentId).limit(page);
      if (last != null) q = q.startAfterDocument(last);

      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      count += snap.docs.length;
      last = snap.docs.last;
    }
    return count;
  }

  // -------- API --------

  /// Remove as [subcollections] abaixo de UM documento específico.
  /// Retorna: { subcolecao: quantidade_apagada_ou_existente }
  Future<Map<String, int>> deleteForDocument({
    required DocumentReference<Map<String, dynamic>> docRef,
    required List<String> subcollections,
    bool dryRun = false,
  }) async {
    final Map<String, int> result = {};

    for (final sub in subcollections) {
      final col = docRef.collection(sub);
      final existing = await _countCollectionDocs(col);

      if (!dryRun && existing > 0) {
        final deleted = await _deleteCollectionBatched(col);
        result[sub] = deleted;
      } else {
        result[sub] = existing; // prévia
      }
    }

    return result;
  }

  /// Remove as [subcollections] abaixo de TODOS os docs de [collectionPath].
  /// [collectionPath] pode ser 'contracts' ou algo como 'orgs/XYZ/contracts'.
  ///
  /// Retorna: { 'docPath': { subcolecao: qtd } }
  Future<Map<String, Map<String, int>>> deleteForCollectionPath(
      String collectionPath,
      List<String> subcollections, {
        bool dryRun = false,
      }) async {
    final Map<String, Map<String, int>> overall = {};

    final colRef =
    _db.collection(collectionPath);
    final docs = await colRef.get();

    for (final d in docs.docs) {
      try {
        final res = await deleteForDocument(
          docRef: d.reference,
          subcollections: subcollections,
          dryRun: dryRun,
        );
        overall[d.reference.path] = res;
      } catch (e) {
      }
      await Future.delayed(const Duration(milliseconds: 20));
    }

    return overall;
  }
}
