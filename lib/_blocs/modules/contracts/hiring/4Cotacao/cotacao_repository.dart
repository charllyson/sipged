// lib/_blocs/modules/contracts/hiring/4Cotacao/cotacao_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'cotacao_data.dart';

class CotacaoRepository {
  CotacaoRepository({
    required String tenantId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = tenantId.trim() {
    if (_tenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em CotacaoRepository.');
    }
  }

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String _tenantId;

  String get tenantId => _tenantId;

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _contractsCol()
        .doc(contractId)
        .collection('hiring')
        .doc('main')
        .collection('cotacao');
  }

  String _filesPath({
    required String contractId,
    required String cotacaoId,
    required String anexosId,
  }) {
    return 'tenants/$tenantId/contracts/$contractId/hiring/main/cotacao/$cotacaoId/anexosEvidencias/$anexosId/files';
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

  Future<({String cotacaoId, Map<String, String> sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in CotacaoData.sectionKeys) section: 'main',
    };

    return (cotacaoId: 'main', sectionIds: sectionIds);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String cotacaoId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanCotacaoId.isEmpty) {
      throw Exception('cotacaoId não informado.');
    }

    final root = _col(cleanContractId).doc(cleanCotacaoId);

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
    required String cotacaoId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanCotacaoId.isEmpty) {
      throw Exception('cotacaoId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final root = _col(cleanContractId).doc(cleanCotacaoId);
    final hiringRef =
    _contractsCol().doc(cleanContractId).collection('hiring').doc('main');

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
        'id': cleanCotacaoId,
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
    required String cotacaoId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) throw Exception('contractId não informado.');
    if (cleanCotacaoId.isEmpty) throw Exception('cotacaoId não informado.');
    if (cleanSectionKey.isEmpty) throw Exception('sectionKey não informado.');
    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final cleanData = Map<String, dynamic>.from(data);
    _removeWriteProtectedFields(cleanData);

    final root = _col(cleanContractId).doc(cleanCotacaoId);
    final hiringRef =
    _contractsCol().doc(cleanContractId).collection('hiring').doc('main');

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
        'id': cleanCotacaoId,
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

  Future<CotacaoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      cotacaoId: ids.cotacaoId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return CotacaoData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listAttachments({
    required String contractId,
    required String cotacaoId,
    required String anexosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();
    final cleanAnexosId = anexosId.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty) {
      return const <Attachment>[];
    }

    final result = await _storage
        .ref(
      _filesPath(
        contractId: cleanContractId,
        cotacaoId: cleanCotacaoId,
        anexosId: cleanAnexosId,
      ),
    )
        .listAll();

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
    required String cotacaoId,
    required String anexosId,
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
    final cleanCotacaoId = cotacaoId.trim();
    final cleanAnexosId = anexosId.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty) {
      throw Exception('Caminho inválido para upload da cotação.');
    }

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
        cotacaoId: cleanCotacaoId,
        anexosId: cleanAnexosId,
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
          'cotacaoId': cleanCotacaoId,
          'anexosId': cleanAnexosId,
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
    required String cotacaoId,
    required String anexosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();
    final cleanAnexosId = anexosId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      await _storage
          .ref(
        '${_filesPath(
          contractId: cleanContractId,
          cotacaoId: cleanCotacaoId,
          anexosId: cleanAnexosId,
        )}/$cleanFileName',
      )
          .delete();

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
  }
}