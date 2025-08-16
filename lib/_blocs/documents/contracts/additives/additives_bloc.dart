import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../system/user_bloc.dart';

class AdditivesBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  AdditivesBloc();

  Future<List<AdditiveData>> getAdditivesByContractIds(Set<String> contractIds) async {
    final all = await getAllAdditives();
    return all.where((a) => contractIds.contains(a.contractId)).toList();
  }
  /// Busca todos os aditivos de todos os contratos
  Future<List<AdditiveData>> getAllAdditives() async {
    final contratosSnapshot = await _db.collection('contracts').get();

    final List<AdditiveData> todosAditivos = [];

    for (final contrato in contratosSnapshot.docs) {
      final aditivosSnapshot = await contrato.reference.collection('additives').get();

      for (final doc in aditivosSnapshot.docs) {
        final data = doc.data();
        final aditivo = AdditiveData.fromMap(data, id: doc.id);
        todosAditivos.add(aditivo);
      }
    }

    return todosAditivos;
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
        final idOriginal = data['additiveId'];

        if (tipo == 'aditivo') {
          final originalSnap = await FirebaseFirestore.instance
              .collection('contracts')
              .doc(contractId)
              .collection('additives')
              .doc(idOriginal)
              .get();

          if (originalSnap.exists) {
            final original = AdditiveData.fromDocument(snapshot: originalSnap);

            registros.add(Registro(
              id: doc.id,
              tipo: tipo,
              data: data['createdAt']?.toDate() ?? DateTime.now(),
              original: original,
              contractData: await buscarContrato(contractId),
            ));
          }
        }
      }

      return registros;
    });
  }*/

  Future<double> getValorPorStatus(List<ContractData> contratos, String statusDesejado) async {
    final contratosFiltrados = contratos.where((c) =>
    (c.contractStatus ?? '').toUpperCase() == statusDesejado.toUpperCase()).toList();

    double total = 0.0;

    // Executa todos os gets em paralelo
    final futures = contratosFiltrados.map((contrato) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contrato.id)
          .collection('additives')
          .get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final valor = doc.data()['additivevalue'];
        return sum + (valor is num ? valor.toDouble() : 0.0);
      });
    });

    final resultados = await Future.wait(futures);
    total = resultados.fold(0.0, (a, b) => a + b);

    return total;
  }



  Future<ContractData?> buscarContrato(String contractId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('contracts')
        .doc(contractId)
        .get();

    if (!snapshot.exists) return null;
    return ContractData.fromDocument(snapshot: snapshot);
  }


  Future<double> somarValoresAditivosPorStatus({
    required List<ContractData> contratos,
    required String status,
  }) async {
    double total = 0.0;

    final contratosFiltrados = contratos.where((c) => c.contractStatus == status).toList();

    for (final contrato in contratosFiltrados) {
      final snapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contrato.id)
          .collection('additives')
          .get();

      for (final doc in snapshot.docs) {
        try {
          final additive = AdditiveData.fromDocument(snapshot: doc);
          final valor = additive.additiveValue ?? 0.0;
          total += valor;
        } catch (e) {
        }
      }
    }
    return total;
  }


  Future<List<AdditiveData>> getAllAdditivesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('additives')
        .orderBy('additiveorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return AdditiveData.fromDocument(snapshot: doc);
    }).toList();
    return list;
  }

  Future<void> salvarOuAtualizarAditivo(AdditiveData data, String uidContract) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('additives');

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

    // ✅ Notificar usuários
    await notificarUsuariosSobreAditivo(data, uidContract);
  }

  Future<void> notificarUsuariosSobreAditivo(AdditiveData aditivo, String contractId) async {
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
        'tipo': 'aditivo', // padronizado
        'titulo': 'Novo aditivo nº ${aditivo.additiveOrder}',
        'contractId': contractId,
        'additiveId': aditivo.id,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  Future<void> deleteAdditive(String uidContract, String uidAditivo) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('additives')
          .doc(uidAditivo)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar aditivo: $e');
    }
  }


  Future<void> selecionarEPDFDeAditivoComProgresso({
    required String contractId,
    required AdditiveData additiveData,
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
        final fileName = '$contractNumber-${additiveData.additiveOrder}-${additiveData.additiveNumberProcess}.pdf';

        final ref = FirebaseStorage.instance.ref('contracts/$contractId/additives/${additiveData.id}/$fileName');
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
            .collection('additives')
            .doc(additiveData.id)
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
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeAditivoExiste({
    required ContractData contract,
    required AdditiveData additive,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final additiveOrder = additive.additiveOrder ?? '0';
    final additiveNumberProcess = additive.additiveNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$additiveOrder-$additiveNumberProcess.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/additives/${additive.id}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  ///
  Future<String?> getPdfUrlDoAditivo({
    required ContractData contract,
    required AdditiveData additive,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final additiveOrder = additive.additiveOrder ?? '0';
    final additiveNumberProcess = additive.additiveNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$additiveOrder-$additiveNumberProcess.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/additives/${additive.id}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }



  Future<bool> deletarPdfDoAditivo({
    required String contractId,
    required AdditiveData additiveData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName = '$contractNumber-${additiveData.additiveOrder}-${additiveData.additiveNumberProcess}.pdf';
      final pdfPath = 'contracts/$contractId/additives/${additiveData.id}/$fileName';

      await FirebaseStorage.instance.ref(pdfPath).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .doc(additiveData.id)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> salvarUrlPdfDoAditivo({
    required String contractId,
    required String additiveId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .doc(additiveId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF do aditivo no Firestore: $e');
    }
  }

  Future<double> getAllAdditivesValue(String contractId) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();

    return snapshot.docs.fold<double>(0.0, (sum, doc) {
      final additive = AdditiveData.fromDocument(snapshot: doc);
      final valor = additive.additiveValue ?? 0.0;
      return sum + valor;
    });
  }






}
