// lib/_tools/migrations/migration_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MeasurementsMigrationService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  MeasurementsMigrationService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Migra TODOS os contratos
  Future<void> migrateAllContracts({int batchLimit = 400}) async {
    final contracts = await _db.collection('contracts').get();
    for (final c in contracts.docs) {
      await migrateContract(c.id, batchLimit: batchLimit);
    }
    debugPrint('✔️ Migração concluída para todos os contratos.');
  }

  /// Migra UM contrato
  Future<void> migrateContract(String contractId, {int batchLimit = 400}) async {
    debugPrint('➡️ Migrando measurements do contrato: $contractId');
    final measurementsRef = _db.collection('contracts').doc(contractId).collection('measurements');
    final snap = await measurementsRef.get();

    WriteBatch batch = _db.batch();
    int pending = 0;

    for (final doc in snap.docs) {
      final mId = doc.id;
      final data = doc.data();

      // --------- REPORT ---------
      final hasReport = data['measurementorder'] != null ||
          data['measurementnumberprocess'] != null ||
          data['measurementdata'] != null ||
          data['measurementinitialvalue'] != null ||
          data['pdfUrl'] != null;

      if (hasReport) {
        final reportRef = _db
            .collection('contracts').doc(contractId)
            .collection('reportsMeasurement')        // 👈 nova coleção
            .doc(mId);                                // mantém o mesmo id

        final report = _nonNull({
          'contractId': contractId,
          'originalMeasurementId': mId,
          'measurementorder': data['measurementorder'],
          'measurementnumberprocess': data['measurementnumberprocess'],
          'measurementdata': data['measurementdata'],
          'measurementinitialvalue': data['measurementinitialvalue'],
          'pdfUrl': data['pdfUrl'], // se existia antes, copiamos
          // metadados (preserva se já existiam)
          'createdAt': data['createdAt'],
          'createdBy': data['createdBy'],
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
          'migratedFromMeasurements': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });

        batch.set(reportRef, report, SetOptions(merge: true));
        if (++pending >= batchLimit) { await batch.commit(); batch = _db.batch(); pending = 0; }
      }

      // --------- ADJUSTMENT ---------
      final hasAdj = data['measurementadjustment'] != null ||
          data['measurementadjustmentorder'] != null ||
          data['measurementadjustmentnumberprocess'] != null ||
          data['measurementadjustmentdate'] != null ||
          data['measurementadjustmentvalue'] != null;

      if (hasAdj) {
        // usa o id do próprio reajuste se existir; senão, cai em fallback
        final adjId = (data['measurementadjustment']?.toString().trim().isNotEmpty ?? false)
            ? data['measurementadjustment'].toString()
            : 'adj_$mId';

        final adjRef = _db
            .collection('contracts').doc(contractId)
            .collection('adjustmentMeasurement')      // 👈 nova coleção
            .doc(adjId);

        final adj = _nonNull({
          'contractId': contractId,
          'originalMeasurementId': mId,
          'measurementadjustment': data['measurementadjustment'],
          'measurementadjustmentorder': data['measurementadjustmentorder'],
          'measurementadjustmentnumberprocess': data['measurementadjustmentnumberprocess'],
          'measurementadjustmentdate': data['measurementadjustmentdate'],
          'measurementadjustmentvalue': data['measurementadjustmentvalue'],
          // metadados
          'createdAt': data['createdAt'],
          'createdBy': data['createdBy'],
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
          'migratedFromMeasurements': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });

        batch.set(adjRef, adj, SetOptions(merge: true));
        if (++pending >= batchLimit) { await batch.commit(); batch = _db.batch(); pending = 0; }
      }

      // --------- REVISION ---------
      final hasRev = data['measurementrevision'] != null ||
          data['measurementrevisionorder'] != null ||
          data['measurementrevisionnumberprocess'] != null ||
          data['measurementrevisiondate'] != null ||
          data['measurementvaluerevisionsadjustments'] != null;

      if (hasRev) {
        final revId = (data['measurementrevision']?.toString().trim().isNotEmpty ?? false)
            ? data['measurementrevision'].toString()
            : 'rev_$mId';

        final revRef = _db
            .collection('contracts').doc(contractId)
            .collection('revisionMeasurement')        // 👈 nova coleção
            .doc(revId);

        final rev = _nonNull({
          'contractId': contractId,
          'originalMeasurementId': mId,
          'measurementrevision': data['measurementrevision'],
          'measurementrevisionorder': data['measurementrevisionorder'],
          'measurementrevisionnumberprocess': data['measurementrevisionnumberprocess'],
          'measurementrevisiondate': data['measurementrevisiondate'],
          'measurementvaluerevisionsadjustments': data['measurementvaluerevisionsadjustments'],
          // metadados
          'createdAt': data['createdAt'],
          'createdBy': data['createdBy'],
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
          'migratedFromMeasurements': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });

        batch.set(revRef, rev, SetOptions(merge: true));
        if (++pending >= batchLimit) { await batch.commit(); batch = _db.batch(); pending = 0; }
      }
    }

    if (pending > 0) await batch.commit();
    debugPrint('✅ Migração concluída para contrato: $contractId');
  }

  /// remove entradas nulas para não sujar os docs no Firestore
  Map<String, dynamic> _nonNull(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    src.forEach((k, v) { if (v != null) out[k] = v; });
    return out;
  }
}


double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Migra measurements -> reportsMeasurement / adjustmentsMeasurement / revisionsMeasurement
/// sem apagar a coleção original. Pode rodar mais de uma vez (merge).
Future<void> migrarMeasurementsParaColecoesNovas() async {
  final db = FirebaseFirestore.instance;

  final contratos = await db.collection('contracts').get();

  for (final cDoc in contratos.docs) {
    final contractId = cDoc.id;
    final measRef = db.collection('contracts').doc(contractId).collection('measurements');

    final measSnap = await measRef.get();
    if (measSnap.docs.isEmpty) continue;

    debugPrint('Migrando ${measSnap.docs.length} measurements do contrato $contractId...');

    for (final doc in measSnap.docs) {
      final d = doc.data();

      // -------- REPORT --------
      final orderReport = _toInt(d['measurementorder']) ?? 0;
      final reportData = <String, dynamic>{
        'id': d['report'] ?? doc.id, // se você tiver um id específico, use-o; senão, reaproveita o doc.id
        'order': orderReport,
        'numberprocess': d['measurementnumberprocess'],
        'date': _toDate(d['measurementdata']),
        'value': _toDouble(d['measurementinitialvalue']),
        'contractId': contractId,
        'migratedFrom': doc.reference.path,
        'migratedAt': FieldValue.serverTimestamp(),
      }..removeWhere((k, v) => v == null);

      await db
          .collection('contracts').doc(contractId)
          .collection('reportsMeasurement').doc(doc.id) // 1:1 com o measurement antigo
          .set(reportData, SetOptions(merge: true));

      // -------- ADJUSTMENT -------- (fallback para measurementorder)
      final orderAdj = _toInt(d['measurementadjustmentorder'] ?? d['measurementorder']) ?? 0;
      final adjData = <String, dynamic>{
        'id': d['measurementadjustment'] ?? doc.id,
        'order': orderAdj,
        'numberprocess': d['measurementadjustmentnumberprocess'],
        'date': _toDate(d['measurementadjustmentdate']),
        'value': _toDouble(d['measurementadjustmentvalue']),
        'contractId': contractId,
        'migratedFrom': doc.reference.path,
        'migratedAt': FieldValue.serverTimestamp(),
      }..removeWhere((k, v) => v == null);

      await db
          .collection('contracts').doc(contractId)
          .collection('adjustmentsMeasurement').doc(doc.id)
          .set(adjData, SetOptions(merge: true));

      // -------- REVISION -------- (fallback para measurementorder)
      final orderRev = _toInt(d['measurementrevisionorder'] ?? d['measurementorder']) ?? 0;
      final revData = <String, dynamic>{
        'id': d['measurementrevision'] ?? doc.id,
        'order': orderRev,
        'numberprocess': d['measurementrevisionnumberprocess'],
        'date': _toDate(d['measurementrevisiondate']),
        'value': _toDouble(d['measurementvaluerevisionsadjustments']),
        'contractId': contractId,
        'migratedFrom': doc.reference.path,
        'migratedAt': FieldValue.serverTimestamp(),
      }..removeWhere((k, v) => v == null);

      await db
          .collection('contracts').doc(contractId)
          .collection('revisionsMeasurement').doc(doc.id)
          .set(revData, SetOptions(merge: true));
    }
  }

  debugPrint('✅ Migração concluída (sem apagar a coleção original).');
}

