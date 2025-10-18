// ==============================
// lib/_blocs/process/contracts/apostilles/apostilles_storage_bloc.dart
// ==============================
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Storage (upload/list/getUrl/delete) de PDFs/arquivos de **apostilamentos**.
/// Mantém métodos legados + novos para múltiplos anexos com rótulo.
class ApostillesStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ApostillesStorageBloc({FirebaseStorage? storage})
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

  // legados (um arquivo “principal” por apostila)
  String fileName(ContractData c, ApostillesData a) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = ((a.apostilleOrder ?? 0)).toString().padLeft(3, '0');
    final proc     = _sanitize(a.apostilleNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, ApostillesData a) =>
      'contracts/${c.id}/apostilles/${a.id}/${fileName(c, a)}';

  // multi-arquivos
  String folderFor(ContractData c, ApostillesData a) =>
      'contracts/${c.id}/apostilles/${a.id}/';

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final rnd  = (DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    final ext  = _extFromName(original);
    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  // ---------- Métodos legados ----------
  Future<bool> exists(ContractData c, ApostillesData a) async {
    try {
      await _storage.ref(pathFor(c, a)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, ApostillesData a) async {
    try {
      return await _storage.ref(pathFor(c, a)).getDownloadURL();
    } catch (e) {
      debugPrint('ApostillesStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ContractData contract,
    required ApostillesData apostille,
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
      apostille: apostille,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  Future<String> uploadBytes({
    required ContractData contract,
    required ApostillesData apostille,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract, apostille));
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

  Future<bool> delete(ContractData c, ApostillesData a) async {
    try {
      await _storage.ref(pathFor(c, a)).delete();
      return true;
    } catch (e) {
      debugPrint('ApostillesStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- COMPAT wrappers ----------
  Future<bool> verificarSePdfDeApostilaExiste({
    required ContractData contract,
    required ApostillesData apostille,
  }) => exists(contract, apostille);

  Future<String?> getPdfUrlDaApostila({
    required ContractData contract,
    required ApostillesData apostille,
  }) => getUrl(contract, apostille);

  Future<void> sendPdf({
    required ContractData? contract,
    required ApostillesData? apostille,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
  }) async {
    final c = contract;
    final a = apostille;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF da apostila.');
    if (a == null) throw Exception('Apostila nula ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (a.id == null) throw Exception('ApostillesData sem id.');

    final url = await uploadWithPicker(
      contract: c,
      apostille: a,
      onProgress: onProgress,
    );
    if (onUploaded != null) {
      await onUploaded(url);
    }
  }

  // ---------- NOVOS métodos: múltiplos anexos com rótulo ----------
  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required ApostillesData apostille,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir  = folderFor(contract, apostille);
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

  /// Lista todos os arquivos já enviados (multi) para a apostila.
  Future<List<({String name, String url})>> listarArquivosDaApostila({
    required String contractId,
    required String apostilleId,
  }) async {
    final folderRef = _storage.ref('contracts/$contractId/apostilles/$apostilleId/');
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

  Future<void> deletarArquivoDaApostilaPorUrl(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (e) {
      debugPrint('Erro ao deletar "$storagePath": $e');
      rethrow;
    }
  }

  // ---------- metadado no Firestore ----------
  Future<void> salvarUrlPdfDaApostila({
    required String contractId,
    required String apostilleId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .doc(apostilleId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF da apostila no Firestore: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
