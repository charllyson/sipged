// lib/_blocs/sectors/financial/payments/adjustments/payment_adjustment_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';

/// Firestore-only para Ajustes de Pagamento.
/// (Upload/Storage ficou no PaymentsAdjustmentStorageBloc.)
class PaymentAdjustmentBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PaymentAdjustmentBloc();

  // ---------------------------------------------------------------------------
  // Listagens / consultas
  // ---------------------------------------------------------------------------

  Future<List<PaymentsAdjustmentsData>> getAllAdjustmentPaymentsOfContract({
    required String contractId,
  }) async {
    final snapshot = await _db
        .collection('process')
        .doc(contractId)
        .collection('adjustmentPayments')
        .orderBy('orderPaymentAdjustment')
        .get();

    return snapshot.docs
        .map((doc) => PaymentsAdjustmentsData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<List<PaymentsAdjustmentsData>> fetchAllMeasurements() async {
    final querySnapshot = await _db.collectionGroup('adjustmentPayments').get();
    return querySnapshot.docs.map((doc) {
      final payment = PaymentsAdjustmentsData.fromJson(doc.data());
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

  Future<void> saveOrUpdatePayment(PaymentsAdjustmentsData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final contractId = data.contractId!;
    final ref = _db
        .collection('process')
        .doc(contractId)
        .collection('adjustmentPayments');

    final docRef = (data.idPaymentAdjustment != null &&
        data.idPaymentAdjustment!.trim().isNotEmpty)
        ? ref.doc(data.idPaymentAdjustment)
        : ref.doc();

    data.idPaymentAdjustment ??= docRef.id;

    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;

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
      json['datePaymentAdjustment'] =
          Timestamp.fromDate(data.datePaymentAdjustment!);
    }

    json['taxPaymentAdjustment'] ??= 0.0;
    json['orderPaymentAdjustment'] ??= 0;

    await docRef.set(json, SetOptions(merge: true));
  }

  Future<void> deletarPayment(String uidContract, String uidPayment) async {
    final ref = _db
        .collection('process')
        .doc(uidContract)
        .collection('adjustmentPayments')
        .doc(uidPayment);
    await ref.delete();
  }

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore)
  //  → upload/exists/getUrl/delete ficam no PaymentsAdjustmentStorageBloc
  // ---------------------------------------------------------------------------

  Future<void> salvarUrlPdfDePayment({
    required String contractId,
    required String paymentId,
    required String url,
  }) async {
    try {
      await _db
          .collection('process')
          .doc(contractId)
          .collection('adjustmentPayments')
          .doc(paymentId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF do ajuste: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
