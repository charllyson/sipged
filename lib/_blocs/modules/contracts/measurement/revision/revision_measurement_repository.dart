// lib/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'revision_measurement_data.dart';

class RevisionMeasurementRepository {
  RevisionMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    String? tenantId,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = _cleanTenantId(tenantId);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? _tenantId;

  static String? _cleanTenantId(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  String get tenantId {
    final clean = _tenantId?.trim();

    if (clean == null || clean.isEmpty) {
      throw StateError(
        'tenantId não definido em RevisionMeasurementRepository. '
            'Selecione uma empresa antes de acessar revisões.',
      );
    }

    return clean;
  }

  String? get currentTenantId => _cleanTenantId(_tenantId);

  bool get hasTenant => currentTenantId != null;

  void setActiveTenantId(String? value) {
    final next = _cleanTenantId(value);

    if (_tenantId == next) return;

    _tenantId = next;
  }

  String get tenantContractsCollectionPath {
    return 'tenants/$tenantId/contracts';
  }

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection(tenantContractsCollectionPath);
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    return _contractsCol().doc(contractId.trim());
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _contractDoc(contractId).collection(
      RevisionMeasurementData.collectionName,
    );
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String revisionId,
  }) {
    return _col(contractId).doc(revisionId.trim());
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  bool _isTenantRevisionPath(String path) {
    final parts = path
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length < 6) return false;

    return parts[0] == 'tenants' &&
        parts[1] == tenantId &&
        parts[2] == 'contracts' &&
        parts[4] == RevisionMeasurementData.collectionName;
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsOfContract({
    required String uidContract,
  }) async {
    if (!hasTenant) return const <RevisionMeasurementData>[];

    final contractId = uidContract.trim();

    if (contractId.isEmpty) return const <RevisionMeasurementData>[];

    QuerySnapshot<Map<String, dynamic>> query;

    try {
      query = await _col(contractId).orderBy('order').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        query = await _col(contractId).get();
      } else {
        rethrow;
      }
    }

    final list = query.docs.map(RevisionMeasurementData.fromDocument).toList();

    list.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return list;
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() async {
    if (!hasTenant) return const <RevisionMeasurementData>[];

    QuerySnapshot<Map<String, dynamic>> query;

    try {
      query = await _db
          .collectionGroup(RevisionMeasurementData.collectionName)
          .where('tenantId', isEqualTo: tenantId)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        query = await _db
            .collectionGroup(RevisionMeasurementData.collectionName)
            .get();
      } else {
        rethrow;
      }
    }

    final list = query.docs
        .where((doc) => _isTenantRevisionPath(doc.reference.path))
        .map(RevisionMeasurementData.fromDocument)
        .toList();

    list.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return list;
  }

  Future<String> saveOrUpdateRevision({
    required String contractId,
    required String? revisionMeasurementId,
    required RevisionMeasurementData rev,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar revisão.');
    }

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar revisão.');
    }

    final cleanRevisionId = revisionMeasurementId?.trim();
    final docRef = cleanRevisionId == null || cleanRevisionId.isEmpty
        ? _col(cleanContractId).doc()
        : _doc(
      contractId: cleanContractId,
      revisionId: cleanRevisionId,
    );

    final revisionId = docRef.id;

    final existing = await docRef.get();

    final data = rev
        .copyWith(
      id: revisionId,
      contractId: cleanContractId,
    )
        .toFirestore()
      ..addAll({
        'id': revisionId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_contract_revisions_measurement',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      });

    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = _uid();
    } else {
      data.remove('createdAt');
      data.remove('createdBy');
    }

    await docRef.set(data, SetOptions(merge: true));

    await _recalcularFinancialPercentage(cleanContractId);

    return revisionId;
  }

  Future<void> deleteRevision({
    required String contractId,
    required String revisionId,
  }) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) return;

    final docRef = _doc(
      contractId: cleanContractId,
      revisionId: cleanRevisionId,
    );

    final snap = await docRef.get();
    final data = snap.data();

    if (data != null) {
      final raw = data['attachments'];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final attachment = Attachment.fromMap(
              Map<String, dynamic>.from(item),
            );

            if (attachment.path.trim().isNotEmpty) {
              await deleteStorageByPath(attachment.path);
            }
          }
        }
      }
    }

    try {
      final folder = _storage.ref(
        'tenants/$tenantId/contracts/$cleanContractId/'
            '${RevisionMeasurementData.collectionName}/$cleanRevisionId/attachments',
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
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar PDF da revisão.');
    }

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionMeasurementId.trim();
    final cleanUrl = url.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) return;

    final docRef = _doc(
      contractId: cleanContractId,
      revisionId: cleanRevisionId,
    );

    await docRef.set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setAttachments({
    required String contractId,
    required String revisionId,
    required List<Attachment> attachments,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar anexos da revisão.');
    }

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      throw Exception('contractId e revisionId são obrigatórios.');
    }

    final docRef = _doc(
      contractId: cleanContractId,
      revisionId: cleanRevisionId,
    );

    await docRef.set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((item) => item.toMap()).toList(),
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

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

  String attachmentsDir(
      ContractData contract,
      RevisionMeasurementData revision,
      ) {
    final contractId = contract.id?.trim();
    final revisionId = revision.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contract.id é obrigatório para anexos de revisão.');
    }

    if (revisionId == null || revisionId.isEmpty) {
      throw Exception('revision.id é obrigatório para anexos de revisão.');
    }

    return 'tenants/$tenantId/contracts/$contractId/'
        '${RevisionMeasurementData.collectionName}/$revisionId/attachments';
  }

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }

    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required RevisionMeasurementData revision,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para enviar anexo da revisão.');
    }

    final dir = attachmentsDir(contract, revision);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final ext = _extFromName(originalName);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType:
        ext == '.pdf' ? 'application/pdf' : 'application/octet-stream',
        customMetadata: {
          'tenantId': tenantId,
          'companyId': tenantId,
          'originalName': originalName,
          'contractId': contract.id ?? '',
          'revisionId': revision.id ?? '',
        },
      ),
    );

    task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        final progress = event.bytesTransferred / event.totalBytes;
        onProgress?.call(progress.clamp(0.0, 1.0));
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
      createdBy: _uid(),
    );
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return;

    try {
      await _storage.ref(cleanPath).delete();
    } catch (_) {}
  }

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return;

    double total = 0.0;

    final reportsSnapshot = await _contractDoc(cleanContractId)
        .collection('reportsMeasurement')
        .get();

    for (final doc in reportsSnapshot.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final adjustmentsSnapshot = await _contractDoc(cleanContractId)
        .collection('adjustmentsMeasurement')
        .get();

    for (final doc in adjustmentsSnapshot.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final revisionsSnapshot = await _contractDoc(cleanContractId)
        .collection(RevisionMeasurementData.collectionName)
        .get();

    for (final doc in revisionsSnapshot.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final contractSnap = await _contractDoc(cleanContractId).get();
    final initialValue = contractSnap.data()?['initialContractValue'];
    final baseInicial = initialValue is num ? initialValue.toDouble() : 0.0;

    final additivesSnapshot =
    await _contractDoc(cleanContractId).collection('additives').get();

    double totalAditivos = 0.0;

    for (final doc in additivesSnapshot.docs) {
      final value = doc.data()['additiveValue'] ?? doc.data()['additivevalue'];
      totalAditivos += value is num ? value.toDouble() : 0.0;
    }

    final apostillesSnapshot =
    await _contractDoc(cleanContractId).collection('apostilles').get();

    double totalApostilas = 0.0;

    for (final doc in apostillesSnapshot.docs) {
      final value =
          doc.data()['apostilleValue'] ?? doc.data()['apostillevalue'];
      totalApostilas += value is num ? value.toDouble() : 0.0;
    }

    final totalBase = baseInicial + totalAditivos + totalApostilas;
    final percent = totalBase > 0 ? (total / totalBase) * 100.0 : 0.0;

    await _contractDoc(cleanContractId).set(
      {
        'financialPercentage': percent,
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
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