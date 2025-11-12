import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Storage-only para PDFs e anexos de **Revisões de Pagamento**.
class PaymentRevisionStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentRevisionStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ProcessData c, PaymentsRevisionsData p, {String? originalName}) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (p.orderPaymentRevision ?? '0').toString();
    final proc     = _sanitize(p.processPaymentRevision ?? 'processo');
    if (originalName != null && originalName.trim().isNotEmpty) {
      return '$contrato-$ordem-$proc-${_sanitize(originalName)}';
    }
    return '$contrato-$ordem-$proc.pdf';
  }

  // Legado: caminho único para PDF
  String pathFor(ProcessData c, PaymentsRevisionsData p) =>
      'process/${c.id}/revisionPayments/${p.idRevisionPayment}/${fileName(c, p)}';

  // Nova pasta padrão para múltiplos anexos
  String folderFor(ProcessData c, PaymentsRevisionsData p) =>
      'contracts/${c.id}/revisionPayments/${p.idRevisionPayment}';

  String fullPath(ProcessData c, PaymentsRevisionsData p, String file) =>
      '${folderFor(c, p)}/$file';

  // ---------- Operações principais (legado) ----------
  Future<bool> exists(ProcessData c, PaymentsRevisionsData p) async {
    try {
      await _storage.ref(pathFor(c, p)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ProcessData c, PaymentsRevisionsData p) async {
    try {
      return await _storage.ref(pathFor(c, p)).getDownloadURL();
    } catch (e) {
      debugPrint('PaymentRevisionStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna a URL https. (legado)
  Future<String> uploadWithPicker({
    required ProcessData contract,
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

  /// Upload a partir de bytes; retorna URL https. (legado)
  Future<String> uploadBytes({
    required ProcessData contract,
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

  Future<bool> delete(ProcessData c, PaymentsRevisionsData p) async {
    try {
      await _storage.ref(pathFor(c, p)).delete();
      return true;
    } catch (e) {
      debugPrint('PaymentRevisionStorageBloc.delete erro: $e');
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
    required PaymentsRevisionsData payment,
    required Uint8List bytes,
    required String originalName,
    required String label,
  }) async {
    final safeName = fileName(contract, payment, originalName: originalName);
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
      ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(safeName)?.group(0) ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Lista todos os arquivos já existentes na pasta da revisão (novo esquema).
  Future<List<_StorageFile>> listarArquivosDaRevisao({
    required String contractId,
    required String revisionPaymentId,
  }) async {
    final dir = 'contracts/$contractId/revisionPayments/$revisionPaymentId';
    try {
      final res = await _storage.ref(dir).listAll();
      final out = <_StorageFile>[];
      for (final item in res.items) {
        final url = await item.getDownloadURL();
        out.add(_StorageFile(name: item.name, url: url));
      }
      return out;
    } catch (e) {
      debugPrint('listarArquivosDaRevisao erro: $e');
      return const <_StorageFile>[];
    }
  }

  /// Deleta um arquivo pelo caminho completo (path salvo no Attachment).
  Future<void> deleteStorageByPath(String fullPath) async {
    try {
      await _storage.ref(fullPath).delete();
    } catch (e) {
      debugPrint('deleteStorageByPath erro: $e');
    }
  }

  // ---------- Compat (UI antiga) ----------
  Future<bool> verificarSePdfDePaymentExiste({
    required ProcessData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) => exists(contract, paymentsRevisionsData);

  Future<String?> getPdfUrlDaPayment({
    required ProcessData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
  }) => getUrl(contract, paymentsRevisionsData);

  Future<void> sendPdf({
    required ProcessData? contract,
    required PaymentsRevisionsData? payment,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
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

  @override
  void dispose() {
    super.dispose();
  }
}

class _StorageFile {
  final String name;
  final String url;
  const _StorageFile({required this.name, required this.url});
}
