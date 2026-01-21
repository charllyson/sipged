import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/modules/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

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
        .collection('operation')
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
      payment.idPaymentReport = doc.id; // garante ID
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
    _db.collection('operation').doc(contractId).collection('reportPayments');

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
        .collection('operation')
        .doc(uidContract)
        .collection('reportPayments')
        .doc(uidPayment)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore) — legado
  // ---------------------------------------------------------------------------

  Future<void> salvarUrlPdfDePayment({
    required String contractId,
    required String paymentId,
    required String url,
  }) async {
    try {
      await _db
          .collection('operation')
          .doc(contractId)
          .collection('reportPayments')
          .doc(paymentId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
    }
  }

  // ---------------------------------------------------------------------------
  // 🆕 Lista de anexos (multi-arquivo) no Firestore
  // ---------------------------------------------------------------------------

  Future<void> setAttachments({
    required String contractId,
    required String paymentId,
    required List<Attachment> attachments,
  }) async {
    try {
      await _db
          .collection('operation')
          .doc(contractId)
          .collection('reportPayments')
          .doc(paymentId)
          .set({
        'attachments': attachments.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
