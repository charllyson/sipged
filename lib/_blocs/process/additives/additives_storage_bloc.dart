import 'dart:typed_data';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';

// ✅ usamos o mesmo modelo de anexo do módulo de Relatório
import 'package:siged/_widgets/list/files/attachment.dart';

/// Responsável por Storage (upload/list/getUrl/delete) de arquivos de **aditivos**.
class AdditivesStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  AdditivesStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  // pasta do aditivo (para múltiplos arquivos)
  String folderFor(ProcessData c, AdditiveData a) =>
      'contracts/${c.id}/additives/${a.id}/';

  // nome “legado” (um único pdf)
  String legacyFileName(ProcessData c, AdditiveData a) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (a.additiveOrder ?? 0).toString().padLeft(3, '0');
    final proc     = _sanitize(a.additiveNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  // caminho legado (mantido para compatibilidade)
  String legacyPathFor(ProcessData c, AdditiveData a) =>
      '${folderFor(c, a)}${legacyFileName(c, a)}';

  // ===== helpers de nome/metadata para multi-anexos =====
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
    final rnd  = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString().padLeft(6, '0');
    final ext  = _extFromName(original);
    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  // ---------- Operações principais (multi-arquivos + legado) ----------

  /// Verifica se existe **arquivo legado** no caminho fixo.
  Future<bool> exists(ProcessData c, AdditiveData a) async {
    try {
      await _storage.ref(legacyPathFor(c, a)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retorna a URL do **arquivo legado** (se existir).
  Future<String?> getUrl(ProcessData c, AdditiveData a) async {
    try {
      return await _storage.ref(legacyPathFor(c, a)).getDownloadURL();
    } catch (e) {
      debugPrint('AdditivesStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Abre seletor e faz upload (multi-arquivos).
  /// Salva em `contracts/{cid}/additives/{aid}/{arquivo_original}_{timestamp}.pdf`
  Future<String> uploadWithPicker({
    required ProcessData contract,
    required AdditiveData additive,
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

    final original = result.files.single.name; // ex.: doc.pdf
    final safe = _sanitize(original.split('/').last);
    final ts = DateTime.now().millisecondsSinceEpoch;

    final fileName = '${safe}_$ts.pdf';
    final path = '${folderFor(contract, additive)}$fileName';

    return _uploadBytesTo(
      path,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
      contentType: 'application/pdf',
      originalName: original,
    );
  }

  Future<String> _uploadBytesTo(
      String fullPath, {
        required Uint8List bytes,
        void Function(double progress)? onProgress,
        String? contentType,
        String? originalName,
      }) async {
    final ref = _storage.ref(fullPath);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {
          if (originalName != null) 'originalName': originalName,
        },
      ),
    );
    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }
    await task;
    return await ref.getDownloadURL();
  }

  /// Upload **legado** (um arquivo fixo – mantém compat).
  Future<String> uploadBytes({
    required ProcessData contract,
    required AdditiveData additive,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final path = legacyPathFor(contract, additive);
    return _uploadBytesTo(
      path,
      bytes: bytes,
      onProgress: onProgress,
      contentType: 'application/pdf',
    );
  }

  /// Apaga o **arquivo legado** (se existir).
  Future<bool> delete(ProcessData c, AdditiveData a) async {
    try {
      await _storage.ref(legacyPathFor(c, a)).delete();
      return true;
    } catch (e) {
      debugPrint('AdditivesStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- MÚLTIPLOS ARQUIVOS ----------
  /// Lista todos os arquivos da pasta do aditivo no Storage.
  /// Retorna pares (name, url) já ordenados por nome.
  Future<List<({String name, String url})>> listarArquivosDoAditivo({
    required String contractId,
    required String additiveId,
  }) async {
    final folderRef = _storage.ref('contracts/$contractId/additives/$additiveId/');
    final result = await folderRef.listAll();

    final out = <({String name, String url})>[];
    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();
        out.add((name: item.name, url: url));
      } catch (_) {
        // ignora itens inacessíveis
      }
    }

    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  /// Deleta um arquivo (multi) a partir da URL do Storage.
  Future<void> deletarArquivoDoAditivoPorUrl(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  // ========== NOVOS MÉTODOS: compat com ReportMeasurementAttachment ==========

  /// Abre o seletor e retorna **bytes + nome original**.
  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  /// Upload (multi-anexos) retornando **ReportMeasurementAttachment**.
  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required AdditiveData additive,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir  = folderFor(contract, additive);
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

  /// Deleta um arquivo diretamente pelo **caminho** do Storage.
  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (e) {
      debugPrint('Erro ao deletar "$storagePath": $e');
      rethrow;
    }
  }

  // ---------- Persistência do metadado no Firestore ----------
  Future<void> salvarUrlPdfDoAditivo({
    required String contractId,
    required String additiveId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .doc(additiveId)
          .update({
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF do aditivo no Firestore: $e');
    }
  }

  // ---------- WRAPPERS DE COMPATIBILIDADE (mantêm o resto do app funcionando) ----------

  /// (LEGADO) Envia um PDF abrindo o seletor; ao concluir, chama [onUploaded] com a URL.
  Future<void> sendPdf({
    required ProcessData? contract,
    required AdditiveData? additive,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
  }) async {
    final c = contract;
    final a = additive;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF.');
    if (a == null) throw Exception('Aditivo nulo ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (a.id == null) throw Exception('AdditiveData sem id.');

    final url = await uploadWithPicker(
      contract: c,
      additive: a,
      onProgress: onProgress,
    );

    if (onUploaded != null) {
      await onUploaded(url);
    }
  }

  /// (LEGADO) Verifica existência do PDF legado.
  Future<bool> verificarSePdfDeAditivoExiste({
    required ProcessData contract,
    required AdditiveData additive,
  }) {
    return exists(contract, additive);
  }

  /// (LEGADO) Obtém a URL do PDF legado.
  Future<String?> getPdfUrlDoAditivo({
    required ProcessData contract,
    required AdditiveData additive,
  }) {
    return getUrl(contract, additive);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
