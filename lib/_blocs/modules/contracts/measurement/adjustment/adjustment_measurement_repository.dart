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
  AdjustmentMeasurementRepository({
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
        .collection(AdjustmentMeasurementData.collectionName);
  }

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsOfContract({
    required String uidContract,
  }) async {
    final qs = await _col(uidContract).orderBy('order').get();

    return qs.docs.map(AdjustmentMeasurementData.fromDocument).toList();
  }

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsCollectionGroup() async {
    final qs = await _db
        .collectionGroup(AdjustmentMeasurementData.collectionName)
        .get();

    return qs.docs.map(AdjustmentMeasurementData.fromDocument).toList();
  }

  Future<void> saveOrUpdateAdjustment({
    required String contractId,
    required AdjustmentMeasurementData adj,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar reajuste.');
    }

    final user = _auth.currentUser;

    final docId = adj.id?.trim().isNotEmpty == true
        ? adj.id!.trim()
        : _col(cleanContractId).doc().id;

    final docRef = _col(cleanContractId).doc(docId);

    final existing = await docRef.get();

    final data = adj
        .copyWith(
      id: docId,
      contractId: cleanContractId,
    )
        .toFirestore()
      ..addAll({
        'id': docId,
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

  Future<void> deleteAdjustment({
    required String contractId,
    required String adjustmentId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) return;

    final docRef = _col(cleanContractId).doc(cleanAdjustmentId);
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
        'contracts/$cleanContractId/${AdjustmentMeasurementData.collectionName}/$cleanAdjustmentId/attachments',
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
    final cleanUrl = url.trim();

    await _col(contractId).doc(adjustmentId).set(
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
    required String adjustmentId,
    required List<Attachment> attachments,
  }) async {
    await _col(contractId).doc(adjustmentId).set(
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

  String fileName(
      ProcessData contract,
      AdjustmentMeasurementData adjustment, {
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(
      extrato?.numeroContrato?.trim().isNotEmpty == true
          ? extrato!.numeroContrato!
          : 'contrato',
    );

    final ordem = (adjustment.order ?? 0).toString();
    final processo = _sanitize(adjustment.numberprocess ?? 'processo');

    return 'adjustment-$contrato-$ordem-$processo.pdf';
  }

  String pathFor({
    required ProcessData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) {
    return 'contracts/${contract.id}/measurements/$measurementId/${fileName(contract, adj, extrato: extrato)}';
  }

  String attachmentsDir(ProcessData contract, AdjustmentMeasurementData adjustment) {
    if (contract.id == null || contract.id!.trim().isEmpty) {
      throw Exception('contract.id é obrigatório para anexos de reajuste.');
    }

    if (adjustment.id == null || adjustment.id!.trim().isEmpty) {
      throw Exception('adjustment.id é obrigatório para anexos de reajuste.');
    }

    return 'contracts/${contract.id}/${AdjustmentMeasurementData.collectionName}/${adjustment.id}/attachments';
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
          'adjustmentId': adjustment.id ?? '',
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

  Future<void> deleteAttachment({
    required String contractId,
    required String adjustmentId,
    required Attachment attachment,
    required List<Attachment> nextAttachments,
  }) async {
    if (attachment.path.trim().isNotEmpty) {
      await deleteStorageByPath(attachment.path);
    }

    await setAttachments(
      contractId: contractId,
      adjustmentId: adjustmentId,
      attachments: nextAttachments,
    );
  }

  double sumAdjustments(List<AdjustmentMeasurementData> items) {
    double total = 0.0;

    for (final item in items) {
      total += item.value ?? 0.0;
    }

    return total;
  }

  // ---------------------------------------------------------------------------
  // API legado - PDF único
  // ---------------------------------------------------------------------------

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
      allowedExtensions: const ['pdf'],
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

    task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress(event.bytesTransferred / event.totalBytes);
      }
    });

    await task;

    return ref.getDownloadURL();
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
      await _col(contractId).doc(adjustmentId).set(
        {
          'pdfUrlAdjustment': url.trim().isEmpty ? FieldValue.delete() : url,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}