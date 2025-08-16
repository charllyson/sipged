import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../_datas/documents/measurement/measurement_data.dart';
import '../../system/user_bloc.dart';


class ReportsBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  ReportsBloc();


  Future<List<ReportData>> getAllMeasurementsOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('measurements')
        .orderBy('measurementorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return ReportData.fromDocument(snapshot: doc);
    }).toList();
    return list;
  }

  Future<List<ReportData>> fetchAllMeasurements() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collectionGroup('measurements').get();
    return querySnapshot.docs.map((doc) {
      final measurement = ReportData.fromJson(doc.data());
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 2) {
        measurement.contractId = pathSegments[pathSegments.length - 3];
      }
      return measurement;
    }).toList();
  }

  Future<void> saveOrUpdateMeasurement(ReportData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final ref = _db.collection('contracts').doc(contractId).collection('measurements');
    final docRef = data.idReportMeasurement != null ? ref.doc(data.idReportMeasurement) : ref.doc();
    data.idReportMeasurement ??= docRef.id;

    // 🔢 Buscar todas as medições
    final measurementsSnap = await ref.get();
    double totalMedicoes = 0.0;
    for (final doc in measurementsSnap.docs) {
      final m = doc.data();
      totalMedicoes += (m['measurementInitialValue'] ?? 0).toDouble()
          + (m['measurementAdjustmentValue'] ?? 0).toDouble()
          + (m['measurementValueRevisionsAdjustments'] ?? 0).toDouble();
    }

    // 🔢 Buscar contrato
    final contractSnap = await _db.collection('contracts').doc(contractId).get();
    final contract = contractSnap.data();
    final initialValue = (contract?['initialContractValue'] ?? 0).toDouble();

    // 🔢 Buscar aditivos
    final additivesSnap = await _db.collection('contracts').doc(contractId).collection('additives').get();
    double totalAditivos = 0.0;
    for (final doc in additivesSnap.docs) {
      totalAditivos += (doc.data()['additiveValue'] ?? 0).toDouble();
    }

    // 🔢 Buscar apostilamentos
    final apostillesSnap = await _db.collection('contracts').doc(contractId).collection('apostilles').get();
    double totalApostilles = 0.0;
    for (final doc in apostillesSnap.docs) {
      totalApostilles += (doc.data()['apostilleValue'] ?? 0).toDouble();
    }

    final totalBase = initialValue + totalAditivos + totalApostilles;

    double financialPercentage = 0.0;
    if (totalBase > 0) {
      financialPercentage = (totalMedicoes / totalBase) * 100;
    }

    // 🔄 Atualizar json com os dados
    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'financialPercentage': financialPercentage,
      });

    // 🔒 Garantir createdAt
    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    // 💾 Salvar no Firestore
    await docRef.set(json, SetOptions(merge: true));

    // 🔔 Notificação
    await notificarUsuariosSobreMedicao(data, contractId);
  }


  Future<void> notificarUsuariosSobreMedicao(ReportData medicao, String contractId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final List<String> uidsParaNotificar = [uid];
    final batch = FirebaseFirestore.instance.batch();

    for (final uid in uidsParaNotificar) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();

      batch.set(ref, {
        'tipo': 'medicao', // padronizado
        'titulo': 'Nova medição nº ${medicao.orderReportMeasurement}',
        'contractId': contractId,
        'measurementId': medicao.idReportMeasurement,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  /*Stream<List<Registro>> getNotificacoesRecentesStream(String uid) {
    return FirebaseFirestore.instance
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
        final tipo = data['tipo'];
        final contractId = data['contractId'];
        final idOriginal = data['measurementId'];

        if (tipo == 'medicao') {
          final originalSnap = await FirebaseFirestore.instance
              .collection('contracts')
              .doc(contractId)
              .collection('measurements')
              .doc(idOriginal)
              .get();

          if (originalSnap.exists) {
            final original = MeasurementData.fromDocument(snapshot: originalSnap);

            registros.add(Registro(
              id: doc.id,
              tipo: tipo,
              data: data['createdAt']?.toDate() ?? DateTime.now(),
              original: original, // ✅ diretamente como dynamic
              contractData: await _buscarContrato(contractId),
            ));
          }
        }
      }

      return registros;
    });
  }
*/

  Future<void> deletarMedicao(String uidContract, String uidMedicao) async {
    final ref = _db
        .collection('contracts')
        .doc(uidContract)
        .collection('measurements')
        .doc(uidMedicao);
    await ref.delete();
  }


  String getNomePadronizadoPdfDaMedicao({
    required String contractNumber,
    required ReportData measurement,
  }) {
    return '$contractNumber-${measurement.orderReportMeasurement}-${measurement.numberAdjustmentProcessMeasurement}.pdf';
  }


  Future<void> salvarUrlPdfDaMedicao({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
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
      print('Erro ao salvar URL do PDF da medição: $e');
    }
  }


  Future<void> selecionarEPdfDeMedicaoComProgresso({
    required String contractId,
    required ReportData measurementData,
    required void Function(double progress) onProgress,
    required void Function(bool success) onComplete,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final Uint8List fileBytes = result.files.single.bytes!;

        final contractSnap = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .get();
        final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

        final fileName =
            '$contractNumber-${measurementData.orderReportMeasurement}-${measurementData.numberAdjustmentProcessMeasurement}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'contracts/$contractId/measurements/${measurementData.idReportMeasurement}/$fileName',
        );
        final metadata = SettableMetadata(contentType: 'application/pdf');

        final uploadTask = ref.putData(fileBytes, metadata);

        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });

        await uploadTask;
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .collection('measurements')
            .doc(measurementData.idReportMeasurement)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      print('Erro ao enviar PDF da medição: $e');
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeMedicaoExiste({
    required ContractData contract,
    required ReportData measurement,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${measurement.orderReportMeasurement}-${measurement.numberAdjustmentProcessMeasurement}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/measurements/${measurement.idReportMeasurement}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaMedicao({
    required ContractData contract,
    required ReportData measurement,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${measurement.orderReportMeasurement}-${measurement.numberAdjustmentProcessMeasurement}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/measurements/${measurement.idReportMeasurement}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao obter URL do PDF da medição: $e');
      return null;
    }
  }

  Future<bool> deletarPdfDaMedicao({
    required String contractId,
    required ReportData measurement,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName =
          '$contractNumber-${measurement.orderReportMeasurement}-${measurement.numberAdjustmentProcessMeasurement}.pdf';
      final path = 'contracts/$contractId/measurements/${measurement.idReportMeasurement}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(measurement.idReportMeasurement)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF da medição: $e');
      return false;
    }
  }

  Future<double> somarValorMedicoes({
    required List<ReportData> medicoes,
  }) async {
    return medicoes.fold<double>(
      0.0,
          (soma, m) => soma + (m.valueReportMeasurement ?? 0.0),
    );
  }

  Future<double> somarValorReajustes({
    required List<ReportData> medicoes,
  }) async {
    return medicoes.fold<double>(
      0.0,
          (soma, m) => soma + (m.valueAdjustmentMeasurement ?? 0.0),
    );
  }

  Future<double> somarValorRevisoes({
    required List<ReportData> medicoes,
  }) async {
    return medicoes.fold<double>(
      0.0,
          (soma, m) => soma + (m.valueRevisionMeasurement ?? 0.0),
    );
  }

  Future<void> adicionarContractIdNasMedicoes() async {
    final firestore = FirebaseFirestore.instance;
    final contratosSnapshot = await firestore.collection('contracts').get();

    for (final contratoDoc in contratosSnapshot.docs) {
      final contractId = contratoDoc.id;
      final measurementsRef = contratoDoc.reference.collection('measurements');

      final measurementsSnapshot = await measurementsRef.get();

      for (final medicaoDoc in measurementsSnapshot.docs) {
        final data = medicaoDoc.data();

        // Se já tiver contractId, pula
        if (data.containsKey('contractId')) continue;

        // Atualiza com contractId
        await medicaoDoc.reference.update({
          'contractId': contractId,
        });
      }
    }

    print('✔️ Processo finalizado para medições.');
  }


  Future<List<double>> calcularTotais(List<ReportData> dados) async {
    return Future.wait([
      somarValorMedicoes(medicoes: dados),
      somarValorReajustes(medicoes: dados),
      somarValorRevisoes(medicoes: dados),
    ]);
  }


}
