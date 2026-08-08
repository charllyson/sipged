import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'dotacao_data.dart';

class DotacaoRepository {
  DotacaoRepository({
    required String tenantId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = tenantId.trim() {
    if (_tenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em DotacaoRepository.');
    }
  }

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String _tenantId;

  String get tenantId => _tenantId;

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _hiringRef(String contractId) {
    return _contractsCol().doc(contractId).collection('hiring').doc('main');
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _hiringRef(contractId).collection('dotacao');
  }

  String _filesPath({
    required String contractId,
    required String dotacaoId,
    required String documentosId,
  }) {
    return 'tenants/$tenantId/contracts/$contractId/hiring/main/dotacao/$dotacaoId/${DotacaoData.sectionDocumentos}/$documentosId/files';
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

  Future<({String dotacaoId, Map<String, String> sectionIds})>
  ensureStructure(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in DotacaoData.sectionKeys) section: 'main',
    };

    return (dotacaoId: 'main', sectionIds: sectionIds);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String dotacaoId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = dotacaoId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanDotacaoId.isEmpty) {
      throw Exception('dotacaoId não informado.');
    }

    final root = _col(cleanContractId).doc(cleanDotacaoId);

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

        final snap = await root.collection(sectionName).doc(sectionDocId).get();

        final data = Map<String, dynamic>.from(
          snap.data() ?? const <String, dynamic>{},
        );

        _removeSystemFields(data);

        return MapEntry<String, Map<String, dynamic>>(sectionName, data);
      }),
    );

    return <String, Map<String, dynamic>>{
      for (final entry in entries)
        if (entry.key.trim().isNotEmpty) entry.key: entry.value,
    };
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String dotacaoId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = dotacaoId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanDotacaoId.isEmpty) {
      throw Exception('dotacaoId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final root = _col(cleanContractId).doc(cleanDotacaoId);
    final hiringRef = _hiringRef(cleanContractId);

    final batch = _db.batch();

    batch.set(
      hiringRef,
      <String, dynamic>{
        'id': 'main',
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
      root,
      <String, dynamic>{
        'id': cleanDotacaoId,
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
      final sectionDocId = sectionIds[sectionKey]?.trim();

      if (sectionKey.isEmpty) continue;
      if (sectionDocId == null || sectionDocId.isEmpty) continue;

      final sectionData = Map<String, dynamic>.from(entry.value);
      _removeWriteProtectedFields(sectionData);

      batch.set(
        root.collection(sectionKey).doc(sectionDocId),
        <String, dynamic>{
          ...sectionData,
          'id': sectionDocId,
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
    required String dotacaoId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = dotacaoId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanDotacaoId.isEmpty) {
      throw Exception('dotacaoId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final cleanData = Map<String, dynamic>.from(data);
    _removeWriteProtectedFields(cleanData);

    final root = _col(cleanContractId).doc(cleanDotacaoId);
    final hiringRef = _hiringRef(cleanContractId);

    final batch = _db.batch();

    batch.set(
      hiringRef,
      <String, dynamic>{
        'id': 'main',
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
      root,
      <String, dynamic>{
        'id': cleanDotacaoId,
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
      root.collection(cleanSectionKey).doc(cleanSectionDocId),
      <String, dynamic>{
        ...cleanData,
        'id': cleanSectionDocId,
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

  Future<DotacaoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      dotacaoId: ids.dotacaoId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return DotacaoData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listFiles({
    required String contractId,
    required String dotacaoId,
    required String documentosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = dotacaoId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = _storage.ref(
      _filesPath(
        contractId: cleanContractId,
        dotacaoId: cleanDotacaoId,
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

  Future<Attachment> uploadFile({
    required String contractId,
    required String dotacaoId,
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
    final picked = await FilePicker.pickFiles(
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

    return uploadBytes(
      contractId: contractId,
      dotacaoId: dotacaoId,
      documentosId: documentosId,
      bytes: Uint8List.fromList(bytes),
      fileName: file.name,
      onProgress: onProgress,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    required String dotacaoId,
    required String documentosId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = dotacaoId.trim();
    final cleanDocumentosId = documentosId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        cleanFileName.isEmpty) {
      throw Exception('Caminho inválido para upload da dotação.');
    }

    if (bytes.isEmpty) {
      throw Exception('Bytes do arquivo vazios.');
    }

    final ext = _extractExt(cleanFileName);

    final ref = _storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        dotacaoId: cleanDotacaoId,
        documentosId: cleanDocumentosId,
      )}/$cleanFileName',
    );

    final task = ref.putData(
      bytes,
      metadata ??
          SettableMetadata(
            contentType: _contentTypeForExt(ext),
            customMetadata: <String, String>{
              'originalName': cleanFileName,
              'tenantId': tenantId,
              'companyId': tenantId,
              'contractId': cleanContractId,
              'dotacaoId': cleanDotacaoId,
              'documentosId': cleanDocumentosId,
            },
          ),
    );

    task.snapshotEvents.listen((event) {
      final total = event.totalBytes == 0 ? 1 : event.totalBytes;
      onProgress(event.bytesTransferred / total);
    });

    final snap = await task;
    final url = await snap.ref.getDownloadURL();
    final fileMetadata = await snap.ref.getMetadata();

    return Attachment(
      id: snap.ref.name,
      label: cleanFileName,
      url: url,
      path: snap.ref.fullPath,
      ext: ext,
      size: fileMetadata.size?.toInt(),
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    required String dotacaoId,
    required String documentosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = dotacaoId.trim();
    final cleanDocumentosId = documentosId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      await _storage
          .ref(
        '${_filesPath(
          contractId: cleanContractId,
          dotacaoId: cleanDotacaoId,
          documentosId: cleanDocumentosId,
        )}/$cleanFileName',
      )
          .delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteByPath(String path) async {
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
  }
}