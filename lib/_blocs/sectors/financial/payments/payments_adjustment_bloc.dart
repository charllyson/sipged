import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/sectors/financial/payments/payments_adjustments_data.dart';
import '../../../system/user_bloc.dart';

class PaymentsAdjustmentBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  PaymentsAdjustmentBloc();


  Future<List<PaymentsAdjustmentsData>> getAllAdjustmentPaymentsOfContract({required String contractId}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('documents')
        .doc(contractId)
        .collection('adjustmentPayments')
        .orderBy('orderPaymentAdjustment')
        .get();

    return snapshot.docs
        .map((doc) => PaymentsAdjustmentsData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.orderPaymentAdjustment}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName',
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
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.orderPaymentAdjustment}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName',
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
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
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

        final fileName = '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.orderPaymentAdjustment}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'documents/$contractId/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName',
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
            .collection('adjustmentPayments')
            .doc(paymentsAdjustmentsData.idPaymentAdjustment)
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
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .get();
      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

      final fileName = '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.orderPaymentAdjustment}.pdf';
      final path = 'documents/$contractId/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('adjustmentPayments')
          .doc(paymentsAdjustmentsData.idPaymentAdjustment)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar PDF de pagamento: $e');
      return false;
    }
  }

  Future<List<PaymentsAdjustmentsData>> fetchAllMeasurements() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collectionGroup('adjustmentPayments').get();
    return querySnapshot.docs.map((doc) {
      final payment = PaymentsAdjustmentsData.fromJson(doc.data());
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 2) {
        payment.contractId = pathSegments[pathSegments.length - 3];
      }
      return payment;
    }).toList();
  }

  Future<void> saveOrUpdatePayment(PaymentsAdjustmentsData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final ref = _db.collection('documents').doc(contractId).collection('adjustmentPayments');

    final docRef = (data.idPaymentAdjustment != null && data.idPaymentAdjustment!.trim().isNotEmpty)
        ? ref.doc(data.idPaymentAdjustment)
        : ref.doc();

    data.idPaymentAdjustment ??= docRef.id;

    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'idPaymentAdjustment': data.idPaymentAdjustment,
      });

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    if (data.datePaymentAdjustment != null) {
      json['datePaymentAdjustment'] = Timestamp.fromDate(data.datePaymentAdjustment!);
    }

    json['taxPaymentAdjustment'] ??= 0.0;
    json['orderPaymentAdjustment'] ??= 0;

    await docRef.set(json, SetOptions(merge: true));
  }



  Future<void> deletarPayment(String uidContract, String uidPayment) async {
    final ref = _db
        .collection('documents')
        .doc(uidContract)
        .collection('adjustmentPayments')
        .doc(uidPayment);
    await ref.delete();
  }


  String getNomePadronizadoPdfDaMedicao({
    required String contractNumber,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) {
    return '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.processPaymentAdjustment}.pdf';
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
          .collection('adjustmentPayments')
          .doc(paymentId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',

      });
    } catch (e) {
    }
  }


  Future<void> selecionarEPdfDeMedicaoComProgresso({
    required String contractId,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
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
            '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.processPaymentAdjustment}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'documents/$contractId/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName',
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
            .collection('adjustmentPayments')
            .doc(paymentsAdjustmentsData.idPaymentAdjustment)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeMedicaoExiste({
    required ContractData contract,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.processPaymentAdjustment}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName',
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
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.processPaymentAdjustment}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/reportPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<bool> deletarPdfDaMedicao({
    required String contractId,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName =
          '$contractNumber-${paymentsAdjustmentsData.orderPaymentAdjustment}-${paymentsAdjustmentsData.processPaymentAdjustment}.pdf';
      final path = 'documents/$contractId/adjustmentPayments/${paymentsAdjustmentsData.idPaymentAdjustment}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('adjustmentPayments')
          .doc(paymentsAdjustmentsData.idPaymentAdjustment)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      return false;
    }
  }
}
