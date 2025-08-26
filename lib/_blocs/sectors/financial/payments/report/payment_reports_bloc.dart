// lib/_blocs/sectors/financial/payments/report/payments_report_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';

/// Firestore-only para Relatórios de Pagamento.
/// (Upload/Storage ficou no PaymentsReportStorageBloc.)
class PaymentReportBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PaymentReportBloc();

  // ---------------------------------------------------------------------------
  // Listagens / consultas
  // ---------------------------------------------------------------------------

  Future<List<PaymentsReportData>> getAllReportPaymentsOfContract({
    required String contractId,
  }) async {
    final snapshot = await _db
        .collection('documents')
        .doc(contractId)
        .collection('reportPayments')
        .orderBy('orderPaymentReport')
        .get();

    return snapshot.docs
        .map((doc) => PaymentsReportData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<List<PaymentsReportData>> fetchAllPaymentsReports() async {
    final query = await _db.collectionGroup('reportPayments').get();
    return query.docs.map((doc) {
      final payment = PaymentsReportData.fromJson(doc.data());
      final segs = doc.reference.path.split('/');
      if (segs.length >= 3) {
        payment.contractId = segs[segs.length - 3];
      }
      return payment;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdatePayment(PaymentsReportData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final colRef =
    _db.collection('documents').doc(contractId).collection('reportPayments');

    final docRef = (data.idPaymentReport != null &&
        data.idPaymentReport!.trim().isNotEmpty)
        ? colRef.doc(data.idPaymentReport)
        : colRef.doc();

    data.idPaymentReport ??= docRef.id;

    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
  }

  Future<void> deletarPayment(String uidContract, String uidPayment) async {
    await _db
        .collection('documents')
        .doc(uidContract)
        .collection('reportPayments')
        .doc(uidPayment)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore)
  //  → upload/exists/getUrl/delete ficam no PaymentsReportStorageBloc
  // ---------------------------------------------------------------------------

  Future<void> salvarUrlPdfDePayment({
    required String contractId,
    required String paymentId,
    required String url,
  }) async {
    try {
      await _db
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
      debugPrint('Erro ao salvar URL do PDF do relatório de pagamento: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
