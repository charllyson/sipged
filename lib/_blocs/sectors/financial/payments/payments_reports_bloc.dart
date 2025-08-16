import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/sectors/financial/payments/payments_reports_data.dart';
import '../../../system/user_bloc.dart';

class PaymentsReportBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  PaymentsReportBloc();


  Future<List<PaymentsReportData>> getAllReportPaymentsOfContract({required String contractId}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('documents')
        .doc(contractId)
        .collection('reportPayments')
        .orderBy('orderPaymentReport')
        .get();

    return snapshot.docs
        .map((doc) => PaymentsReportData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsReportData payment,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${payment.orderPaymentReport}-${payment.orderPaymentReport}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/reportPayments/${payment.idPaymentReport}/$fileName',
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
    required PaymentsReportData payment,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName = '$contractNumber-${payment.orderPaymentReport}-${payment.orderPaymentReport}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/reportPayments/${payment.idPaymentReport}/$fileName',
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
    required PaymentsReportData paymentData,
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

        final fileName = '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.orderPaymentReport}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'documents/$contractId/reportPayments/${paymentData.idPaymentReport}/$fileName',
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
            .collection('reportPayments')
            .doc(paymentData.idPaymentReport)
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
    required PaymentsReportData paymentData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .get();
      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

      final fileName = '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.orderPaymentReport}.pdf';
      final path = 'documents/$contractId/reportPayments/${paymentData.idPaymentReport}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('reportPayments')
          .doc(paymentData.idPaymentReport)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      debugPrint('Erro ao deletar PDF de pagamento: $e');
      return false;
    }
  }

  Future<List<PaymentsReportData>> fetchAllPaymentsReports() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collectionGroup('reportPayments').get();
    return querySnapshot.docs.map((doc) {
      final payment = PaymentsReportData.fromJson(doc.data());
      final pathSegments = doc.reference.path.split('/');
      if (pathSegments.length >= 2) {
        payment.contractId = pathSegments[pathSegments.length - 3];
      }
      return payment;
    }).toList();
  }

  Future<void> saveOrUpdatePayment(PaymentsReportData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final collectionRef = _db.collection('documents').doc(contractId).collection('reportPayments');

    // 🚨 Gera novo ID se for criação
    final docRef = (data.idPaymentReport != null && data.idPaymentReport!.trim().isNotEmpty)
        ? collectionRef.doc(data.idPaymentReport)
        : collectionRef.doc(); // Novo ID automático

    // Se for criação, salva o novo ID no modelo
    if (data.idPaymentReport == null || data.idPaymentReport!.trim().isEmpty) {
      data.idPaymentReport = docRef.id;
    }

    // Monta o JSON com campos padrões
    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    // Define campos de criação apenas se for novo
    final existingDoc = await docRef.get();
    final hasCreatedAt = existingDoc.exists && existingDoc.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
  }




  Future<void> deletarPayment(String uidContract, String uidPayment) async {
    final ref = _db
        .collection('documents')
        .doc(uidContract)
        .collection('reportPayments')
        .doc(uidPayment);
    await ref.delete();
  }


  String getNomePadronizadoPdfDaMedicao({
    required String contractNumber,
    required PaymentsReportData paymentData,
  }) {
    return '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.processPaymentReport}.pdf';
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
          .collection('reportPayments')
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
    required PaymentsReportData paymentData,
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
            '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.processPaymentReport}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'documents/$contractId/reportPayments/${paymentData.idPaymentReport}/$fileName',
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
            .collection('reportPayments')
            .doc(paymentData.idPaymentReport)
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
    required PaymentsReportData paymentData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.processPaymentReport}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/reportPayments/${paymentData.idPaymentReport}/$fileName',
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
    required PaymentsReportData paymentData,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.processPaymentReport}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'documents/${contract.id}/reportPayments/${paymentData.idPaymentReport}/$fileName',
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
    required PaymentsReportData paymentData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName =
          '$contractNumber-${paymentData.orderPaymentReport}-${paymentData.processPaymentReport}.pdf';
      final path = 'documents/$contractId/reportPayments/${paymentData.idPaymentReport}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(contractId)
          .collection('reportPayments')
          .doc(paymentData.idPaymentReport)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF da medição: $e');
      return false;
    }
  }
}
