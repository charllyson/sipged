import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/payments_revisions_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

/// Storage-only para PDFs e anexos de **Revisões de Pagamento**.
class PaymentRevisionStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentRevisionStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  /// 🆕 Usa SOMENTE PublicacaoExtratoData.numeroContrato para montar o nome
  String fileName(
      ProcessData c,
      PaymentsRevisionsData p, {
        String? originalName,
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(extrato?.numeroContrato?.trim().isNotEmpty == true
        ? extrato!.numeroContrato!
        : 'contrato');
    final ordem = (p.orderPaymentRevision ?? '0').toString();
    final proc = _sanitize(p.processPaymentRevision ?? 'processo');

    if (originalName != null && originalName.trim().isNotEmpty) {
      return '$contrato-$ordem-$proc-${_sanitize(originalName)}';
    }
    return '$contrato-$ordem-$proc.pdf';
  }

  // Legado: caminho único para PDF
  String pathFor(
      ProcessData c,
      PaymentsRevisionsData p, {
        PublicacaoExtratoData? extrato,
      }) =>
      'operation/${c.id}/revisionPayments/${p.idRevisionPayment}/${fileName(c, p, extrato: extrato)}';

  // Nova pasta padrão para múltiplos anexos
  String folderFor(ProcessData c, PaymentsRevisionsData p) =>
      'contracts/${c.id}/revisionPayments/${p.idRevisionPayment}';

  String fullPath(ProcessData c, PaymentsRevisionsData p, String file) =>
      '${folderFor(c, p)}/$file';

  // ---------- Operações principais (legado) ----------
  Future<bool> exists(
      ProcessData c,
      PaymentsRevisionsData p, {
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
      PaymentsRevisionsData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      return await _storage.ref(pathFor(c, p, extrato: extrato)).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna a URL https. (legado)
  Future<String> uploadWithPicker({
    required ProcessData contract,
    required PaymentsRevisionsData payment,
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
    required PaymentsRevisionsData payment,
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
      PaymentsRevisionsData p, {
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
    required PaymentsRevisionsData payment,
    required Uint8List bytes,
    required String originalName,
    required String label,
    PublicacaoExtratoData? extrato,
  }) async {
    final safeName =
    fileName(contract, payment, originalName: originalName, extrato: extrato);
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

  /// Lista todos os arquivos já existentes na pasta da revisão (novo esquema).
  Future<List<StorageFile>> listarArquivosDaRevisao({
    required String contractId,
    required String revisionPaymentId,
  }) async {
    final dir = 'contracts/$contractId/revisionPayments/$revisionPaymentId';
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

  // ---------- Compat (UI antiga) ----------
  Future<bool> verificarSePdfDePaymentExiste({
    required ProcessData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
    PublicacaoExtratoData? extrato,
  }) =>
      exists(contract, paymentsRevisionsData, extrato: extrato);

  Future<String?> getPdfUrlDaPayment({
    required ProcessData contract,
    required PaymentsRevisionsData paymentsRevisionsData,
    PublicacaoExtratoData? extrato,
  }) =>
      getUrl(contract, paymentsRevisionsData, extrato: extrato);

  Future<void> sendPdf({
    required ProcessData? contract,
    required PaymentsRevisionsData? payment,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
    PublicacaoExtratoData? extrato,
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
