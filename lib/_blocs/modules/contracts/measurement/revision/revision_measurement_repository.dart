import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'revision_measurement_data.dart';

class RevisionMeasurementRepository {
  RevisionMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db
        .collection('contracts')
        .doc(contractId)
        .collection(RevisionMeasurementData.collectionName);
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsOfContract({
    required String uidContract,
  }) async {
    final qs = await _col(uidContract).orderBy('order').get();

    return qs.docs.map(RevisionMeasurementData.fromDocument).toList();
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() async {
    final qs = await _db
        .collectionGroup(RevisionMeasurementData.collectionName)
        .get();

    return qs.docs.map(RevisionMeasurementData.fromDocument).toList();
  }

  Future<void> saveOrUpdateRevision({
    required String contractId,
    required String revisionMeasurementId,
    required RevisionMeasurementData rev,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionMeasurementId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar revisão.');
    }

    if (cleanRevisionId.isEmpty) {
      throw Exception('revisionMeasurementId é obrigatório para salvar revisão.');
    }

    final user = _auth.currentUser;
    final docRef = _col(cleanContractId).doc(cleanRevisionId);

    final existing = await docRef.get();

    final data = rev
        .copyWith(
      id: cleanRevisionId,
      contractId: cleanContractId,
    )
        .toFirestore()
      ..addAll({
        'id': cleanRevisionId,
        'contractId': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
      });

    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = user?.uid ?? '';
    } else {
      data.remove('createdAt');
      data.remove('createdBy');
    }

    await docRef.set(data, SetOptions(merge: true));

    await _recalcularFinancialPercentage(cleanContractId);
  }

  Future<void> deleteRevision({
    required String contractId,
    required String revisionId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) return;

    final docRef = _col(cleanContractId).doc(cleanRevisionId);
    final snap = await docRef.get();
    final data = snap.data();

    if (data != null) {
      final raw = data['attachments'];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final att = Attachment.fromMap(Map<String, dynamic>.from(item));

            if (att.path.trim().isNotEmpty) {
              await deleteStorageByPath(att.path);
            }
          }
        }
      }
    }

    try {
      final folder = _storage.ref(
        'contracts/$cleanContractId/${RevisionMeasurementData.collectionName}/$cleanRevisionId/attachments',
      );

      final list = await folder.listAll();

      for (final item in list.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await docRef.delete();

    await _recalcularFinancialPercentage(cleanContractId);
  }

  Future<void> salvarUrlPdfDaRevisionMeasurement({
    required String contractId,
    required String revisionMeasurementId,
    required String url,
  }) async {
    final cleanUrl = url.trim();

    await _col(contractId).doc(revisionMeasurementId).set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setAttachments({
    required String contractId,
    required String revisionId,
    required List<Attachment> attachments,
  }) async {
    await _col(contractId).doc(revisionId).set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Storage - anexos
  // ---------------------------------------------------------------------------

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');
  }

  String _extFromName(String name) {
    final match = RegExp(
      r'\.([a-z0-9]+)$',
      caseSensitive: false,
    ).firstMatch(name.trim());

    return match == null ? '' : '.${match.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    var value = name.trim();

    final queryIndex = value.indexOf('?');
    if (queryIndex != -1) {
      value = value.substring(0, queryIndex);
    }

    final hashIndex = value.indexOf('#');
    if (hashIndex != -1) {
      value = value.substring(0, hashIndex);
    }

    value = value.split('/').last;

    return value.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final random = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(original);

    return '$base-$random${ext.isEmpty ? ".bin" : ext}';
  }

  /// Pasta dos anexos da revisão.
  /// Padrão:
  /// contracts/{contractId}/revisionsMeasurement/{revisionId}/attachments/{file}
  String attachmentsDir(ProcessData contract, RevisionMeasurementData revision) {
    if (contract.id == null || contract.id!.trim().isEmpty) {
      throw Exception('contract.id é obrigatório para anexos de revisão.');
    }

    if (revision.id == null || revision.id!.trim().isEmpty) {
      throw Exception('revision.id é obrigatório para anexos de revisão.');
    }

    return 'contracts/${contract.id}/${RevisionMeasurementData.collectionName}/${revision.id}/attachments';
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
    required RevisionMeasurementData revision,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = attachmentsDir(contract, revision);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final ext = _extFromName(originalName);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: ext == '.pdf'
            ? 'application/pdf'
            : 'application/octet-stream',
        customMetadata: {
          'originalName': originalName,
          'contractId': contract.id ?? '',
          'revisionId': revision.id ?? '',
        },
      ),
    );

    task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress?.call(event.bytesTransferred / event.totalBytes);
      }
    });

    await task;

    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();

    return Attachment(
      id: ref.name,
      label: label.trim().isEmpty ? _baseName(originalName) : label.trim(),
      url: url,
      path: ref.fullPath,
      ext: ext,
      size: meta.size?.toInt(),
      createdAt: DateTime.now(),
      createdBy: _auth.currentUser?.uid,
    );
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    if (storagePath.trim().isEmpty) return;

    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Percentual financeiro
  // ---------------------------------------------------------------------------

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double total = 0.0;

    final reps = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('reportsMeasurement')
        .get();

    for (final doc in reps.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final adjs = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('adjustmentsMeasurement')
        .get();

    for (final doc in adjs.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final revs = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('revisionsMeasurement')
        .get();

    for (final doc in revs.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final contractSnap = await _db.collection('contracts').doc(contractId).get();
    final initialValue = contractSnap.data()?['initialContractValue'];
    final baseInicial = initialValue is num ? initialValue.toDouble() : 0.0;

    final adds = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();

    double totalAditivos = 0.0;

    for (final doc in adds.docs) {
      final value = doc.data()['additiveValue'];
      totalAditivos += value is num ? value.toDouble() : 0.0;
    }

    final apos = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();

    double totalApostilas = 0.0;

    for (final doc in apos.docs) {
      final value = doc.data()['apostilleValue'];
      totalApostilas += value is num ? value.toDouble() : 0.0;
    }

    final totalBase = baseInicial + totalAditivos + totalApostilas;

    final percent = totalBase > 0 ? (total / totalBase) * 100.0 : 0.0;

    await _db.collection('contracts').doc(contractId).set(
      {
        'financialPercentage': percent,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  double sumRevisions(List<RevisionMeasurementData> items) {
    double total = 0.0;

    for (final item in items) {
      total += item.value ?? 0.0;
    }

    return total;
  }
}