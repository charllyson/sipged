import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Subcoleções antigas que queremos remover, em cada contrato.
const List<String> kOldMeasurementSubcollections = <String>[
  'measurements',            // antigo "tudo misturado"
  'adjustmentMeasurement',   // antigo
  'revisionMeasurement',     // antigo
];

class CleanupOldMeasurementSubcollections {
  final FirebaseFirestore _db;

  CleanupOldMeasurementSubcollections({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Deleta TODOS os docs de uma coleção (subcoleção) em lotes.
  Future<int> _deleteCollectionBatched(CollectionReference<Map<String, dynamic>> col,
      {int batchSize = 200}) async {
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

      // dá um pequeno respiro para não saturar
      await Future.delayed(const Duration(milliseconds: 30));
    }

    return deleted;
  }

  /// Conta docs de forma paginada para não estourar memória.
  Future<int> _countCollectionDocs(CollectionReference<Map<String, dynamic>> col,
      {int page = 300}) async {
    int count = 0;
    DocumentSnapshot? last;

    while (true) {
      Query<Map<String, dynamic>> q = col.orderBy(FieldPath.documentId).limit(page);
      if (last != null) q = q.startAfterDocument(last);

      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      count += snap.docs.length;
      last = snap.docs.last;
    }
    return count;
  }

  /// Apaga as coleções antigas para UM contrato.
  /// Retorna um mapa { subcolecao: quantidade_apagada }.
  Future<Map<String, int>> deleteForContract(String contractId, {bool dryRun = false}) async {
    final Map<String, int> result = {};

    for (final sub in kOldMeasurementSubcollections) {
      final col = _db.collection('contracts').doc(contractId).collection(sub);

      // conta antes (para relatar o que foi feito)
      final existing = await _countCollectionDocs(col);

      if (!dryRun && existing > 0) {
        final deleted = await _deleteCollectionBatched(col);
        result[sub] = deleted;
      } else {
        result[sub] = existing; // dry run: informa quantos seriam apagados
      }
    }

    return result;
  }

  /// Apaga as coleções antigas para TODOS os contratos.
  /// Retorna um mapa { contractId: { subcolecao: quantidade_apagada } }.
  Future<Map<String, Map<String, int>>> deleteForAllContracts({bool dryRun = false}) async {
    final Map<String, Map<String, int>> overall = {};
    final contractsSnap = await _db.collection('contracts').get();

    for (final c in contractsSnap.docs) {
      final cid = c.id;
      try {
        final res = await deleteForContract(cid, dryRun: dryRun);
        overall[cid] = res;
        debugPrint('Cleanup ($cid): $res');
      } catch (e) {
        debugPrint('Erro ao limpar $cid: $e');
      }
      // pequeno intervalo entre contratos
      await Future.delayed(const Duration(milliseconds: 20));
    }

    return overall;
  }
}
