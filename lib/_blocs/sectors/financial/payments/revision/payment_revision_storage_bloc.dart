// lib/_blocs/sectors/financial/payments/revisions/payment_revision_storage_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

/// Storage-only para PDFs de **Revisões de Pagamento**.
class PaymentRevisionStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentRevisionStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, PaymentsRevisionsData p) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (p.orderPaymentRevision ?? '0').toString();
    final proc     = _sanitize(p.processPaymentRevision ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, PaymentsRevisionsData p) =>
      'documents/${c.id}/revisionPayments/${p.idRevisionPayment}/${fileName(c, p)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, PaymentsRevisionsData p) async {
    try {
      await _storage.ref(pathFor(c, p)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, PaymentsRevisionsData p) async {
    try {
      return await _storage.ref(pathFor(c, p)).getDownloadURL();
    } catch (e) {
      debugPrint('PaymentRevisionStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna a URL https.
  Future<String> uploadWithPicker({
    required ContractData contract,
    required PaymentsRevisionsData payment,
    required void Function(double progress) onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
    }
    return uploadBytes(
      contract: contract,
      payment: payment,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  /// Upload a partir de bytes; retorna URL https.
  Future<String> uploadBytes({
    required ContractData contract,
    required PaymentsRevisionsData payment,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract, payment));
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }
    await task;
    return await ref.getDownloadURL();
  }

  Future<bool> delete(ContractData c, PaymentsRevisionsData p) async {
    try {
      await _storage.ref(pathFor(c, p)).delete();
      return true;
    } catch (e) {
      debugPrint('PaymentRevisionStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Compat (mantém API antiga da UI) ----------
  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) => exists(contract, paymentsRevisionsData);

  Future<String?> getPdfUrlDaPayment({
    required ContractData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) => getUrl(contract, paymentsRevisionsData);

  Future<void> sendPdf({
    required ContractData? contract,
    required PaymentsRevisionsData? payment,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
  }) async {
    final c = contract;
    final p = payment;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF de revisão.');
    if (p == null) throw Exception('Revisão nula ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (p.idRevisionPayment == null) {
      throw Exception('PaymentsRevisionsData sem idRevisionPayment.');
    }

    final url = await uploadWithPicker(
      contract: c,
      payment: p,
      onProgress: onProgress,
    );
    if (onUploaded != null) {
      await onUploaded(url);
    }
  }

}
