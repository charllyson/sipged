import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_data.dart';

/// Storage de PDFs de **revisão** da medição.
class RevisionMeasurementStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  RevisionMeasurementStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, RevisionMeasurementData r) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (r.order ?? 0).toString();
    final proc     = _sanitize(r.numberprocess ?? 'processo');
    return 'revision-$contrato-$ordem-$proc.pdf';
  }

  String pathFor({
    required ContractData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) =>
      'contracts/${contract.id}/measurements/$measurementId/${fileName(contract, rev)}';

  Future<bool> exists({
    required ContractData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) async {
    try {
      await _storage.ref(pathFor(contract: contract, measurementId: measurementId, rev: rev)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl({
    required ContractData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) async {
    try {
      return await _storage
          .ref(pathFor(contract: contract, measurementId: measurementId, rev: rev))
          .getDownloadURL();
    } catch (e) {
      debugPrint('RevisionMeasurementStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ContractData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
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
      measurementId: measurementId,
      rev: rev,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  Future<String> uploadBytes({
    required ContractData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract: contract, measurementId: measurementId, rev: rev));
    final task = ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }
    await task;
    return await ref.getDownloadURL();
  }

  Future<bool> delete({
    required ContractData contract,
    required String measurementId,
    required RevisionMeasurementData rev,
  }) async {
    try {
      await _storage.ref(pathFor(contract: contract, measurementId: measurementId, rev: rev)).delete();
      return true;
    } catch (e) {
      debugPrint('RevisionMeasurementStorageBloc.delete erro: $e');
      return false;
    }
  }

  // Metadado no Firestore (opcional)
  Future<void> salvarUrlPdfDaRevision({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts').doc(contractId)
          .collection('measurements').doc(measurementId)
          .update({
        'pdfUrlRevision': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF (revision) no Firestore: $e');
    }
  }

  @override
  void dispose() { super.dispose(); }
}
