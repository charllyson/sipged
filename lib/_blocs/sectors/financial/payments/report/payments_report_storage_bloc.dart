import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

/// Storage-only para arquivos de **Relatórios de Pagamento**.
class PaymentsReportStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentsReportStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  /// 🆕 Usa SOMENTE PublicacaoExtratoData.numeroContrato
  String fileName(
      ProcessData c,
      PaymentsReportData p, {
        String? originalName,
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(extrato?.numeroContrato?.trim().isNotEmpty == true
        ? extrato!.numeroContrato!
        : 'contrato');
    final ordem = (p.orderPaymentReport ?? '0').toString();
    final proc = _sanitize(p.processPaymentReport ?? 'processo');

    if (originalName != null && originalName.trim().isNotEmpty) {
      return '$contrato-$ordem-$proc-${_sanitize(originalName)}';
    }
    return '$contrato-$ordem-$proc.pdf';
  }

  String folderFor(ProcessData c, PaymentsReportData p) =>
      'contracts/${c.id}/payments/${p.idPaymentReport}';

  String pathFor(
      ProcessData c,
      PaymentsReportData p, {
        required String file,
      }) =>
      '${folderFor(c, p)}/$file';

  // ---------- Métodos utilitários usados pelo controller novo ----------

  /// Abre o seletor e retorna (bytes, nomeOriginal)
  Future<(Uint8List, String)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    final f = result.files.single;
    return (f.bytes!, f.name);
  }

  /// Faz upload de um anexo (a partir de bytes) e retorna um Attachment completo.
  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required PaymentsReportData payment,
    required Uint8List bytes,
    required String originalName,
    required String label,
    PublicacaoExtratoData? extrato,
  }) async {
    final name =
    fileName(contract, payment, originalName: originalName, extrato: extrato);
    final ref = _storage.ref(pathFor(contract, payment, file: name));

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/octet-stream'),
    );

    await task;
    final url = await ref.getDownloadURL();

    return Attachment(
      id: name,
      label: label,
      url: url,
      path: ref.fullPath,
      ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
          .firstMatch(name)
          ?.group(0) ??
          '',
      createdAt: DateTime.now(),
    );
  }

  /// Lista todos os arquivos já existentes no Storage para este pagamento.
  Future<List<_StorageFile>> listarArquivosDoPagamento({
    required String contractId,
    required String paymentId,
  }) async {
    final dir = 'contracts/$contractId/payments/$paymentId';
    final ref = _storage.ref(dir);
    try {
      final res = await ref.listAll();
      final out = <_StorageFile>[];
      for (final item in res.items) {
        final url = await item.getDownloadURL();
        out.add(_StorageFile(name: item.name, url: url));
      }
      return out;
    } catch (e) {
      return const <_StorageFile>[];
    }
  }

  /// Exclui um arquivo diretamente pelo caminho completo do Storage.
  Future<void> deleteStorageByPath(String fullPath) async {
    try {
      await _storage.ref(fullPath).delete();
    } catch (e) {}
  }

  // ---------- Métodos antigos (compatibilidade) ----------

  Future<bool> exists(
      ProcessData c,
      PaymentsReportData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      final name = fileName(c, p, extrato: extrato);
      await _storage.ref(pathFor(c, p, file: name)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(
      ProcessData c,
      PaymentsReportData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      final name = fileName(c, p, extrato: extrato);
      return await _storage.ref(pathFor(c, p, file: name)).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ProcessData contract,
    required PaymentsReportData payment,
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

  Future<String> uploadBytes({
    required ProcessData contract,
    required PaymentsReportData payment,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final name = fileName(contract, payment, extrato: extrato);
    final ref = _storage.ref(pathFor(contract, payment, file: name));
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
      PaymentsReportData p, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      final name = fileName(c, p, extrato: extrato);
      await _storage.ref(pathFor(c, p, file: name)).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verificarSePdfDePaymentExiste({
    required ProcessData contract,
    required PaymentsReportData payment,
    PublicacaoExtratoData? extrato,
  }) =>
      exists(contract, payment, extrato: extrato);

  Future<String?> getPdfUrlDaPayment({
    required ProcessData contract,
    required PaymentsReportData payment,
    PublicacaoExtratoData? extrato,
  }) =>
      getUrl(contract, payment, extrato: extrato);

  Future<void> sendPdf({
    required ProcessData? contract,
    required PaymentsReportData? paymentReport,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
    PublicacaoExtratoData? extrato,
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
      extrato: extrato,
    );
    if (onUploaded != null) {
      await onUploaded(url);
    }
  }
}

class _StorageFile {
  final String name;
  final String url;
  const _StorageFile({required this.name, required this.url});
}
