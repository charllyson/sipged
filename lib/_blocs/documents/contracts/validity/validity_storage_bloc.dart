import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_datas/documents/contracts/validity/validity_data.dart';

/// Responsável APENAS por Storage (upload/getUrl/exists/delete) de PDFs de **validades**.
class ValidityStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ValidityStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, ValidityData v) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (v.orderNumber ?? '0').toString();
    final tipo     = _sanitize(v.ordertype ?? 'tipo');
    return '$contrato-$ordem-$tipo.pdf';
  }

  String pathFor(ContractData c, ValidityData v) =>
      'contracts/${c.id}/orders/${v.id}/${fileName(c, v)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, ValidityData v) async {
    try {
      await _storage.ref(pathFor(c, v)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, ValidityData v) async {
    try {
      return await _storage.ref(pathFor(c, v)).getDownloadURL();
    } catch (e) {
      debugPrint('ValidityStorageBloc.getUrl erro: $e');
      return null;
    }
  }

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
    final ref = _storage.ref(pathFor(contract, validade));
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
      await _storage.ref(pathFor(c, v)).delete();
      return true;
    } catch (e) {
      debugPrint('ValidityStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Métodos de COMPATIBILIDADE (para UI existente) ----------

  Future<bool> verificarSePdfDeValidadeExiste(
      {required ContractData contract, required ValidityData validade}) =>
      exists(contract, validade);

  Future<String?> getPdfUrlDaValidade(
      {required ContractData contract, required ValidityData validade}) =>
      getUrl(contract, validade);

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

  // ---------------------------------------------------------------------------
  // Metadado de PDF (somente URL no Firestore)
  //  → Upload/exists/getUrl/delete ficam no ValidityStorageBloc
  // ---------------------------------------------------------------------------

  /// Salva a URL https do PDF da validade no Firestore.
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

  @override
  void dispose() {
    super.dispose();
  }
}
