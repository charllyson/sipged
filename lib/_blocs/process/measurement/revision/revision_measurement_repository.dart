import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'revision_measurement_data.dart';

class RevisionMeasurementRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RevisionMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db
          .collection('contracts')
          .doc(contractId)
          .collection(RevisionMeasurementData.collectionName);

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  Future<List<RevisionMeasurementData>> getAllRevisionsOfContract({
    required String uidContract,
  }) async {
    final qs = await _col(uidContract).orderBy('order').get();
    return qs.docs
        .map((d) => RevisionMeasurementData.fromDocument(d))
        .toList();
  }

  /// Para dashboards (collectionGroup global).
  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() async {
    final qs =
    await _db.collectionGroup(RevisionMeasurementData.collectionName).get();
    return qs.docs
        .map((d) => RevisionMeasurementData.fromDocument(d))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdateRevision({
    required String contractId,
    required String revisionMeasurementId, // mantido para compatibilidade
    required RevisionMeasurementData rev,
  }) async {
    final user = _auth.currentUser;
    final docRef = _col(contractId).doc(revisionMeasurementId);

    rev.id ??= revisionMeasurementId;

    final data = rev.toFirestore()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
        'contractId': contractId,
      });

    final existing = await docRef.get();
    if (!existing.exists || existing.data()?['createdAt'] == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = user?.uid ?? '';
    }

    await docRef.set(data, SetOptions(merge: true));
    await _recalcularFinancialPercentage(contractId);
  }

  Future<void> deleteRevision({
    required String contractId,
    required String revisionId,
  }) async {
    await _col(contractId).doc(revisionId).delete();
    await _recalcularFinancialPercentage(contractId);
  }

  // Metadado (Firestore)
  Future<void> salvarUrlPdfDaRevisionMeasurement({
    required String contractId,
    required String revisionMeasurementId,
    required String url,
  }) async {
    await _col(contractId).doc(revisionMeasurementId).update({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    });
  }

  // atualiza attachments (lista completa)
  Future<void> setAttachments({
    required String contractId,
    required String revisionId,
    required List<Attachment> attachments,
  }) async {
    await _col(contractId).doc(revisionId).set({
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // % financeiro (reuso do cálculo com reports + adjustments + revisions)
  // ---------------------------------------------------------------------------

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double total = 0.0;

    final reps = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('reportsMeasurement')
        .get();
    for (final d in reps.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final adjs = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('adjustmentsMeasurement')
        .get();
    for (final d in adjs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final revs = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('revisionsMeasurement')
        .get();
    for (final d in revs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final c = await _db.collection('contracts').doc(contractId).get();
    final initialValue = (c.data()?['initialContractValue'] ?? 0);
    final baseInicial =
    (initialValue is num) ? initialValue.toDouble() : 0.0;

    final adds = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();
    double totAdd = 0.0;
    for (final a in adds.docs) {
      final v = (a.data()['additiveValue'] ?? 0);
      totAdd += (v is num) ? v.toDouble() : 0;
    }

    final apos = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();
    double totApo = 0.0;
    for (final ap in apos.docs) {
      final v = (ap.data()['apostilleValue'] ?? 0);
      totApo += (v is num) ? v.toDouble() : 0;
    }

    final totalBase = baseInicial + totAdd + totApo;
    final percent = totalBase > 0 ? (total / totalBase) * 100.0 : 0.0;

    await _db.collection('contracts').doc(contractId).set({
      'financialPercentage': percent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Totais
  // ---------------------------------------------------------------------------

  double sumRevisions(List<RevisionMeasurementData> items) {
    double total = 0.0;
    for (final i in items) {
      total += (i.value ?? 0.0);
    }
    return total;
  }
}
