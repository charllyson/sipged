import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_datas/documents/measurement/reports/report_measurement_data.dart';
import '../../../../_widgets/registers/register_class.dart';
import '../../../system/user_bloc.dart';

class ReportMeasurementBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  ReportMeasurementBloc();

  // ---------------------------------------------------------------------------
  // Listagens / consultas
  // ---------------------------------------------------------------------------

  Future<List<ReportMeasurementData>> getAllMeasurementsOfContract({
    required String uidContract,
  }) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('measurements')
        .orderBy('measurementorder')
        .get();

    return snapshot.docs
        .map((doc) => ReportMeasurementData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<List<ReportMeasurementData>> fetchAllMeasurements() async {
    final query = await _db.collectionGroup('measurements').get();
    return query.docs.map((doc) {
      final m = ReportMeasurementData.fromJson(doc.data());
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 3) {
        m.contractId = pathSegments[pathSegments.length - 3];
      }
      return m;
    }).toList();
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    if (!snap.exists) return null;
    return ContractData.fromDocument(snapshot: snap);
  }

  // ---------------------------------------------------------------------------
  // CRUD + regras derivadas
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdateMeasurement(ReportMeasurementData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final ref = _db.collection('contracts').doc(contractId).collection('measurements');

    final docRef = (data.idReportMeasurement != null)
        ? ref.doc(data.idReportMeasurement)
        : ref.doc();
    data.idReportMeasurement ??= docRef.id;

    // 🔢 Somatório das medições existentes
    final measurementsSnap = await ref.get();
    double totalMedicoes = 0.0;
    for (final doc in measurementsSnap.docs) {
      final m = doc.data();
      totalMedicoes += (m['measurementInitialValue'] ?? 0).toDouble()
          + (m['measurementAdjustmentValue'] ?? 0).toDouble()
          + (m['measurementValueRevisionsAdjustments'] ?? 0).toDouble();
    }

    // 🔢 Valor base = contrato inicial + aditivos + apostilas
    final contractSnap = await _db.collection('contracts').doc(contractId).get();
    final contract = contractSnap.data();
    final initialValue = (contract?['initialContractValue'] ?? 0).toDouble();

    final additivesSnap = await _db
        .collection('contracts').doc(contractId).collection('additives').get();
    double totalAditivos = 0.0;
    for (final doc in additivesSnap.docs) {
      totalAditivos += (doc.data()['additiveValue'] ?? 0).toDouble();
    }

    final apostillesSnap = await _db
        .collection('contracts').doc(contractId).collection('apostilles').get();
    double totalApostilles = 0.0;
    for (final doc in apostillesSnap.docs) {
      totalApostilles += (doc.data()['apostilleValue'] ?? 0).toDouble();
    }

    final totalBase = initialValue + totalAditivos + totalApostilles;
    final financialPercentage =
    totalBase > 0 ? (totalMedicoes / totalBase) * 100 : 0.0;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'financialPercentage': financialPercentage,
      });

    // preserva createdAt/createdBy
    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));

    // 🔔 Notificação
    await notificarUsuariosSobreMedicao(data, contractId);
  }

  Future<void> deletarMedicao(String uidContract, String uidMedicao) async {
    final ref = _db
        .collection('contracts')
        .doc(uidContract)
        .collection('measurements')
        .doc(uidMedicao);
    await ref.delete();
  }

  // ---------------------------------------------------------------------------
  // Metadado de PDF (apenas URL no Firestore)
  //  → upload/exists/getUrl/delete ficam no ReportsStorageBloc
  // ---------------------------------------------------------------------------

  Future<void> salvarUrlPdfDaMedicao({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(measurementId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF da medição: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notificações
  // ---------------------------------------------------------------------------

  Future<void> notificarUsuariosSobreMedicao(
      ReportMeasurementData medicao, String contractId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final List<String> uidsParaNotificar = [uid];
    final batch = _db.batch();

    for (final userId in uidsParaNotificar) {
      final ref = _db.collection('users').doc(userId).collection('notifications').doc();

      batch.set(ref, {
        'tipo': 'medicao',
        'titulo': 'Nova medição nº ${medicao.orderReportMeasurement}',
        'contractId': contractId,
        'measurementId': medicao.idReportMeasurement,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  Stream<List<Registro>> getNotificacoesRecentesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Registro> registros = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['tipo'] != 'medicao') continue;

        final contractId = data['contractId'];
        final idOriginal = data['measurementId'];

        final originalSnap = await _db
            .collection('contracts')
            .doc(contractId)
            .collection('measurements')
            .doc(idOriginal)
            .get();

        if (originalSnap.exists) {
          final original = ReportMeasurementData.fromDocument(snapshot: originalSnap);
          registros.add(Registro(
            id: doc.id,
            tipo: 'medicao',
            data: data['createdAt']?.toDate() ?? DateTime.now(),
            original: original,
            contractData: await buscarContrato(contractId),
          ));
        }
      }
      return registros;
    });
  }

  // ---------------------------------------------------------------------------
  // Agregações
  // ---------------------------------------------------------------------------

  Future<double> somarValorMedicoes({
    required List<ReportMeasurementData> medicoes,
  }) async {
    return medicoes.fold<double>(
        0.0, (s, m) => s + (m.valueReportMeasurement ?? 0.0));
  }

  Future<double> somarValorReajustes({
    required List<ReportMeasurementData> medicoes,
  }) async {
    return medicoes.fold<double>(
        0.0, (s, m) => s + (m.valueAdjustmentMeasurement ?? 0.0));
  }

  Future<double> somarValorRevisoes({
    required List<ReportMeasurementData> medicoes,
  }) async {
    return medicoes.fold<double>(
        0.0, (s, m) => s + (m.valueRevisionMeasurement ?? 0.0));
  }

  Future<List<double>> calcularTotais(List<ReportMeasurementData> dados) async {
    return Future.wait([
      somarValorMedicoes(medicoes: dados),
      somarValorReajustes(medicoes: dados),
      somarValorRevisoes(medicoes: dados),
    ]);
  }

  // ---------------------------------------------------------------------------

  Future<void> adicionarContractIdNasMedicoes() async {
    final contratosSnapshot = await _db.collection('contracts').get();

    for (final contratoDoc in contratosSnapshot.docs) {
      final contractId = contratoDoc.id;
      final measurementsRef = contratoDoc.reference.collection('measurements');
      final measurementsSnapshot = await measurementsRef.get();

      for (final medicaoDoc in measurementsSnapshot.docs) {
        final data = medicaoDoc.data();
        if (data.containsKey('contractId')) continue;
        await medicaoDoc.reference.update({'contractId': contractId});
      }
    }

    debugPrint('✔️ Processo finalizado para medições.');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
