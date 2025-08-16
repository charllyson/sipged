import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/sectors/financial/payments/payments_revisions_data.dart';
import '../../../system/user_bloc.dart';

class PaymentsRevisionBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  PaymentsRevisionBloc();


  Future<List<PaymentsRevisionsData>> getAllReportPaymentsOfContract({required String contractId}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('documents')
        .doc(contractId)
        .collection('revisionPayments')
        .orderBy('orderPaymentRevision')
        .get();

    return snapshot.docs
        .map((doc) => PaymentsRevisionsData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.orderPaymentRevision}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaPayment({
    required ContractData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.orderPaymentRevision}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao obter URL do PDF da validade: $e');
      return null;
    }
  }

  Future<void> selecionarEPdfDePaymentComProgresso({
    required String contractId,
    required PaymentsRevisionsData paymentsRevisionsData,
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
            .collection('documents')
            .doc(contractId)
            .get();
        final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

        final fileName = '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.orderPaymentRevision}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'documents/$contractId/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName',
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
            .collection('documents')
            .doc(contractId)
            .collection('revisionPayments')
            .doc(paymentsRevisionsData.idRevisionPayment)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      debugPrint('Erro ao enviar PDF da pagamento: $e');
      onComplete(false);
    }
  }

  Future<bool> deletarPdfDePayment({
    required String contractId,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .get();
      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

      final fileName = '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.orderPaymentRevision}.pdf';
      final path = 'documents/$contractId/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('revisionPayments')
          .doc(paymentsRevisionsData.idRevisionPayment)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar PDF de pagamento: $e');
      return false;
    }
  }

  Future<List<PaymentsRevisionsData>> fetchAllPaymentsRevisions() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collectionGroup('revisionPayments').get();
    return querySnapshot.docs.map((doc) {
      final paymentsRevisionsData = PaymentsRevisionsData.fromJson(doc.data());
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 2) {
        paymentsRevisionsData.contractId = pathSegments[pathSegments.length - 3];
      }
      return paymentsRevisionsData;
    }).toList();
  }

  Future<void> saveOrUpdatePayment(PaymentsRevisionsData paymentsRevisionsData) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = paymentsRevisionsData.contractId!;
    final ref = _db.collection('documents').doc(contractId).collection('revisionPayments');

    final docRef = (paymentsRevisionsData.idRevisionPayment != null &&
        paymentsRevisionsData.idRevisionPayment!.trim().isNotEmpty)
        ? ref.doc(paymentsRevisionsData.idRevisionPayment)
        : ref.doc();

    paymentsRevisionsData.idRevisionPayment ??= docRef.id;

    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;

    final json = paymentsRevisionsData.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'idRevisionPayment': paymentsRevisionsData.idRevisionPayment,
      });

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    if (paymentsRevisionsData.datePaymentRevision != null) {
      json['datePaymentRevision'] =
          Timestamp.fromDate(paymentsRevisionsData.datePaymentRevision!);
    }

    json['taxPaymentRevision'] ??= 0.0;
    json['orderPaymentRevision'] ??= 0;

    await docRef.set(json, SetOptions(merge: true));
  }



  Future<void> deletarPayment(String uidContract, String uidPayment) async {
    final ref = _db
        .collection('documents')
        .doc(uidContract)
        .collection('revisionPayments')
        .doc(uidPayment);
    await ref.delete();
  }


  String getNomePadronizadoPdfDaMedicao({
    required String contractNumber,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) {
    return '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.processPaymentRevision}.pdf';
  }


  Future<void> salvarUrlPdfDePayment({
    required String contractId,
    required String paymentId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('revisionPayments')
          .doc(paymentId)
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
    required PaymentsRevisionsData paymentsRevisionsData,
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
            .collection('documents')
            .doc(contractId)
            .get();
        final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

        final fileName =
            '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.processPaymentRevision}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'documents/$contractId/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName',
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
            .collection('documents')
            .doc(contractId)
            .collection('revisionPayments')
            .doc(paymentsRevisionsData.idRevisionPayment)
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
    required PaymentsRevisionsData paymentsRevisionsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.processPaymentRevision}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName',
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
    required PaymentsRevisionsData paymentsRevisionsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.processPaymentRevision}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName',
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
    required PaymentsRevisionsData paymentsRevisionsData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName =
          '$contractNumber-${paymentsRevisionsData.orderPaymentRevision}-${paymentsRevisionsData.processPaymentRevision}.pdf';
      final path = 'documents/$contractId/revisionPayments/${paymentsRevisionsData.idRevisionPayment}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('revisionPayments')
          .doc(paymentsRevisionsData.idRevisionPayment)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF da medição: $e');
      return false;
    }
  }
}
