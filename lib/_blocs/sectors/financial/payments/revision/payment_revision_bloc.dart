// lib/_blocs/sectors/financial/payments/revisions/payment_revision_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

/// Firestore-only para **Revisões de Pagamento**.
/// (Upload/Storage ficou no PaymentRevisionStorageBloc.)
class PaymentRevisionBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PaymentRevisionBloc();

  // ---------------------------------------------------------------------------
  // Listagens / consultas
  // ---------------------------------------------------------------------------

  Future<List<PaymentsRevisionsData>> getAllReportPaymentsOfContract({
    required String contractId,
  }) async {
    final snapshot = await _db
        .collection('documents')
        .doc(contractId)
        .collection('revisionPayments')
        .orderBy('orderPaymentRevision')
        .get();

    return snapshot.docs
        .map((doc) => PaymentsRevisionsData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<List<PaymentsRevisionsData>> fetchAllPaymentsRevisions() async {
    final query = await _db.collectionGroup('revisionPayments').get();
    return query.docs.map((doc) {
      final rev = PaymentsRevisionsData.fromJson(doc.data());
      final segs = doc.reference.path.split('/');
      if (segs.length >= 3) {
        rev.contractId = segs[segs.length - 3];
      }
      return rev;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdatePayment(PaymentsRevisionsData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final col = _db
        .collection('documents')
        .doc(contractId)
        .collection('revisionPayments');

    final docRef = (data.idRevisionPayment != null &&
        data.idRevisionPayment!.trim().isNotEmpty)
        ? col.doc(data.idRevisionPayment)
        : col.doc();

    data.idRevisionPayment ??= docRef.id;

    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'idRevisionPayment': data.idRevisionPayment,
      });

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    if (data.datePaymentRevision != null) {
      json['datePaymentRevision'] = Timestamp.fromDate(data.datePaymentRevision!);
    }

    json['taxPaymentRevision'] ??= 0.0;
    json['orderPaymentRevision'] ??= 0;

    await docRef.set(json, SetOptions(merge: true));
  }

  Future<void> deletarPayment(String uidContract, String uidPayment) async {
    await _db
        .collection('documents')
        .doc(uidContract)
        .collection('revisionPayments')
        .doc(uidPayment)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore)
  //  → upload/exists/getUrl/delete ficam no PaymentRevisionStorageBloc
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
          .collection('revisionPayments')
          .doc(paymentId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF da revisão: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
