// lib/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'tr_data.dart';

class TrRepository {
  TrRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required String tenantId,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = _validateTenantId(tenantId);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String _tenantId;

  String get tenantId => _tenantId;

  static String _validateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para TrRepository.');
    }

    return cleanTenantId;
  }

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId não informado.');
    }

    return _contractsCol().doc(cleanContractId);
  }

  DocumentReference<Map<String, dynamic>> _hiringMainDoc(String contractId) {
    return _contractDoc(contractId).collection('hiring').doc('main');
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId não informado.');
    }

    return _hiringMainDoc(cleanContractId).collection('tr');
  }

  String _filesPath({
    required String contractId,
    required String trId,
    required String documentosId,
  }) {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw ArgumentError('trId não informado.');
    }

    if (cleanDocumentosId.isEmpty) {
      throw ArgumentError('documentosId não informado.');
    }

    return 'tenants/$tenantId/contracts/$cleanContractId/hiring/main/tr/$cleanTrId/documentosReferencias/$cleanDocumentosId/files';
  }

  String _extractExt(String nameOrUrl) {
    final clean = nameOrUrl.trim();
    final queryFree = clean.split('?').first.split('#').first;
    final index = queryFree.lastIndexOf('.');

    if (index <= 0 || index == queryFree.length - 1) return '';

    return queryFree.substring(index + 1).toLowerCase();
  }

  String _contentTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _ensureContractParent(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    await _contractDoc(cleanContractId).set(
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _ensureHiringMain(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    await _ensureContractParent(cleanContractId);

    await _hiringMainDoc(cleanContractId).set(
      <String, dynamic>{
        'id': 'main',
        'module': 'hiring',
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<({String trId, Map<String, String> sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    await _ensureHiringMain(id);

    final sectionIds = <String, String>{
      for (final section in TrData.sectionKeys) section: 'main',
    };

    return (trId: 'main', sectionIds: sectionIds);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String trId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw Exception('trId não informado.');
    }

    final trRef = _col(cleanContractId).doc(cleanTrId);

    final entries = await Future.wait(
      sectionIds.entries.map((entry) async {
        final sectionName = entry.key.trim();
        final sectionDocId = entry.value.trim();

        if (sectionName.isEmpty || sectionDocId.isEmpty) {
          return MapEntry<String, Map<String, dynamic>>(
            sectionName,
            <String, dynamic>{},
          );
        }

        final snap = await trRef.collection(sectionName).doc(sectionDocId).get();

        final data = Map<String, dynamic>.from(
          snap.data() ?? const <String, dynamic>{},
        );

        _removeSystemFields(data);

        return MapEntry<String, Map<String, dynamic>>(
          sectionName,
          data,
        );
      }),
    );

    return <String, Map<String, dynamic>>{
      for (final entry in entries)
        if (entry.key.trim().isNotEmpty) entry.key: entry.value,
    };
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String trId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw Exception('trId não informado.');
    }

    if (sectionsData.isEmpty) return;

    await _ensureHiringMain(cleanContractId);

    final trRef = _col(cleanContractId).doc(cleanTrId);
    final batch = _db.batch();

    batch.set(
      _contractDoc(cleanContractId),
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _hiringMainDoc(cleanContractId),
      <String, dynamic>{
        'id': 'main',
        'module': 'hiring',
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      trRef,
      <String, dynamic>{
        'id': cleanTrId,
        'module': 'hiring',
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key.trim();
      final sectionData = Map<String, dynamic>.from(entry.value);
      final sectionDocId = sectionIds[sectionKey]?.trim();

      if (sectionKey.isEmpty) continue;
      if (sectionDocId == null || sectionDocId.isEmpty) continue;

      _removeWriteProtectedFields(sectionData);

      final ref = trRef.collection(sectionKey).doc(sectionDocId);

      batch.set(
        ref,
        <String, dynamic>{
          ...sectionData,
          'id': sectionDocId,
          'module': 'hiring',
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> saveSection({
    required String contractId,
    required String trId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw Exception('trId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    await _ensureHiringMain(cleanContractId);

    final cleanData = Map<String, dynamic>.from(data);
    _removeWriteProtectedFields(cleanData);

    final trRef = _col(cleanContractId).doc(cleanTrId);
    final batch = _db.batch();

    batch.set(
      _contractDoc(cleanContractId),
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _hiringMainDoc(cleanContractId),
      <String, dynamic>{
        'id': 'main',
        'module': 'hiring',
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      trRef,
      <String, dynamic>{
        'id': cleanTrId,
        'module': 'hiring',
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final ref = trRef.collection(cleanSectionKey).doc(cleanSectionDocId);

    batch.set(
      ref,
      <String, dynamic>{
        ...cleanData,
        'id': cleanSectionDocId,
        'module': 'hiring',
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<TrData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      trId: ids.trId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return TrData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listAttachments({
    required String contractId,
    required String trId,
    required String documentosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty ||
        cleanTrId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = _storage.ref(
      _filesPath(
        contractId: cleanContractId,
        trId: cleanTrId,
        documentosId: cleanDocumentosId,
      ),
    );

    final result = await ref.listAll();

    final attachments = await Future.wait(
      result.items.map((item) async {
        final url = await item.getDownloadURL();
        final metadata = await item.getMetadata();
        final ext = _extractExt(item.name);

        return Attachment(
          id: item.name,
          label: item.name,
          url: url,
          path: item.fullPath,
          ext: ext,
          size: metadata.size?.toInt(),
        );
      }),
    );

    attachments.sort((a, b) => a.label.compareTo(b.label));

    return attachments;
  }

  Future<Attachment> uploadAttachment({
    required String contractId,
    required String trId,
    required String documentosId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
    ],
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty ||
        cleanTrId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload do TR.');
    }

    await _ensureHiringMain(cleanContractId);

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado.');
    }

    final file = picked.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Falha ao ler os bytes do arquivo.');
    }

    final name = file.name.trim();

    if (name.isEmpty) {
      throw Exception('Nome do arquivo inválido.');
    }

    final ext = _extractExt(name);

    final ref = _storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        trId: cleanTrId,
        documentosId: cleanDocumentosId,
      )}/$name',
    );

    final upload = ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
        customMetadata: <String, String>{
          'originalName': name,
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'trId': cleanTrId,
          'documentosId': cleanDocumentosId,
          'module': 'hiring',
        },
      ),
    );

    upload.snapshotEvents.listen((event) {
      final total = event.totalBytes == 0 ? 1 : event.totalBytes;
      onProgress(event.bytesTransferred / total);
    });

    final snap = await upload;
    final url = await snap.ref.getDownloadURL();
    final metadata = await snap.ref.getMetadata();

    return Attachment(
      id: snap.ref.name,
      label: name,
      url: url,
      path: snap.ref.fullPath,
      ext: ext,
      size: metadata.size?.toInt(),
    );
  }

  Future<bool> deleteAttachment({
    required String contractId,
    required String trId,
    required String documentosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();
    final cleanDocumentosId = documentosId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanTrId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = _storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          trId: cleanTrId,
          documentosId: cleanDocumentosId,
        )}/$cleanFileName',
      );

      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAttachmentByPath(String path) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) return false;

    try {
      await _storage.ref(cleanPath).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _removeWriteProtectedFields(Map<String, dynamic> data) {
    data.remove('createdAt');
    data.remove('updatedAt');
    data.remove('createdBy');
    data.remove('updatedBy');
  }

  void _removeSystemFields(Map<String, dynamic> data) {
    _removeWriteProtectedFields(data);
    data.remove('migratedAt');
    data.remove('migrationSourcePath');
    data.remove('migrationSourceDocId');
    data.remove('migrationTargetPath');
    data.remove('legacySourceId');
    data.remove('legacySourcePath');
    data.remove('recordPath');
    data.remove('sourcePath');
    data.remove('path');
    data.remove('sourceCollectionModel');
    data.remove('tenantId');
    data.remove('companyId');
    data.remove('uidContract');
    data.remove('uidcontract');
    data.remove('contractId');
    data.remove('module');
  }
}