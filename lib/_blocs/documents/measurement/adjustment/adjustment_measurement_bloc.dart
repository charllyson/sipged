import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_data.dart';

class AdjustmentMeasurementBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection(AdjustmentMeasurementData.collectionName);

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsOfContract({
    required String uidContract,
  }) async {
    final qs = await _col(uidContract).orderBy('order').get();
    return qs.docs.map((d) => AdjustmentMeasurementData.fromDocument(d)).toList();
  }

  Future<void> saveOrUpdateAdjustment({
    required String contractId,
    required String measurementId, // id do doc (mantido por compat)
    required AdjustmentMeasurementData adj,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final docRef = _col(contractId).doc(measurementId);

    adj.id ??= measurementId; // garante que o id vá para o payload

    final data = adj.toFirestore()
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

  Future<void> deleteAdjustment({
    required String contractId,
    required String adjustmentId,
  }) async {
    await _col(contractId).doc(adjustmentId).delete();
    await _recalcularFinancialPercentage(contractId);
  }

  // ✅ novo: salva a URL do PDF diretamente no doc da coleção de adjustments
  Future<void> salvarUrlPdfDaAdjustmentMeasurement({
    required String contractId,
    required String adjustmentId,
    required String url,
  }) async {
    await _col(contractId).doc(adjustmentId).set({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double total = 0.0;

    // reports
    final reps = await _db.collection('contracts').doc(contractId)
        .collection('reportsMeasurement').get();
    for (final d in reps.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    // adjustments
    final adjs = await _db.collection('contracts').doc(contractId)
        .collection('adjustmentsMeasurement').get();
    for (final d in adjs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    // revisions
    final revs = await _db.collection('contracts').doc(contractId)
        .collection('revisionsMeasurement').get();
    for (final d in revs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    // base = inicial + aditivos + apostilas
    final c = await _db.collection('contracts').doc(contractId).get();
    final initialValue = (c.data()?['initialContractValue'] ?? 0);
    final baseInicial = (initialValue is num) ? initialValue.toDouble() : 0.0;

    final adds = await _db.collection('contracts').doc(contractId).collection('additives').get();
    double totAdd = 0.0;
    for (final a in adds.docs) {
      final v = (a.data()['additiveValue'] ?? 0);
      totAdd += (v is num) ? v.toDouble() : 0;
    }

    final apos = await _db.collection('contracts').doc(contractId).collection('apostilles').get();
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

  @override
  void dispose() { super.dispose(); }
}
