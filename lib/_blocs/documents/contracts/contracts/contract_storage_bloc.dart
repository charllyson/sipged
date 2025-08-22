// lib/_blocs/documents/contracts/contracts/contract_storage_bloc.dart
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';

/// Responsável APENAS por Storage (upload/getUrl/exists/delete).
class ContractStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ContractStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c) {
    final n = _sanitize(c.contractNumber ?? 'contrato');
    final p = _sanitize(c.contractNumberProcess ?? 'processo');
    return '$n-$p.pdf';
  }

  /// Padrão único de pasta. Troque 'contract' por 'mainInformation' se preferir.
  String pathFor(ContractData c) => 'contracts/${c.id}/contract/${fileName(c)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c) async {
    try {
      await _storage.ref(pathFor(c)).getMetadata();
      return true;
    } catch (_) {
      // Fallback legado
      try {
        final old = 'contracts/${c.id}/mainInformation/${fileName(c)}';
        await _storage.ref(old).getMetadata();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<String?> getUrl(ContractData c) async {
    try {
      return await _storage.ref(pathFor(c)).getDownloadURL();
    } catch (_) {
      try {
        final old = 'contracts/${c.id}/mainInformation/${fileName(c)}';
        return await _storage.ref(old).getDownloadURL();
      } catch (e) {
        debugPrint('ContractStorageBloc.getUrl erro: $e');
        return null;
      }
    }
  }

  /// Upload via seletor (Web). Retorna a URL https.
  Future<String> uploadWithPicker({
    required ContractData contract,
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

  /// Upload a partir de bytes; retorna URL https.
  Future<String> uploadBytes({
    required ContractData contract,
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

  Future<bool> delete(ContractData c) async {
    try {
      await _storage.ref(pathFor(c)).delete();
      return true;
    } catch (e) {
      debugPrint('ContractStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Métodos de COMPATIBILIDADE (mantêm sua UI funcionando) ----------

  /// Era usado no ContractsBloc antigo.
  Future<bool> verificarSePdfExiste(ContractData contract) => exists(contract);

  /// Era getFirstContractPdfUrl no ContractsBloc.
  Future<String?> getFirstContractPdfUrl(ContractData? contract) async {
    if (contract == null) return null;
    return getUrl(contract);
  }

  /// Era deleteContractPdf no ContractsBloc.
  Future<bool> deletePdf(ContractData? contract) async {
    if (contract == null) return false;
    return delete(contract);
  }

  /// Era sendContractPdfWeb no ContractsBloc.
  /// Agora faz upload e, opcionalmente, chama um callback com a URL para quem quiser salvar no Firestore.
  Future<void> sendPdf({
    required ContractData? contract,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded, // opcional
  }) async {
    final c = contract;
    if (c == null) {
      throw Exception('Contrato nulo ao enviar PDF.');
    }
    final url = await uploadWithPicker(contract: c, onProgress: onProgress);
    if (onUploaded != null) {
      await onUploaded(url); // ex.: chamar ContractsBloc.salvarUrlPdfDoContrato
    }
  }

  // -------------------- URL do PDF (metadado) --------------------

  /// Salva a URL https do PDF no documento do contrato.
  Future<void> salvarUrlPdfDoContrato(String contractId, String url) async {
    try {
      await _db.collection('contracts').doc(contractId).update({
        'urlContractPdf': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF do contrato no Firestore: $e');
    }
  }

  /// Remove a URL do PDF (não apaga arquivo no Storage).
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

}
