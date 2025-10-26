import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_widgets/registers/register_class.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';

class ReportMeasurementBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection(ReportMeasurementData.collectionName);

  Future<List<ReportMeasurementData>> getAllMeasurementsOfContract({
    required String uidContract,
  }) async {
    final snapshot = await _col(uidContract).orderBy('order').get();
    return snapshot.docs.map((doc) => ReportMeasurementData.fromDocument(doc)).toList();
  }

  Future<List<ReportMeasurementData>> fetchAllMeasurements() async {
    final query = await _db.collectionGroup(ReportMeasurementData.collectionName).get();
    return query.docs.map((doc) {
      final m = ReportMeasurementData.fromMap(doc.data());
      m.contractId = doc.reference.parent.parent?.id;
      m.id = doc.id;
      return m;
    }).toList();
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    if (!snap.exists) return null;
    return ContractData.fromDocument(snapshot: snap);
  }

  // -------------------------- CRUD: REPORT --------------------------
  Future<void> saveOrUpdateReport(ReportMeasurementData report) async {
    final user = FirebaseAuth.instance.currentUser;
    final contractId = report.contractId;
    if (contractId == null) throw Exception('contractId é obrigatório');

    final ref = _col(contractId);
    final docRef = (report.id != null) ? ref.doc(report.id) : ref.doc();
    report.id ??= docRef.id;

    final data = report.toFirestore()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
        'contractId': contractId,
      });

    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = user?.uid ?? '';
    }

    await docRef.set(data, SetOptions(merge: true));
    await _recalcularFinancialPercentage(contractId);
    await _notificar(report, contractId);
  }

  Future<void> deletarMedicao(String uidContract, String uidMedicao) async {
    await _col(uidContract).doc(uidMedicao).delete();
    // não recalcula aqui de propósito; depende do seu fluxo
  }

  // -------------------------- PDF URL (só metadado) --------------------------
  Future<void> salvarUrlPdfDaMedicao({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    try {
      await _col(contractId).doc(measurementId).update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF (report): $e');
    }
  }

  // -------------------------- Notificações --------------------------
  Future<void> _notificar(ReportMeasurementData report, String contractId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = _db.collection('users').doc(uid).collection('notifications').doc();
    await ref.set({
      'tipo': 'medicao',
      'titulo': 'Nova medição nº ${report.order}',
      'contractId': contractId,
      'measurementId': report.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  Stream<List<Registro>> getNotificacoesRecentesStream(String uid) {
    return _db
        .collection('users').doc(uid).collection('notifications')
        .orderBy('createdAt', descending: true).limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Registro> out = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['tipo'] != 'medicao') continue;

        final contractId = data['contractId'];
        final idOriginal = data['measurementId'];
        final originalSnap = await _db
            .collection('contracts').doc(contractId)
            .collection(ReportMeasurementData.collectionName).doc(idOriginal).get();

        if (originalSnap.exists) {
          final original = ReportMeasurementData.fromDocument(originalSnap);
          out.add(Registro(
            id: doc.id,
            tipo: 'medicao',
            data: data['createdAt']?.toDate() ?? DateTime.now(),
            original: original,
            contractData: await buscarContrato(contractId),
          ));
        }
      }
      return out;
    });
  }

  // -------------------------- Agregações simples (Report) --------------------------
  Future<double> somarValorMedicoes({
    required List<ReportMeasurementData> medicoes,
  }) async {
    return medicoes.fold<double>(0.0, (s, m) => s + (m.value ?? 0.0));
  }

  // -------------------------- Util: recalcular % financeiro --------------------------
  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double total = 0.0;

    final reps = await _db.collection('contracts').doc(contractId)
        .collection('reportsMeasurement').get();
    for (final d in reps.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final adjs = await _db.collection('contracts').doc(contractId)
        .collection('adjustmentsMeasurement').get();
    for (final d in adjs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final revs = await _db.collection('contracts').doc(contractId)
        .collection('revisionsMeasurement').get();
    for (final d in revs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final contractSnap = await _db.collection('contracts').doc(contractId).get();
    final initialValue = (contractSnap.data()?['initialContractValue'] ?? 0);
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

  // ==================== ITENS DA MEDIÇÃO (por item do Budget) ====================
  // contracts/{contractId}/reportsMeasurement/{measurementId}/items/{budgetItemId}

  CollectionReference<Map<String, dynamic>> _itemsCol({
    required String contractId,
    required String measurementId,
  }) =>
      _db.collection('contracts')
          .doc(contractId)
          .collection(ReportMeasurementData.collectionName)
          .doc(measurementId)
          .collection('items');

  Future<Map<String, Map<String, dynamic>>> loadItemsMap({
    required String contractId,
    required String measurementId,
  }) async {
    final qs = await _itemsCol(contractId: contractId, measurementId: measurementId).get();
    final out = <String, Map<String, dynamic>>{};
    for (final d in qs.docs) {
      final m = d.data();
      out[d.id] = {
        'qtyPrev': (m['qtyPrev'] ?? 0).toDouble(),
        'qtyPeriod': (m['qtyPeriod'] ?? 0).toDouble(),
        'qtyAccum': (m['qtyAccum'] ?? 0).toDouble(),
        'qtyContractBal': (m['qtyContractBal'] ?? 0).toDouble(),
        'valPrev': (m['valPrev'] ?? 0).toDouble(),
        'valPeriod': (m['valPeriod'] ?? 0).toDouble(),
        'valAccum': (m['valAccum'] ?? 0).toDouble(),
        'valContractBal': (m['valContractBal'] ?? 0).toDouble(),
        'updatedAt': m['updatedAt'],
        'updatedBy': m['updatedBy'],
        'budgetItemId': m['budgetItemId'] ?? d.id,
      };
    }
    return out;
  }

  Future<void> upsertMeasurementItem({
    required String contractId,
    required String measurementId,
    required String budgetItemId,
    required Map<String, dynamic> payload,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final data = <String, dynamic>{
      'budgetItemId': budgetItemId,
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
      'contractId': contractId,
      'measurementId': measurementId,
    };
    await _itemsCol(contractId: contractId, measurementId: measurementId)
        .doc(budgetItemId)
        .set(data, SetOptions(merge: true));
  }

  // snapshot + itens em lote + atualizar value (inalterado)
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  Future<void> saveBreakdownSnapshot({
    required String contractId,
    required String measurementId,
    required Map<String, dynamic> breakdown,
  }) async {
    await _col(contractId).doc(measurementId).set({
      'breakdown': {
        'headers': List<String>.from(breakdown['headers'] ?? const <String>[]),
        'colTypes': List<String>.from(breakdown['colTypes'] ?? const <String>[]),
        'colWidths': List<double>.from(
          (breakdown['colWidths'] as List? ?? const <double>[])
              .map((e) => (e is num) ? e.toDouble() : double.tryParse('$e') ?? 120.0),
        ),
        'rows': List<List<String>>.from(
          (breakdown['rows'] as List? ?? const <List<dynamic>>[])
              .map((r) => List<String>.from(r.map((e) => '$e'))),
        ),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> bulkUpsertMeasurementItems({
    required String contractId,
    required String measurementId,
    required Map<String, Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) return;

    final entries = items.entries.toList();
    const int kMaxBatch = 500;
    for (final chunk in _chunk(entries, kMaxBatch)) {
      final batch = _db.batch();
      for (final e in chunk) {
        final budgetItemId = e.key;
        final m = e.value;
        final docRef = _itemsCol(contractId: contractId, measurementId: measurementId).doc(budgetItemId);

        final data = <String, dynamic>{
          'budgetItemId': budgetItemId,
          'qtyPrev': (m['qtyPrev'] ?? 0) is num ? (m['qtyPrev'] as num).toDouble() : 0.0,
          'qtyPeriod': (m['qtyPeriod'] ?? 0) is num ? (m['qtyPeriod'] as num).toDouble() : 0.0,
          'qtyAccum': (m['qtyAccum'] ?? 0) is num ? (m['qtyAccum'] as num).toDouble() : 0.0,
          'qtyContractBal': (m['qtyContractBal'] ?? 0) is num ? (m['qtyContractBal'] as num).toDouble() : 0.0,
          'valPrev': (m['valPrev'] ?? 0) is num ? (m['valPrev'] as num).toDouble() : 0.0,
          'valPeriod': (m['valPeriod'] ?? 0) is num ? (m['valPeriod'] as num).toDouble() : 0.0,
          'valAccum': (m['valAccum'] ?? 0) is num ? (m['valAccum'] as num).toDouble() : 0.0,
          'valContractBal': (m['valContractBal'] ?? 0) is num ? (m['valContractBal'] as num).toDouble() : 0.0,
          'contractId': contractId,
          'measurementId': measurementId,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        };

        batch.set(docRef, data, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Future<void> updateMeasurementValue({
    required String contractId,
    required String measurementId,
    required double value,
  }) async {
    await _col(contractId).doc(measurementId).set({
      'value': value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    }, SetOptions(merge: true));

    await _recalcularFinancialPercentage(contractId);
  }

  @override
  void dispose() {
    // nada a cancelar no momento
    super.dispose();
  }
}
