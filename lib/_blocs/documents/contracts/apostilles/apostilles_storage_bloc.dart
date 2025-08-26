// lib/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_data.dart';

/// Responsável APENAS por Storage (upload/getUrl/exists/delete) de PDFs de **apostilamentos**.
class ApostillesStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ApostillesStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, ApostillesData a) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = ((a.apostilleOrder ?? 0)).toString().padLeft(3, '0');
    final proc     = _sanitize(a.apostilleNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, ApostillesData a) =>
      'contracts/${c.id}/apostilles/${a.id}/${fileName(c, a)}';

  // ---------- Operações principais ----------
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

  /// Upload via seletor (Web/desktop). Retorna a URL https.
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

  /// Upload a partir de bytes; retorna URL https.
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

  // ---------- Métodos de COMPATIBILIDADE (mantêm sua UI funcionando) ----------

  Future<bool> verificarSePdfDeApostilaExiste({
    required ContractData contract,
    required ApostillesData apostille,
  }) => exists(contract, apostille);

  Future<String?> getPdfUrlDaApostila({
    required ContractData contract,
    required ApostillesData apostille,
  }) => getUrl(contract, apostille);

  /// Faz o upload e, opcionalmente, chama um callback com a URL para persistir no Firestore.
  Future<void> sendPdf({
    required ContractData? contract,
    required ApostillesData? apostille,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
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

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore)
  //  → Upload/exists/getUrl/delete ficam no ApostillesStorageBloc
  // ---------------------------------------------------------------------------

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
