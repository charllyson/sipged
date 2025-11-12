import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Storage de PDFs/arquivos de **revisão** da medição.
class RevisionMeasurementStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  RevisionMeasurementStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ProcessData c, RevisionMeasurementData r) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem = (r.order ?? 0).toString();
    final proc = _sanitize(r.numberprocess ?? 'processo');
    return 'revision-$contrato-$ordem-$proc.pdf';
  }

  String pathFor({
    required ProcessData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) =>
      'contracts/${contract.id}/measurements/$measurementId/${fileName(contract, rev)}';

  // ======= Suporte a multi-anexos =======
  String attachmentsDir(ProcessData c, RevisionMeasurementData r) =>
      'contracts/${c.id}/measurements/${r.id}/attachments';

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

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final rnd = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(original);
    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required RevisionMeasurementData revision,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = attachmentsDir(contract, revision);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType:
        _extFromName(originalName) == '.pdf' ? 'application/pdf' : 'application/octet-stream',
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

  // ====== API legado (PDF único) ======
  Future<bool> exists({
    required ProcessData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) async {
    try {
      await _storage
          .ref(pathFor(contract: contract, measurementId: measurementId, rev: rev))
          .getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl({
    required ProcessData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) async {
    try {
      return await _storage
          .ref(pathFor(contract: contract, measurementId: measurementId, rev: rev))
          .getDownloadURL();
    } catch (e) {
      debugPrint('RevisionMeasurementStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ProcessData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
    required void Function(double progress) onProgress,
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
      measurementId: measurementId,
      rev: rev,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  Future<String> uploadBytes({
    required ProcessData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref =
    _storage.ref(pathFor(contract: contract, measurementId: measurementId, rev: rev));
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

  Future<bool> delete({
    required ProcessData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) async {
    try {
      await _storage
          .ref(pathFor(contract: contract, measurementId: measurementId, rev: rev))
          .delete();
      return true;
    } catch (e) {
      debugPrint('RevisionMeasurementStorageBloc.delete erro: $e');
      return false;
    }
  }

  // Metadado no Firestore (opcional)
  Future<void> salvarUrlPdfDaRevision({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(measurementId)
          .update({
        'pdfUrlRevision': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF (revision) no Firestore: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
