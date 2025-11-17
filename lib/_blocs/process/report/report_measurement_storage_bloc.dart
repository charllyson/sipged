import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

/// Storage de arquivos da **medição (report)**.
class ReportMeasurementStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ReportMeasurementStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  /// 🆕 Usa SOMENTE PublicacaoExtratoData.numeroContrato
  String fileName(
      ProcessData c,
      ReportMeasurementData m, {
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(
      extrato?.numeroContrato?.trim().isNotEmpty == true
          ? extrato!.numeroContrato!
          : 'contrato',
    );
    final ordem = (m.order ?? 0).toString();
    final proc = _sanitize(m.numberprocess ?? 'processo');
    return 'report-$contrato-$ordem-$proc.pdf';
  }

  String pathFor(
      ProcessData c,
      ReportMeasurementData m, {
        PublicacaoExtratoData? extrato,
      }) =>
      'contracts/${c.id}/measurements/${m.id}/${fileName(c, m, extrato: extrato)}';

  // ======= helpers anexos múltiplos =======
  String _extFromName(String name) {
    final m =
    RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(name.trim());
    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String attachmentsDir(ProcessData c, ReportMeasurementData m) =>
      'contracts/${c.id}/measurements/${m.id}/attachments';

  String storedFileName(String originalName) {
    final base = _sanitize(_baseName(originalName));
    final rnd = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ex = _extFromName(originalName);
    return '$base-$rnd${ex.isEmpty ? ".bin" : ex}';
  }

  // ---------- API antiga (único PDF) ----------
  Future<bool> exists(
      ProcessData c,
      ReportMeasurementData m, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      await _storage.ref(pathFor(c, m, extrato: extrato)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(
      ProcessData c,
      ReportMeasurementData m, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      return await _storage.ref(pathFor(c, m, extrato: extrato)).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ProcessData contract,
    required ReportMeasurementData reportMeasurement,
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
      measurement: reportMeasurement,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
      extrato: extrato,
    );
  }

  Future<String> uploadBytes({
    required ProcessData contract,
    required ReportMeasurementData measurement,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final ref = _storage.ref(pathFor(contract, measurement, extrato: extrato));
    final task =
    ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
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
      ReportMeasurementData m, {
        PublicacaoExtratoData? extrato,
      }) async {
    try {
      await _storage.ref(pathFor(c, m, extrato: extrato)).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------- Compat (mantém API antiga da UI) ----------
  Future<bool> verificarSePdfDeMedicaoExiste({
    required ProcessData contract,
    required ReportMeasurementData measurement,
    PublicacaoExtratoData? extrato,
  }) =>
      exists(contract, measurement, extrato: extrato);

  Future<String?> getPdfUrlDaMedicao({
    required ProcessData contract,
    required ReportMeasurementData measurement,
    PublicacaoExtratoData? extrato,
  }) =>
      getUrl(contract, measurement, extrato: extrato);

  Future<void> sendPdf({
    required ProcessData? contract,
    required ReportMeasurementData? measurement,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
    PublicacaoExtratoData? extrato,
  }) async {
    final c = contract;
    final m = measurement;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF da medição.');
    if (m == null) throw Exception('Medição nula ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (m.id == null) {
      throw Exception('ReportMeasurementData sem idReportMeasurement.');
    }

    final url = await uploadWithPicker(
      contract: c,
      reportMeasurement: m,
      onProgress: onProgress,
      extrato: extrato,
    );
    if (onUploaded != null) await onUploaded(url);
  }

  Future<void> salvarUrlPdfDaReportMeasurement({
    required String contractId,
    required String reportMeasurementId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(reportMeasurementId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {}
  }

  // ======= NOVOS MÉTODOS: múltiplos anexos com rótulo =======

  Future<Attachment> pickAndUploadAttachment({
    required ProcessData contract,
    required ReportMeasurementData measurement,
    required String label,
    void Function(double progress)? onProgress,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    final file = result.files.single;
    return uploadAttachmentBytes(
      contract: contract,
      measurement: measurement,
      bytes: file.bytes!,
      originalName: file.name,
      label: label,
      onProgress: onProgress,
    );
  }

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required ReportMeasurementData measurement,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = attachmentsDir(contract, measurement);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _extFromName(originalName) == '.pdf'
            ? 'application/pdf'
            : 'application/octet-stream',
        customMetadata: {'originalName': originalName},
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }

    await task;

    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();

    return Attachment(
      id: ref.name,
      label: label.isEmpty ? _baseName(originalName) : label,
      url: url,
      path: ref.fullPath,
      ext: _extFromName(originalName),
      size: meta.size?.toInt(),
      createdAt: DateTime.now(),
      createdBy: FirebaseAuth.instance.currentUser?.uid,
    );
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }
}
