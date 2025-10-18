// ==============================
// lib/_blocs/process/contracts/validity/validity_storage_bloc.dart
// ==============================
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';

import 'package:siged/_blocs/process/validity/validity_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Storage (upload/getUrl/exists/delete) de **validades**.
/// Agora com suporte a múltiplos anexos com rótulo (mantém compat com pdfUrl legado).
class ValidityStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ValidityStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

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

  // pastas
  String folderFor(ContractData c, ValidityData v) =>
      'contracts/${c.id}/orders/${v.id}/';

  // caminho legado (um único pdf “padrão”)
  String legacyFileName(ContractData c, ValidityData v) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (v.orderNumber ?? 0).toString().padLeft(3, '0');
    final tipo     = _sanitize(v.ordertype ?? 'tipo');
    return '$contrato-$ordem-$tipo.pdf';
  }

  String legacyPathFor(ContractData c, ValidityData v) =>
      '${folderFor(c, v)}${legacyFileName(c, v)}';

  // ---------- Operações principais (multi + legado) ----------

  Future<bool> exists(ContractData c, ValidityData v) async {
    try {
      await _storage.ref(legacyPathFor(c, v)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, ValidityData v) async {
    try {
      return await _storage.ref(legacyPathFor(c, v)).getDownloadURL();
    } catch (e) {
      debugPrint('ValidityStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  // ======= Multi-anexos =======
  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required ValidityData validity,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir  = folderFor(contract, validity);
    final name = storedFileName(originalName);
    final ref  = _storage.ref('$dir/$name');

    final contentType =
    (_extFromName(originalName) == '.pdf') ? 'application/pdf' : 'application/octet-stream';

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {'originalName': originalName, 'label': label},
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

  Future<List<({String name, String url})>> listarArquivosDaValidade({
    required String contractId,
    required String validityId,
  }) async {
    final folderRef = _storage.ref('contracts/$contractId/orders/$validityId/');
    final result = await folderRef.listAll();

    final out = <({String name, String url})>[];
    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();
        out.add((name: item.name, url: url));
      } catch (_) {}
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (e) {
      debugPrint('Erro ao deletar "$storagePath": $e');
      rethrow;
    }
  }

  // ======= Legado (um arquivo) =======
  Future<String> uploadWithPicker({
    required ContractData contract,
    required ValidityData validade,
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
      validade: validade,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  Future<String> uploadBytes({
    required ContractData contract,
    required ValidityData validade,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(legacyPathFor(contract, validade));
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

  Future<bool> delete(ContractData c, ValidityData v) async {
    try {
      await _storage.ref(legacyPathFor(c, v)).delete();
      return true;
    } catch (e) {
      debugPrint('ValidityStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Metadado de PDF no Firestore ----------
  Future<void> salvarUrlPdfDaValidade({
    required String contractId,
    required String validadeId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('orders')
          .doc(validadeId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF da validade no Firestore: $e');
    }
  }

  // ---------- Helpers de compatibilidade ----------
  Future<bool> verificarSePdfDeValidadeExiste({
    required ContractData contract,
    required ValidityData validade,
  }) => exists(contract, validade);

  Future<String?> getPdfUrlDaValidade({
    required ContractData contract,
    required ValidityData validade,
  }) => getUrl(contract, validade);

  Future<void> sendPdf({
    required ContractData contract,
    required ValidityData validade,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
  }) async {
    final url = await uploadWithPicker(
      contract: contract,
      validade: validade,
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
