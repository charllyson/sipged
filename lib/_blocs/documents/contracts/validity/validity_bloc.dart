import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/documents/contracts/validity/validity_data.dart';
import '../../../system/user_bloc.dart';

class ValidityBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  ValidityBloc();

  ///Recuperando todos os contratos
  Future<List<ContractData>> getAllContracts() {
    return _db.collection('contracts').get().then((snapshot) {
      return snapshot.docs.map((doc) {
        return ContractData.fromDocument(snapshot: doc);
      }).toList();
    });
  }

  Future<ContractData?> getSpecificContract({required String uid}) async {
    final snapshot = await FirebaseFirestore.instance.collection('contracts').doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    return ContractData.fromDocument(snapshot: snapshot);
  }

  Future<bool> verificarSePdfDeValidadeExiste({
    required ContractData contract,
    required ValidityData validade,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${validade.orderNumber}-${validade.ordertype}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/orders/${validade.id}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaValidade({
    required ContractData contract,
    required ValidityData validade,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${validade.orderNumber}-${validade.ordertype}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/orders/${validade.id}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao obter URL do PDF da validade: $e');
      return null;
    }
  }

  Future<void> selecionarEPdfDeValidadeComProgresso({
    required String contractId,
    required ValidityData validadeData,
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

        final fileName = '$contractNumber-${validadeData.orderNumber}-${validadeData.ordertype}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'contracts/$contractId/orders/${validadeData.id}/$fileName',
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
            .collection('orders')
            .doc(validadeData.id)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      debugPrint('Erro ao enviar PDF da validade: $e');
      onComplete(false);
    }
  }

  Future<bool> deletarPdfDaValidade({
    required String contractId,
    required ValidityData validade,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();
      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

      final fileName = '$contractNumber-${validade.orderNumber}-${validade.ordertype}.pdf';
      final path = 'contracts/$contractId/orders/${validade.id}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('orders')
          .doc(validade.id)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar PDF da validade: $e');
      return false;
    }
  }

  Future<void> salvarUrlPdfDaValidade({
    required String contractId,
    required String validadeId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('orders') // subcoleção de validades
          .doc(validadeId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF da validade no Firestore: $e');
    }
  }

  Future<void> salvarOuAtualizarValidade(ValidityData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final uidContract = data.uidContract;
    if (uidContract == null) {
      throw Exception("Contrato não informado");
    }

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('orders');

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

    // ✅ Notificação
    await notificarUsuariosSobreValidade(data, uidContract);
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
        final idOriginal = data['validityId'];

        if (tipo == 'validade') {
          final originalSnap = await FirebaseFirestore.instance
              .collection('contracts')
              .doc(contractId)
              .collection('orders')
              .doc(idOriginal)
              .get();

          if (originalSnap.exists) {
            final original = ValidityData.fromDocument(snapshot: originalSnap);

            registros.add(Registro(
              id: doc.id,
              tipo: tipo,
              data: data['createdAt']?.toDate() ?? DateTime.now(),
              original: original,
              contractData: await _buscarContrato(contractId),
            ));
          }
        }
      }

      return registros;
    });
  }*/


  ///deletando uma validade
  Future<void> deletarValidade(String uidContract, String uidValidade) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('orders')
          .doc(uidValidade)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar validade: $e');
    }
  }

  Future<List<ValidityData>> getAllValidityOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders')
        .orderBy('ordernumber')
        .get();

    final list = snapshot.docs.map((doc) {
      return ValidityData.fromDocument(snapshot: doc);
    }).toList();

    return list;
  }

  Future<void> notificarUsuariosSobreValidade(ValidityData validade, String contractId) async {
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
        'tipo': 'validade', // padronizado
        'titulo': validade.ordertype,
        'contractId': contractId,
        'validityId': validade.id,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  Future<DateTime?> calcularDataFinalContrato({required ContractData contract}) async {
    if (contract.id == null || contract.publicationDateDoe == null) return null;

    final additives = await _buscarAditivos(contract.id!);

    final diasValidadeInicial = contract.initialValidityContractDays ?? 0;
    final diasAditivos = additives.fold<int>(
      0, (soma, a) => soma + (a.additiveValidityContractDays ?? 0),
    );

    final totalDias = diasValidadeInicial + diasAditivos;

    return contract.publicationDateDoe!.add(Duration(days: totalDias));
  }


  Future<DateTime?> calcularDataFinalExecucao({required ContractData contract}) async {
    if (contract.id == null) return null;

    final additives = await _buscarAditivos(contract.id!);
    final validities = await getAllValidityOfContract(uidContract: contract.id!);

    final ordemInicio = validities.firstWhere(
          (v) => (v.ordertype?.toUpperCase() ?? '').contains('INÍCIO'),
      orElse: () => ValidityData(orderdate: null),
    ).orderdate;

    if (ordemInicio == null) return null;

    final diasParalisados = calcularDiasParalisados(validities);
    final diasExecucaoInicial = contract.initialValidityExecutionDays ?? 0;
    final diasExecucaoAditivos = additives.fold<int>(
      0, (soma, a) => soma + (a.additiveValidityExecutionDays ?? 0),
    );

    final totalDiasExecucao = diasExecucaoInicial + diasExecucaoAditivos + diasParalisados;

    return ordemInicio.add(Duration(days: totalDiasExecucao));
  }

  int calcularDiasParalisados(List<ValidityData> validities) {
    int diasParalisados = 0;
    for (int i = 0; i < validities.length; i++) {
      final atual = validities[i];
      if ((atual.ordertype?.toUpperCase() ?? '').contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        if ((anterior.ordertype?.toUpperCase() ?? '').contains('PARALISA') &&
            atual.orderdate != null &&
            anterior.orderdate != null) {
          diasParalisados += atual.orderdate!.difference(anterior.orderdate!).inDays;
        }
      }
    }
    return diasParalisados;
  }

  Future<List<AdditiveData>> _buscarAditivos(String contractId) async {
    final snap = await FirebaseFirestore.instance
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();

    return snap.docs
        .map((doc) => AdditiveData.fromDocument(snapshot: doc))
        .toList();
  }



}
