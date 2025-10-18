import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_data.dart';
// Reaproveita o mesmo modelo de anexo
import 'package:siged/_widgets/list/files/attachment.dart';

/// Storage de PDFs/arquivos de **reajuste** da medição.
class AdjustmentMeasurementStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  AdjustmentMeasurementStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, AdjustmentMeasurementData a) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (a.order ?? 0).toString();
    final proc     = _sanitize(a.numberprocess ?? 'processo');
    return 'adjustment-$contrato-$ordem-$proc.pdf';
  }

  String pathFor({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
  }) => 'contracts/${contract.id}/measurements/$measurementId/${fileName(contract, adj)}';

  // ======= Suporte a multi-anexos =======
  String attachmentsDir(ContractData c, AdjustmentMeasurementData a) =>
      'contracts/${c.id}/measurements/${a.id}/attachments';

  String _extFromName(String name) {
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(name.trim());
    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?'); if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#'); if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final rnd  = (DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    final ext  = _extFromName(original);
    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  /// Pick genérico (qualquer extensão), retorna bytes + nome original (para sugerir rótulo após o pick)
  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  /// Upload a partir de bytes com rótulo decidido após o pick
  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir  = attachmentsDir(contract, adjustment);
    final name = storedFileName(originalName);
    final ref  = _storage.ref('$dir/$name');

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _extFromName(originalName) == '.pdf' ? 'application/pdf' : 'application/octet-stream',
        customMetadata: {'originalName': originalName},
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }

    await task;
    final url  = await ref.getDownloadURL();
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
    try { await _storage.ref(storagePath).delete(); } catch (_) {}
  }

  // ======= API legado (PDF único) mantida =======
  Future<bool> exists({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
  }) async {
    try {
      await _storage.ref(pathFor(contract: contract, measurementId: measurementId, adj: adj)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
  }) async {
    try {
      return await _storage
          .ref(pathFor(contract: contract, measurementId: measurementId, adj: adj))
          .getDownloadURL();
    } catch (e) {
      debugPrint('AdjustmentMeasurementStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ContractData contract,
    required String adjustmentId,
    required AdjustmentMeasurementData adj,
    required void Function(double progress) onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
    }
    final ref = _storage.ref(pathFor(contract: contract, measurementId: adjustmentId, adj: adj));
    final task = ref.putData(result.files.single.bytes!, SettableMetadata(contentType: 'application/pdf'));
    task.snapshotEvents.listen((e) {
      if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
    });
    await task;
    return await ref.getDownloadURL();
  }

  Future<bool> delete({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
  }) async {
    try {
      await _storage.ref(pathFor(contract: contract, measurementId: measurementId, adj: adj)).delete();
      return true;
    } catch (e) {
      debugPrint('AdjustmentMeasurementStorageBloc.delete erro: $e');
      return false;
    }
  }

  Future<void> salvarUrlPdfDoAdjustment({
    required String contractId,
    required String adjustmentId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts').doc(contractId)
          .collection('measurements').doc(adjustmentId)
          .update({
        'pdfUrlAdjustment': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF (adjustment) no Firestore: $e');
    }
  }

  @override
  void dispose() { super.dispose(); }
}
