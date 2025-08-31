// lib/_blocs/sectors/financial/payments/adjustments/payments_adjustment_storage_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';

/// Storage-only para PDFs de Ajustes de Pagamento.
class PaymentAdjustmentStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentAdjustmentStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, PaymentsAdjustmentsData p) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (p.orderPaymentAdjustment ?? '0').toString();
    final proc     = _sanitize(p.processPaymentAdjustment ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, PaymentsAdjustmentsData p) =>
      'documents/${c.id}/adjustmentPayments/${p.idPaymentAdjustment}/${fileName(c, p)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, PaymentsAdjustmentsData p) async {
    try {
      await _storage.ref(pathFor(c, p)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, PaymentsAdjustmentsData p) async {
    try {
      return await _storage.ref(pathFor(c, p)).getDownloadURL();
    } catch (e) {
      debugPrint('PaymentsAdjustmentStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna a URL https.
  Future<String> uploadWithPicker({
    required ContractData contract,
    required PaymentsAdjustmentsData payment,
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
    required PaymentsAdjustmentsData payment,
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

  Future<bool> delete(ContractData c, PaymentsAdjustmentsData p) async {
    try {
      await _storage.ref(pathFor(c, p)).delete();
      return true;
    } catch (e) {
      debugPrint('PaymentsAdjustmentStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Compat (mantém API antiga da UI) ----------
  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) => exists(contract, paymentsAdjustmentsData);

  Future<String?> getPdfUrlDaPayment({
    required ContractData contract,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
  }) => getUrl(contract, paymentsAdjustmentsData);

  Future<void> sendPdf({
    required ContractData? contract,
    required PaymentsAdjustmentsData? paymentsAdjustment,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
  }) async {
    final c = contract;
    final p = paymentsAdjustment;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF de ajuste.');
    if (p == null) throw Exception('Ajuste nulo ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (p.idPaymentAdjustment == null) {
      throw Exception('PaymentsAdjustmentsData sem idPaymentAdjustment.');
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

  @override
  void dispose() {
    super.dispose();
  }
}
