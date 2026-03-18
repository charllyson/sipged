import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

/// Storage-only para PDFs e anexos de Ajustes de Pagamento.
class PaymentAdjustmentStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentAdjustmentStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  /// 🆕 Usa SOMENTE PublicacaoExtratoData.numeroContrato
  String fileName(
      ProcessData c,
      PaymentsAdjustmentsData p, {
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(extrato?.numeroContrato?.trim().isNotEmpty == true
        ? extrato!.numeroContrato!
        : 'contrato');
    final ordem = (p.orderPaymentAdjustment ?? '0').toString();
    final proc = _sanitize(p.processPaymentAdjustment ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  // legacy helpers (mantidos)
  String pathFor(
      ProcessData c,
      PaymentsAdjustmentsData p, {
        PublicacaoExtratoData? extrato,
      }) =>
      'operation/${c.id}/adjustmentPayments/${p.idPaymentAdjustment}/${fileName(c, p, extrato: extrato)}';

  // nova pasta padrão para anexos
  String folderFor(ProcessData c, PaymentsAdjustmentsData p) =>
      'contracts/${c.id}/adjustmentPayments/${p.idPaymentAdjustment}';

  String fullPath(ProcessData c, PaymentsAdjustmentsData p, String file) =>
      '${folderFor(c, p)}/$file';

  // ---------- Operações principais ----------
  Future<bool> exists(
      ProcessData c,
      PaymentsAdjustmentsData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      await _storage.ref(pathFor(c, p, extrato: extrato)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(
      ProcessData c,
      PaymentsAdjustmentsData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      return await _storage.ref(pathFor(c, p, extrato: extrato)).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna a URL https.
  Future<String> uploadWithPicker({
    required ProcessData contract,
    required PaymentsAdjustmentsData payment,
    required void Function(double progress) onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
    }
    return uploadBytes(
      contract: contract,
      payment: payment,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
      extrato: extrato,
    );
  }

  /// Upload a partir de bytes; retorna URL https. (legado)
  Future<String> uploadBytes({
    required ProcessData contract,
    required PaymentsAdjustmentsData payment,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final ref = _storage.ref(pathFor(contract, payment, extrato: extrato));
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

  Future<bool> delete(
      ProcessData c,
      PaymentsAdjustmentsData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      await _storage.ref(pathFor(c, p, extrato: extrato)).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------- NOVOS utilitários (multi-anexos) ----------

  /// Abre o picker e retorna (bytes, nomeOriginal)
  Future<(Uint8List, String)> pickFileBytes() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null || res.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (res.files.single.bytes!, res.files.single.name);
  }

  /// Upload de anexo a partir de bytes, gerando um Attachment completo.
  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required PaymentsAdjustmentsData payment,
    required Uint8List bytes,
    required String originalName,
    required String label,
    PublicacaoExtratoData? extrato,
  }) async {
    final safeName = '${fileName(contract, payment, extrato: extrato)
        .replaceFirst('.pdf', '')}-${_sanitize(originalName)}';
    final ref = _storage.ref(fullPath(contract, payment, safeName));
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/octet-stream'),
    );
    await task;
    final url = await ref.getDownloadURL();

    return Attachment(
      id: safeName,
      label: label,
      url: url,
      path: ref.fullPath,
      ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
          .firstMatch(safeName)
          ?.group(0) ??
          '',
      createdAt: DateTime.now(),
    );
  }

  /// Lista todos os arquivos já existentes na pasta do pagamento (novo esquema).
  Future<List<StorageFile>> listarArquivosDoPagamento({
    required String contractId,
    required String paymentAdjustmentId,
  }) async {
    final dir = 'contracts/$contractId/adjustmentPayments/$paymentAdjustmentId';
    try {
      final res = await _storage.ref(dir).listAll();
      final out = <StorageFile>[];
      for (final item in res.items) {
        final url = await item.getDownloadURL();
        out.add(StorageFile(name: item.name, url: url));
      }
      return out;
    } catch (e) {
      return const <StorageFile>[];
    }
  }

  /// Deleta um arquivo pelo caminho completo (path salvo no Attachment).
  Future<void> deleteStorageByPath(String fullPath) async {
    await _storage.ref(fullPath).delete();
  }

  // ---------- Compat (mantém API antiga da UI) ----------
  Future<bool> verificarSePdfDePaymentExiste({
    required ProcessData contract,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
    PublicacaoExtratoData? extrato,
  }) =>
      exists(contract, paymentsAdjustmentsData, extrato: extrato);

  Future<String?> getPdfUrlDaPayment({
    required ProcessData contract,
    required PaymentsAdjustmentsData paymentsAdjustmentsData,
    PublicacaoExtratoData? extrato,
  }) =>
      getUrl(contract, paymentsAdjustmentsData, extrato: extrato);

  Future<void> sendPdf({
    required ProcessData? contract,
    required PaymentsAdjustmentsData? paymentsAdjustment,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
    PublicacaoExtratoData? extrato,
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
      extrato: extrato,
    );
    if (onUploaded != null) {
      await onUploaded(url);
    }
  }

}

class StorageFile {
  final String name;
  final String url;
  const StorageFile({required this.name, required this.url});
}
