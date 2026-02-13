import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'revision_measurement_data.dart';

class RevisionMeasurementRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  RevisionMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection(
        RevisionMeasurementData.collectionName,
      );

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  Future<List<RevisionMeasurementData>> getAllRevisionsOfContract({
    required String uidContract,
  }) async {
    final qs = await _col(uidContract).orderBy('order').get();
    return qs.docs.map((d) => RevisionMeasurementData.fromDocument(d)).toList();
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() async {
    final qs = await _db.collectionGroup(RevisionMeasurementData.collectionName).get();
    return qs.docs.map((d) => RevisionMeasurementData.fromDocument(d)).toList();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdateRevision({
    required String contractId,
    required String revisionMeasurementId,
    required RevisionMeasurementData rev,
  }) async {
    final user = _auth.currentUser;
    final docRef = _col(contractId).doc(revisionMeasurementId);

    rev.id ??= revisionMeasurementId;

    final data = rev.toFirestore()
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

  Future<void> deleteRevision({
    required String contractId,
    required String revisionId,
  }) async {
    await _col(contractId).doc(revisionId).delete();
    await _recalcularFinancialPercentage(contractId);
  }

  // ---------------------------------------------------------------------------
  // Metadados (legado)
  // ---------------------------------------------------------------------------

  Future<void> salvarUrlPdfDaRevisionMeasurement({
    required String contractId,
    required String revisionMeasurementId,
    required String url,
  }) async {
    await _col(contractId).doc(revisionMeasurementId).update({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    });
  }

  // ---------------------------------------------------------------------------
  // Attachments (Firestore)
  // ---------------------------------------------------------------------------

  Future<void> setAttachments({
    required String contractId,
    required String revisionId,
    required List<Attachment> attachments,
  }) async {
    await _col(contractId).doc(revisionId).set(
      {
        'attachments': attachments.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Storage – multi-anexos (igual Adjustment)
  // ---------------------------------------------------------------------------

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String _extFromName(String name) {
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(name.trim());
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

  /// Pasta dos anexos da revisão.
  /// Padrão: contracts/{contractId}/revisionsMeasurement/{revisionId}/attachments/{file}
  String attachmentsDir(ProcessData c, RevisionMeasurementData r) =>
      'contracts/${c.id}/revisionsMeasurement/${r.id}/attachments';

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required RevisionMeasurementData revision,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    if (revision.id == null || revision.id!.trim().isEmpty) {
      throw Exception('revision.id é obrigatório para anexos.');
    }

    final dir = attachmentsDir(contract, revision);
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
      createdBy: _auth.currentUser?.uid,
    );
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // % financeiro (mesmo cálculo)
  // ---------------------------------------------------------------------------

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

    await _db.collection('contracts').doc(contractId).set(
      {
        'financialPercentage': percent,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Totais
  // ---------------------------------------------------------------------------

  double sumRevisions(List<RevisionMeasurementData> items) {
    double total = 0.0;
    for (final i in items) {
      total += (i.value ?? 0.0);
    }
    return total;
  }
}
