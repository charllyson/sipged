import 'dart:typed_data';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Responsável APENAS por Storage (upload/getUrl/exists/delete).
class ProcessStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ProcessStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ProcessData c) {
    final n = _sanitize(c.contractNumber ?? 'contrato');
    return '$n-.pdf';
  }

  /// Padrão único de pasta do PDF principal (nova convenção).
  String pathFor(ProcessData c) => 'contracts/${c.id}/hiring/${fileName(c)}';

  /// Pasta de anexos do SideListBox
  String docsFolderForId(String contractId) => 'contracts/$contractId/docs';

  // ---------- Operações principais (PDF principal) ----------
  Future<bool> exists(ProcessData c) async {
    try {
      await _storage.ref(pathFor(c)).getMetadata();
      return true;
    } catch (_) {
      // Fallbacks legados
      for (final alt in [
        'contracts/${c.id}/0.resume/${fileName(c)}',
        'contracts/${c.id}/contract/${fileName(c)}',
        'contracts/${c.id}/contratos/${fileName(c)}',
      ]) {
        try {
          await _storage.ref(alt).getMetadata();
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  Future<String?> getUrl(ProcessData c) async {
    try {
      return await _storage.ref(pathFor(c)).getDownloadURL();
    } catch (_) {
      // Fallbacks legados
      for (final alt in [
        'contracts/${c.id}/0.resume/${fileName(c)}',
        'contracts/${c.id}/contract/${fileName(c)}',
        'contracts/${c.id}/contratos/${fileName(c)}',
      ]) {
        try {
          return await _storage.ref(alt).getDownloadURL();
        } catch (_) {}
      }
      return null;
    }
  }

  /// Upload via seletor (Web) do PDF principal. Retorna a URL https.
  Future<String> uploadWithPicker({
    required ProcessData contract,
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
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  /// Upload do PDF principal a partir de bytes; retorna URL https.
  Future<String> uploadBytes({
    required ProcessData contract,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract));
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

  Future<bool> delete(ProcessData c) async {
    try {
      await _storage.ref(pathFor(c)).delete();
      return true;
    } catch (_) {
      // tenta legados
      for (final alt in [
        'contracts/${c.id}/0.resume/${fileName(c)}',
        'contracts/${c.id}/contract/${fileName(c)}',
        'contracts/${c.id}/contratos/${fileName(c)}',
      ]) {
        try {
          await _storage.ref(alt).delete();
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  // ---------- Métodos de COMPATIBILIDADE ----------
  Future<bool> verificarSePdfExiste(ProcessData contract) => exists(contract);

  Future<String?> getFirstContractPdfUrl(ProcessData? contract) async {
    if (contract == null) return null;
    return getUrl(contract);
  }

  Future<bool> deletePdf(ProcessData? contract) async {
    if (contract == null) return false;
    return delete(contract);
  }

  /// Upload do PDF principal com callback opcional pós-upload
  Future<void> sendPdf({
    required ProcessData? contract,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
  }) async {
    final c = contract;
    if (c == null) {
      throw Exception('Contrato nulo ao enviar PDF.');
    }
    final url = await uploadWithPicker(contract: c, onProgress: onProgress);
    if (onUploaded != null) {
      await onUploaded(url);
    }
  }

  // -------------------- URL do PDF no Firestore --------------------
  Future<void> salvarUrlPdfDoContrato(String contractId, String url) async {
    try {
      await _db.collection('contracts').doc(contractId).update({
        'urlContractPdf': url, // novo campo padronizado
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF do contrato no Firestore: $e');
    }
  }

  Future<bool> removeUrlPdfDoContrato(String contractId) async {
    try {
      await _db.collection('contracts').doc(contractId).update({
        'urlContractPdf': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      debugPrint('Erro ao remover urlContractPdf: $e');
      return false;
    }
  }

  // ===========================================================================
  // ========================  SIDE LIST BOX  ==================================
  // ===========================================================================

  /// Lista todos os anexos do contrato, incluindo:
  /// - contracts/{id}/docs/*
  /// - contracts/{id}/hiring/*
  /// - contracts/{id}/0.resume/*
  /// - LEGADO: contracts/{id}/contract/*
  /// - LEGADO-PT: contracts/{id}/contratos/*
  Future<List<Attachment>> listarDocsContrato({
    required String contractId,
  }) async {
    final List<Attachment> arquivos = [];

    Future<Attachment> _toAttachment(Reference itemRef) async {
      final meta = await itemRef.getMetadata();
      final url = await itemRef.getDownloadURL();
      final rawName = itemRef.name;
      return Attachment(
        id: rawName,
        label: _labelFromStoredName(rawName), // rótulo base (pode ser sobrescrito pelo Firestore)
        url: url,
        path: itemRef.fullPath,               // <- CHAVE ESTÁVEL
        ext: _extFromName(rawName),
        size: meta.size?.toInt(),
        createdAt: meta.timeCreated,
        updatedAt: meta.updated,
        createdBy: meta.customMetadata?['createdBy'],
        updatedBy: meta.customMetadata?['updatedBy'],
      );
    }

    // Pastas a varrer (algumas podem não existir)
    final folders = <String>[
      'contracts/$contractId/docs',
      'contracts/$contractId/hiring',
      'contracts/$contractId/0.resume',
      'contracts/$contractId/contract',
      'contracts/$contractId/contratos',
    ];

    for (final p in folders) {
      try {
        final ref = _storage.ref(p);
        final list = await ref.listAll();
        for (final item in list.items) {
          arquivos.add(await _toAttachment(item));
        }
      } catch (_) {
        // pasta pode não existir — ignorar
      }
    }

    // Ordenação por label (case-insensitive)
    arquivos.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return arquivos;
  }

  /// Abre seletor e sobe um anexo para `contracts/{contractId}/docs/…`
  /// Retorna o `Attachment` pronto para usar no SideListBox.
  Future<Attachment> uploadDocContratoWithPicker({
    required String contractId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }

    final file = result.files.single;
    return uploadDocContratoBytes(
      contractId: contractId,
      fileName: file.name,
      bytes: file.bytes!,
      onProgress: onProgress,
    );
  }

  /// (Compat) Versão que retorna apenas a URL
  Future<String> uploadDocContratoWithPickerUrl({
    required String contractId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    final a = await uploadDocContratoWithPicker(
      contractId: contractId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
    return a.url;
  }

  /// Upload de anexo via bytes (útil em integrações). Retorna `Attachment`.
  Future<Attachment> uploadDocContratoBytes({
    required String contractId,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final sanitizedName = _sanitize(fileName.isNotEmpty ? fileName : 'anexo');
    final contentType = _guessContentTypeFromName(sanitizedName);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final storedName = '$ts-$sanitizedName';
    final path = '${docsFolderForId(contractId)}/$storedName';

    final ref = _storage.ref(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          if (uid != null) 'createdBy': uid,
          'originalName': sanitizedName,
        },
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
      });
    }

    final snap = await task;
    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();

    return Attachment(
      id: ref.name,
      label: _labelFromStoredName(ref.name),
      url: url,
      path: ref.fullPath, // <- usado como chave de merge
      ext: _extFromName(ref.name),
      size: meta.size?.toInt() ?? bytes.lengthInBytes,
      createdAt: snap.metadata?.timeCreated,
      updatedAt: snap.metadata?.updated,
      createdBy: uid,
      updatedBy: uid,
    );
  }

  /// Deleta um arquivo do Storage a partir da URL pública.
  Future<bool> deleteByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('deleteByUrl erro: $e');
      return false;
    }
  }

  // ---- helpers ----
  String _guessContentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  /// Remove prefixo de timestamp nos arquivos enviados na pasta `docs/`
  /// (ex.: 1714333221-arquivo.pdf -> arquivo.pdf).
  String _labelFromStoredName(String stored) {
    final dash = stored.indexOf('-');
    if (dash > 0 && dash < stored.length - 1) {
      return stored.substring(dash + 1);
    }
    return stored;
  }

  String _extFromName(String name) {
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(name.trim());
    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }
}
