// lib/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';

/// Storage-only para PDFs de **Relatórios de Pagamento**.
class PaymentsReportStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentsReportStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, PaymentsReportData p) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (p.orderPaymentReport ?? '0').toString();
    final proc     = _sanitize(p.processPaymentReport ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, PaymentsReportData p) =>
      'process/${c.id}/reportPayments/${p.idPaymentReport}/${fileName(c, p)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, PaymentsReportData p) async {
    try {
      await _storage.ref(pathFor(c, p)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, PaymentsReportData p) async {
    try {
      return await _storage.ref(pathFor(c, p)).getDownloadURL();
    } catch (e) {
      debugPrint('PaymentsReportStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna URL https.
  Future<String> uploadWithPicker({
    required ContractData contract,
    required PaymentsReportData payment,
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
    required PaymentsReportData payment,
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

  Future<bool> delete(ContractData c, PaymentsReportData p) async {
    try {
      await _storage.ref(pathFor(c, p)).delete();
      return true;
    } catch (e) {
      debugPrint('PaymentsReportStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Métodos de COMPATIBILIDADE (mantêm sua UI funcionando) ----------

  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsReportData payment,
  }) => exists(contract, payment);

  Future<String?> getPdfUrlDaPayment({
    required ContractData contract,
    required PaymentsReportData payment,
  }) => getUrl(contract, payment);

  /// Faz o upload e, opcionalmente, chama um callback com a URL para persistir no Firestore.
  Future<void> sendPdf({
    required ContractData? contract,
    required PaymentsReportData? paymentReport,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
  }) async {
    final c = contract;
    final p = paymentReport;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF de pagamento.');
    if (p == null) throw Exception('Pagamento nulo ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (p.idPaymentReport == null) {
      throw Exception('PaymentsReportData sem idPaymentReport.');
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

  /// Exclusão simples no Storage; metadado do Firestore deve ser limpo no Bloc de dados.
  Future<bool> deletePdf({
    required ContractData contract,
    required PaymentsReportData payment,
  }) => delete(contract, payment);

}
