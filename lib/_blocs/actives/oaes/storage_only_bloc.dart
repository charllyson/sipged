// lib/_blocs/storage/storage_only_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

/// Uploader genérico que **só** lida com Firebase Storage.
/// Não grava metadados em Firestore.
/// Retorna `Attachment` pronto para você persistir onde quiser.
class StorageOnlyBloc extends BlocBase {
  final FirebaseStorage _storage;
  StorageOnlyBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // ---------------- Helpers de nome e caminho ----------------

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?'); if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#'); if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String _extWithDot(String name) {
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(name.trim());
    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }

  String _extNoDot(String name) {
    final e = _extWithDot(name);
    return e.isEmpty ? '' : e.substring(1);
  }

  String storedFileName(String originalName) {
    final base = _sanitize(_baseName(originalName));
    final rnd  = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString().padLeft(6, '0');
    final ex   = _extWithDot(originalName);
    return '$base-$rnd${ex.isEmpty ? ".bin" : ex}';
  }

  String _contentTypeForExt(String extNoDot) {
    final e = (extNoDot).toLowerCase();
    // mapeamento básico; ajuste à vontade
    switch (e) {
      case 'pdf':  return 'application/pdf';
      case 'png':  return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      case 'svg':  return 'image/svg+xml';
      case 'json': return 'application/json';
      case 'csv':  return 'text/csv';
      case 'txt':  return 'text/plain';
      case 'xml':  return 'application/xml';
      case 'zip':  return 'application/zip';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':  return 'application/vnd.ms-excel';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':  return 'application/msword';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:     return 'application/octet-stream';
    }
  }

  // ----------------- Upload com File Picker -----------------

  /// Abre o seletor, sobe o arquivo para `baseDir` (ex.: `actives_oaes/{id}/attachments`)
  /// e retorna um `Attachment` pronto. **Não** grava no Firestore.
  ///
  /// [baseDir] deve ser um caminho de pasta (sem barra no final, opcional).
  /// [allowedExtensions] exemplo: `['pdf','png','jpg']`; se `null`, permite qualquer.
  Future<Attachment?> pickAndUploadSingle({
    required String baseDir,
    List<String>? allowedExtensions,
    void Function(double progress)? onProgress,
    String? forcedLabel, // se quiser forçar o rótulo
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return null;

    final f = result.files.single;
    return uploadBytes(
      baseDir: baseDir,
      bytes: f.bytes!,
      originalName: f.name,
      onProgress: onProgress,
      forcedLabel: forcedLabel,
    );
  }

  /// Seleciona **vários** arquivos, faz upload em lote e retorna a lista de `Attachment`.
  Future<List<Attachment>> pickAndUploadMultiple({
    required String baseDir,
    List<String>? allowedExtensions,
    void Function(double progress, int index, int total)? onProgress, // progresso por item
    String Function(String originalName)? labelFactory,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null) return const [];

    final files = result.files.where((f) => f.bytes != null).toList();
    final total = files.length;
    final out = <Attachment>[];

    for (var i = 0; i < total; i++) {
      final f = files[i];
      final att = await uploadBytes(
        baseDir: baseDir,
        bytes: f.bytes!,
        originalName: f.name,
        onProgress: (p) => onProgress?.call(p, i, total),
        forcedLabel: labelFactory?.call(f.name),
      );
      out.add(att);
    }
    return out;
  }

  // --------------------- Upload de bytes ---------------------

  /// Faz upload de [bytes] para `[baseDir]/[storedFileName(originalName)]`
  /// e retorna um `Attachment` com url, path, ext, size etc.
  Future<Attachment> uploadBytes({
    required String baseDir,
    required Uint8List bytes,
    required String originalName,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) async {
    final dir  = baseDir.endsWith('/') ? baseDir.substring(0, baseDir.length - 1) : baseDir;
    final name = storedFileName(originalName);
    final ref  = _storage.ref('$dir/$name');

    final ext = _extNoDot(originalName);
    final label = forcedLabel ?? _baseName(originalName);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
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
    final now  = DateTime.now();

    return Attachment(
      id: ref.name,
      label: label.isEmpty ? 'Arquivo' : label,
      url: url,
      path: ref.fullPath,
      ext: ext.isEmpty ? 'bin' : ext,
      size: meta.size?.toInt(),
      createdAt: now,
      createdBy: FirebaseAuth.instance.currentUser?.uid,
      updatedAt: now,
      updatedBy: FirebaseAuth.instance.currentUser?.uid,
    );
  }

  // ---------------------- Utilitários -----------------------

  Future<bool> deleteByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      return true;
    } catch (e) {
      debugPrint('StorageOnlyBloc.deleteByPath erro: $e');
      return false;
    }
  }

  Future<String?> getDownloadUrlByPath(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (e) {
      debugPrint('StorageOnlyBloc.getDownloadUrlByPath erro: $e');
      return null;
    }
  }

  Future<bool> existsPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() { super.dispose(); }
}
