// lib/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_datas/documents/measurement/reports/report_measurement_data.dart';

/// Responsável APENAS por Storage (upload/getUrl/exists/delete) de PDFs de **medições**.
class ReportMeasurementStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  ReportMeasurementStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Utils ----------
  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(ContractData c, ReportMeasurementData m) {
    final contrato = _sanitize(c.contractNumber ?? 'contrato');
    final ordem    = (m.orderReportMeasurement ?? '0').toString();
    final proc     = _sanitize(m.numberAdjustmentProcessMeasurement ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String pathFor(ContractData c, ReportMeasurementData m) =>
      'contracts/${c.id}/measurements/${m.idReportMeasurement}/${fileName(c, m)}';

  // ---------- Operações principais ----------
  Future<bool> exists(ContractData c, ReportMeasurementData m) async {
    try {
      await _storage.ref(pathFor(c, m)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl(ContractData c, ReportMeasurementData m) async {
    try {
      return await _storage.ref(pathFor(c, m)).getDownloadURL();
    } catch (e) {
      debugPrint('ReportsStorageBloc.getUrl erro: $e');
      return null;
    }
  }

  /// Upload via seletor (Web/desktop). Retorna URL https.
  Future<String> uploadWithPicker({
    required ContractData contract,
    required ReportMeasurementData reportMeasurement,
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
      measurement: reportMeasurement,
      bytes: result.files.single.bytes!,
      onProgress: onProgress,
    );
  }

  /// Upload a partir de bytes; retorna URL https.
  Future<String> uploadBytes({
    required ContractData contract,
    required ReportMeasurementData measurement,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(pathFor(contract, measurement));
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

  Future<bool> delete(ContractData c, ReportMeasurementData m) async {
    try {
      await _storage.ref(pathFor(c, m)).delete();
      return true;
    } catch (e) {
      debugPrint('ReportsStorageBloc.delete erro: $e');
      return false;
    }
  }

  // ---------- Compat (mantém API antiga da UI) ----------
  Future<bool> verificarSePdfDeMedicaoExiste({
    required ContractData contract,
    required ReportMeasurementData measurement,
  }) => exists(contract, measurement);

  Future<String?> getPdfUrlDaMedicao({
    required ContractData contract,
    required ReportMeasurementData measurement,
  }) => getUrl(contract, measurement);

  Future<void> sendPdf({
    required ContractData? contract,
    required ReportMeasurementData? measurement,
    required void Function(double) onProgress,
    Future<void> Function(String url)? onUploaded,
  }) async {
    final c = contract;
    final m = measurement;
    if (c == null) throw Exception('Contrato nulo ao enviar PDF da medição.');
    if (m == null) throw Exception('Medição nula ao enviar PDF.');
    if (c.id == null) throw Exception('ContractData sem id.');
    if (m.idReportMeasurement == null) {
      throw Exception('ReportMeasurementData sem idReportMeasurement.');
    }

    final url = await uploadWithPicker(
      contract: c,
      reportMeasurement: m,
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
  Future<void> salvarUrlPdfDaReportMeasurement({
    required String contractId,
    required String reportMeasuremnetId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('orders')
          .doc(reportMeasuremnetId)
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
