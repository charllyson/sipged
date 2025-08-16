import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../_datas/documents/contracts/apostilles/apostilles_data.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../system/user_bloc.dart';

class ApostillesBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  ApostillesBloc();

  Future<List<ApostillesData>> getAllApostilles() async {
    final query = await FirebaseFirestore.instance
        .collectionGroup('apostilles')
        .get();

    return query.docs
        .map((doc) => ApostillesData.fromMap(doc.data()))
        .toList();
  }

  Future<List<ApostillesData>> getAdditivesByContractIds(Set<String> contractIds) async {
    final all = await getAllApostilles();
    return all.where((a) => contractIds.contains(a.contractId)).toList();
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
        final idOriginal = data['apostilleId'];

        if (tipo == 'apostilamento') {
          final originalSnap = await FirebaseFirestore.instance
              .collection('contracts')
              .doc(contractId)
              .collection('apostilles')
              .doc(idOriginal)
              .get();

          if (originalSnap.exists) {
            final original = ApostillesData.fromDocument(snapshot: originalSnap);
            final contrato = await _buscarContrato(contractId);

            registros.add(Registro(
              id: doc.id,
              tipo: tipo,
              data: data['createdAt']?.toDate() ?? DateTime.now(),
              original: original,
              contractData: contrato,
            ));
          }
        }
      }

      return registros;
    });
  }*/

  Future<void> adicionarContractIdNasApostilas() async {
    final firestore = FirebaseFirestore.instance;
    final contratosSnapshot = await firestore.collection('contracts').get();

    for (final contratoDoc in contratosSnapshot.docs) {
      final contractId = contratoDoc.id;
      final apostillesRef = contratoDoc.reference.collection('apostilles');

      final apostillesSnapshot = await apostillesRef.get();

      for (final apostilaDoc in apostillesSnapshot.docs) {
        final data = apostilaDoc.data();

        // Se já tiver contractId, pula
        if (data.containsKey('contractId')) continue;

        // Atualiza com contractId
        await apostilaDoc.reference.update({
          'contractId': contractId,
        });

        print('✅ Apostila ${apostilaDoc.id} atualizada com contractId: $contractId');
      }
    }

    print('✔️ Processo finalizado para apostilas.');
  }

  Future<double> getValorPorStatus(List<ContractData> contratos, String statusDesejado) async {
    final contratosFiltrados = contratos.where((c) =>
    (c.contractStatus ?? '').toUpperCase() == statusDesejado.toUpperCase()).toList();

    final futures = contratosFiltrados.map((contrato) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contrato.id)
          .collection('apostilles')
          .get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final valor = doc.data()['apostillevalue'];
        return sum + (valor is num ? valor.toDouble() : 0.0);
      });
    });

    final resultados = await Future.wait(futures);
    return resultados.fold<double>(0.0, (a, b) => a + b);
  }





  Future<void> notificarUsuariosSobreApostilamento(ApostillesData apostila, String contractId) async {
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
        'tipo': 'apostilamento', // padronizado
        'titulo': 'Novo apostilamento nº ${apostila.apostilleOrder}',
        'contractId': contractId,
        'apostilleId': apostila.id,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  Future<double> somarValoresApostilamentosPorStatus({
    required List<ContractData> contratos,
    required String status,
  }) async {
    double total = 0.0;

    for (final contrato in contratos) {
      if (contrato.contractStatus != status) continue;

      final apostillesSnapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contrato.id)
          .collection('apostilles')
          .get();

      for (final doc in apostillesSnapshot.docs) {
        final data = doc.data();
        final value = data['apostillevalue'] ?? 0.0;
        total += (value is int) ? value.toDouble() : value;
      }
    }

    return total;
  }



  ///
  Future<List<ApostillesData>> getAllApostillesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles')
        .orderBy('apostilleorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return ApostillesData.fromDocument(snapshot: doc);
    }).toList();

    return list;
  }

  Future<void> deletarApostille(String uidContract, String uidApostille) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('apostilles')
          .doc(uidApostille)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar apostilamento: $e');
    }
  }


  Future<void> saveOrUpdateApostille(ApostillesData data, String uidContract) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles');

    final docRef = data.id != null ? ref.doc(data.id) : ref.doc();
    data.id ??= docRef.id;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'contractId': uidContract,
      });

    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));

    await notificarUsuariosSobreApostilamento(data, uidContract);
  }


  Future<void> salvarUrlPdfDaApostila({
    required String contractId,
    required String apostilleId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .doc(apostilleId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF da apostila no Firestore: $e');
    }
  }


  Future<void> selecionarEPdfDeApostilaComProgresso({
    required String contractId,
    required ApostillesData apostilleData,
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
        final fileName = '$contractNumber-${apostilleData.apostilleOrder}-${apostilleData.apostilleNumberProcess}.pdf';

        final ref = FirebaseStorage.instance.ref('contracts/$contractId/apostilles/${apostilleData.id}/$fileName');
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
            .collection('apostilles')
            .doc(apostilleData.id)
            .update({
          'pdfUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        });

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      debugPrint('Erro ao enviar PDF da apostila: $e');
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeApostilaExiste({
    required ContractData contract,
    required ApostillesData apostille,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final order = apostille.apostilleOrder ?? '0';
    final process = apostille.apostilleNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$order-$process.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/apostilles/${apostille.id}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaApostila({
    required ContractData contract,
    required ApostillesData apostille,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final order = apostille.apostilleOrder ?? '0';
    final process = apostille.apostilleNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$order-$process.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/apostilles/${apostille.id}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao obter URL da apostila: $e');
      return null;
    }
  }

  Future<bool> deletarPdfDaApostila({
    required String contractId,
    required ApostillesData apostilleData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName = '$contractNumber-${apostilleData.apostilleOrder}-${apostilleData.apostilleNumberProcess}.pdf';

      final pdfPath = 'contracts/$contractId/apostilles/${apostilleData.id}/$fileName';

      await FirebaseStorage.instance.ref(pdfPath).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .doc(apostilleData.id)
          .update({
        'pdfUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar PDF da apostila: $e');
      return false;
    }
  }

  Future<double> getAllApostillesValue(String contractId) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();
      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final apostilles = ApostillesData.fromDocument(snapshot: doc);
        final valor = apostilles.apostilleValue ?? 0.0;
        return sum + valor;
      });
    }



}
