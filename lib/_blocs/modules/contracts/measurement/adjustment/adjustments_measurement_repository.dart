import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';

class AdjustmentMeasurementRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  AdjustmentMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection(
        AdjustmentMeasurementData.collectionName,
      );

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsOfContract({
    required String uidContract,
  }) async {
    final qs = await _col(uidContract).orderBy('order').get();
    return qs.docs.map((d) => AdjustmentMeasurementData.fromDocument(d)).toList();
  }

  Future<void> saveOrUpdateAdjustment({
    required String contractId,
    required AdjustmentMeasurementData adj,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final docId = adj.id?.isNotEmpty == true ? adj.id! : _col(contractId).doc().id;
    final docRef = _col(contractId).doc(docId);

    final data = adj
        .copyWith(
      id: docId,
      contractId: contractId,
    )
        .toFirestore()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
        'contractId': contractId,
      });

    final existing = await docRef.get();
    if (!existing.exists || existing.data()?['createdAt'] == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = user?.uid ?? '';
    }

    await docRef.set(data, SetOptions(merge: true));
    await _recalcularFinancialPercentage(contractId);
  }

  Future<void> deleteAdjustment({
    required String contractId,
    required String adjustmentId,
  }) async {
    await _col(contractId).doc(adjustmentId).delete();
    await _recalcularFinancialPercentage(contractId);
  }

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double total = 0.0;

    final reps = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('reportsMeasurement')
        .get();
    for (final d in reps.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final adjs = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('adjustmentsMeasurement')
        .get();
    for (final d in adjs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final revs = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('revisionsMeasurement')
        .get();
    for (final d in revs.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final c = await _db.collection('contracts').doc(contractId).get();
    final initialValue = (c.data()?['initialContractValue'] ?? 0);
    final baseInicial = (initialValue is num) ? initialValue.toDouble() : 0.0;

    final adds = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();
    double totAdd = 0.0;
    for (final a in adds.docs) {
      final v = (a.data()['additiveValue'] ?? 0);
      totAdd += (v is num) ? v.toDouble() : 0;
    }

    final apos = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();
    double totApo = 0.0;
    for (final ap in apos.docs) {
      final v = (ap.data()['apostilleValue'] ?? 0);
      totApo += (v is num) ? v.toDouble() : 0;
    }

    final totalBase = baseInicial + totAdd + totApo;
    final percent = totalBase > 0 ? (total / totalBase) * 100.0 : 0.0;

    await _db.collection('contracts').doc(contractId).set({
      'financialPercentage': percent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> salvarUrlPdfDaAdjustmentMeasurement({
    required String contractId,
    required String adjustmentId,
    required String url,
  }) async {
    await _col(contractId).doc(adjustmentId).set(
      {
        'pdfUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setAttachments({
    required String contractId,
    required String adjustmentId,
    required List<Attachment> attachments,
  }) async {
    await _col(contractId).doc(adjustmentId).set(
      {
        'attachments': attachments.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );
  }

  // =====================================================
  // Storage – multi-anexos
  // =====================================================

  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String fileName(
      ProcessData c,
      AdjustmentMeasurementData a, {
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(
      extrato?.numeroContrato?.trim().isNotEmpty == true
          ? extrato!.numeroContrato!
          : 'contrato',
    );
    final ordem = (a.order ?? 0).toString();
    final proc = _sanitize(a.numberprocess ?? 'processo');
    return 'adjustment-$contrato-$ordem-$proc.pdf';
  }

  String pathFor({
    required ProcessData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) =>
      'contracts/${contract.id}/measurements/$measurementId/${fileName(contract, adj, extrato: extrato)}';

  String attachmentsDir(ProcessData c, AdjustmentMeasurementData a) =>
      'contracts/${c.id}/measurements/${a.id}/attachments';

  String _extFromName(String name) {
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
        .firstMatch(name.trim());
    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final rnd = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(original);
    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required AdjustmentMeasurementData adjustment,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = attachmentsDir(contract, adjustment);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _extFromName(originalName) == '.pdf'
            ? 'application/pdf'
            : 'application/octet-stream',
        customMetadata: {'originalName': originalName},
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) {
          onProgress(e.bytesTransferred / e.totalBytes);
        }
      });
    }

    await task;
    final url = await ref.getDownloadURL();
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

  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
  }

  // =====================================================
  // ✅ NOVO: rename persistido (só Firestore)
  // =====================================================
  Future<void> renameAttachmentLabel({
    required String contractId,
    required String adjustmentId,
    required List<Attachment> attachments,
  }) async {
    await setAttachments(
      contractId: contractId,
      adjustmentId: adjustmentId,
      attachments: attachments,
    );
  }

  // =====================================================
  // ✅ NOVO: delete real (Storage + Firestore)
  // =====================================================
  Future<void> deleteAttachment({
    required String contractId,
    required String adjustmentId,
    required Attachment attachment,
    required List<Attachment> nextAttachments,
  }) async {
    if (attachment.path.isNotEmpty) {
      await deleteStorageByPath(attachment.path);
    }
    await setAttachments(
      contractId: contractId,
      adjustmentId: adjustmentId,
      attachments: nextAttachments,
    );
  }

  // =====================================================
  // CollectionGroup / dashboards
  // =====================================================

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsCollectionGroup() async {
    final qs = await _db.collectionGroup(AdjustmentMeasurementData.collectionName).get();

    return qs.docs
        .map((d) => AdjustmentMeasurementData.fromDocument(d))
        .toList();
  }

  double sumAdjustments(List<AdjustmentMeasurementData> items) {
    double total = 0.0;
    for (final i in items) {
      total += (i.value ?? 0.0);
    }
    return total;
  }

  // ======= API legado (PDF único) =======
  Future<bool> exists({
    required ProcessData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      await _storage
          .ref(
        pathFor(
          contract: contract,
          measurementId: measurementId,
          adj: adj,
          extrato: extrato,
        ),
      )
          .getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl({
    required ProcessData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      return await _storage
          .ref(
        pathFor(
          contract: contract,
          measurementId: measurementId,
          adj: adj,
          extrato: extrato,
        ),
      )
          .getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ProcessData contract,
    required String adjustmentId,
    required AdjustmentMeasurementData adj,
    required void Function(double progress) onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
    }
    final ref = _storage.ref(
      pathFor(
        contract: contract,
        measurementId: adjustmentId,
        adj: adj,
        extrato: extrato,
      ),
    );
    final task = ref.putData(
      result.files.single.bytes!,
      SettableMetadata(contentType: 'application/pdf'),
    );
    task.snapshotEvents.listen((e) {
      if (e.totalBytes > 0) {
        onProgress(e.bytesTransferred / e.totalBytes);
      }
    });
    await task;
    return await ref.getDownloadURL();
  }

  Future<bool> delete({
    required ProcessData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      await _storage
          .ref(
        pathFor(
          contract: contract,
          measurementId: measurementId,
          adj: adj,
          extrato: extrato,
        ),
      )
          .delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> salvarUrlPdfDoAdjustment({
    required String contractId,
    required String adjustmentId,
    required String url,
  }) async {
    try {
      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(adjustmentId)
          .update({
        'pdfUrlAdjustment': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (_) {}
  }
}
