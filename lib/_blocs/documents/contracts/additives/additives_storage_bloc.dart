import 'dart:typed_data';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/documents/contracts/additives/additive_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

/// Responsável por Storage (upload/list/getUrl/delete) de arquivos de **aditivos**.
class AdditivesStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  AdditivesStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  // pasta do aditivo (para múltiplos arquivos)
  String folderFor(ContractData c, AdditiveData a) =>
      'contracts/${c.id}/additives/${a.id}/';

  // nome “legado” (um único pdf)
  String legacyFileName(ContractData c, AdditiveData a) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (a.additiveOrder ?? 0).toString().padLeft(3, '0');
    final proc     = _sanitize(a.additiveNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  // caminho legado (mantido para compatibilidade)
  String legacyPathFor(ContractData c, AdditiveData a) =>
      '${folderFor(c, a)}${legacyFileName(c, a)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, AdditiveData a) async {
    try {
      await _storage.ref(legacyPathFor(c, a)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, AdditiveData a) async {
    try {
      return await _storage.ref(legacyPathFor(c, a)).getDownloadURL();
    } catch (e) {
      debugPrint('AdditivesStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Abre seletor e faz upload. Para múltiplos, salva com nome do arquivo original + timestamp.
  Future<String> uploadWithPicker({
    required ContractData contract,
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
    final base = original.split('/').last;
    final safe = _sanitize(base);
    final ts = DateTime.now().millisecondsSinceEpoch;

    final fileName = '${safe}_$ts.pdf';
    final path = '${folderFor(contract, additive)}$fileName';

    return _uploadBytesTo(path,
        bytes: result.files.single.bytes!, onProgress: onProgress);
  }

  Future<String> _uploadBytesTo(
      String fullPath, {
        required Uint8List bytes,
        void Function(double progress)? onProgress,
      }) async {
    final ref = _storage.ref(fullPath);
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

  /// Upload legado (um arquivo fixo).
  Future<String> uploadBytes({
    required ContractData contract,
    required AdditiveData additive,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final path = legacyPathFor(contract, additive);
    return _uploadBytesTo(path, bytes: bytes, onProgress: onProgress);
    // (mantido para compatibilidade com chamadas antigas)
  }

  Future<bool> delete(ContractData c, AdditiveData a) async {
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

    // pega URL de cada item
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

  /// Deleta um arquivo a partir da URL do Storage.
  Future<void> deletarArquivoDoAditivoPorUrl(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  // ---------- Métodos de compatibilidade (UI antiga) ----------
  Future<bool> verificarSePdfDeAditivoExiste({
    required ContractData contract,
    required AdditiveData additive,
  }) => exists(contract, additive);

  Future<String?> getPdfUrlDoAditivo({
    required ContractData contract,
    required AdditiveData additive,
  }) => getUrl(contract, additive);

  Future<void> sendPdf({
    required ContractData? contract,
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

  @override
  void dispose() {
    super.dispose();
  }
}
