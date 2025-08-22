// lib/_blocs/documents/contracts/additives/additives_storage_bloc.dart
import 'dart:typed_data';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:sisged/_datas/documents/contracts/additive/additive_data.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';

/// Responsável APENAS por Storage (upload/getUrl/exists/delete) de PDFs de **aditivos**.
class AdditivesStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  AdditivesStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, AdditiveData a) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (a.additiveOrder ?? '0').toString();
    final proc     = _sanitize(a.additiveNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, AdditiveData a) =>
      'contracts/${c.id}/additives/${a.id}/${fileName(c, a)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, AdditiveData a) async {
    try {
      await _storage.ref(pathFor(c, a)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, AdditiveData a) async {
    try {
      return await _storage.ref(pathFor(c, a)).getDownloadURL();
    } catch (e) {
      debugPrint('AdditivesStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna a URL https.
  Future<String> uploadWithPicker({
    required ContractData contract,
    required AdditiveData additive,
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
      additive: additive,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  /// Upload a partir de bytes; retorna URL https.
  Future<String> uploadBytes({
    required ContractData contract,
    required AdditiveData additive,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract, additive));
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

  Future<bool> delete(ContractData c, AdditiveData a) async {
    try {
      await _storage.ref(pathFor(c, a)).delete();
      return true;
    } catch (e) {
      debugPrint('AdditivesStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Métodos de COMPATIBILIDADE (mantêm sua UI funcionando) ----------

  Future<bool> verificarSePdfDeAditivoExiste({
    required ContractData contract,
    required AdditiveData additive,
  }) => exists(contract, additive);

  Future<String?> getPdfUrlDoAditivo({
    required ContractData contract,
    required AdditiveData additive,
  }) => getUrl(contract, additive);

  /// Faz o upload e, opcionalmente, chama um callback com a URL para persistir no Firestore.
  Future<void> sendPdf({
    required ContractData? contract,
    required AdditiveData? additive,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
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

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore)
  //  → Upload/exists/getUrl/delete ficam no AdditivesStorageBloc
  // ---------------------------------------------------------------------------

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
