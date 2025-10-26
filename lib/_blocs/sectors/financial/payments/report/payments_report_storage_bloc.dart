import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Storage-only para arquivos de **Relatórios de Pagamento**.
class PaymentsReportStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  PaymentsReportStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, PaymentsReportData p, {String? originalName}) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (p.orderPaymentReport ?? '0').toString();
    final proc     = _sanitize(p.processPaymentReport ?? 'processo');
    if (originalName != null && originalName.trim().isNotEmpty) {
      return '$contrato-$ordem-$proc-${_sanitize(originalName)}';
    }
    return '$contrato-$ordem-$proc.pdf';
  }

  String folderFor(ContractData c, PaymentsReportData p) =>
      'contracts/${c.id}/payments/${p.idPaymentReport}';

  String pathFor(ContractData c, PaymentsReportData p, String file) =>
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
    required ContractData contract,
    required PaymentsReportData payment,
    required Uint8List bytes,
    required String originalName,
    required String label,
  }) async {
    final name = fileName(contract, payment, originalName: originalName);
    final ref = _storage.ref(pathFor(contract, payment, name));

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
      debugPrint('listarArquivosDoPagamento erro: $e');
      return const <_StorageFile>[];
    }
  }

  /// Exclui um arquivo diretamente pelo caminho completo do Storage.
  Future<void> deleteStorageByPath(String fullPath) async {
    try {
      await _storage.ref(fullPath).delete();
    } catch (e) {
      debugPrint('deleteStorageByPath erro: $e');
    }
  }

  // ---------- Métodos antigos (compatibilidade) ----------

  Future<bool> exists(ContractData c, PaymentsReportData p) async {
    try {
      // verifica apenas o primeiro arquivo padrão .pdf
      await _storage.ref(pathFor(c, p, fileName(c, p))).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, PaymentsReportData p) async {
    try {
      return await _storage.ref(pathFor(c, p, fileName(c, p))).getDownloadURL();
    } catch (e) {
      debugPrint('PaymentsReportStorageBloc.getUrl erro: $e');
      return null;
    }
  }

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

  Future<String> uploadBytes({
    required ContractData contract,
    required PaymentsReportData payment,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract, payment, fileName(contract, payment)));
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
      await _storage.ref(pathFor(c, p, fileName(c, p))).delete();
      return true;
    } catch (e) {
      debugPrint('PaymentsReportStorageBloc.delete erro: $e');
      return false;
    }
  }

  Future<bool> verificarSePdfDePaymentExiste({
    required ContractData contract,
    required PaymentsReportData payment,
  }) => exists(contract, payment);

  Future<String?> getPdfUrlDaPayment({
    required ContractData contract,
    required PaymentsReportData payment,
  }) => getUrl(contract, payment);

  Future<void> sendPdf({
    required ContractData? contract,
    required PaymentsReportData? paymentReport,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
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
}

class _StorageFile {
  final String name;
  final String url;
  const _StorageFile({required this.name, required this.url});
}
