// lib/_blocs/modules/contracts/hiring/10Arquivamento/termo_arquivamento_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'termo_arquivamento_data.dart';

class TermoArquivamentoRepository {
  TermoArquivamentoRepository({
    required String tenantId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _tenantId = _requireTenantId(tenantId),
        _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final String _tenantId;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const String _hiringCollectionId = 'hiring';
  static const String _mainDocId = 'main';
  static const String _arquivamentoCollectionId = 'arquivamento';

  static String _requireTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório em TermoArquivamentoRepository.',
      );
    }

    return cleanTenantId;
  }

  String get tenantId => _tenantId;

  String _requireContractId(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    return cleanContractId;
  }

  String _requireTaId(String taId) {
    final cleanTaId = taId.trim();

    if (cleanTaId.isEmpty) {
      throw Exception('taId não informado.');
    }

    return cleanTaId;
  }

  String _requireSectionKey(String sectionKey) {
    final cleanSectionKey = sectionKey.trim();

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    return cleanSectionKey;
  }

  String _requireSectionDocId(String sectionDocId) {
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    return cleanSectionDocId;
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = _requireContractId(contractId);

    return _db
        .collection('tenants')
        .doc(_tenantId)
        .collection('contracts')
        .doc(cleanContractId);
  }

  DocumentReference<Map<String, dynamic>> _hiringMainDoc(String contractId) {
    return _contractDoc(contractId)
        .collection(_hiringCollectionId)
        .doc(_mainDocId);
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _hiringMainDoc(contractId).collection(_arquivamentoCollectionId);
  }

  DocumentReference<Map<String, dynamic>> _taDoc({
    required String contractId,
    required String taId,
  }) {
    final cleanContractId = _requireContractId(contractId);
    final cleanTaId = _requireTaId(taId);

    return _col(cleanContractId).doc(cleanTaId);
  }

  DocumentReference<Map<String, dynamic>> _sectionDoc({
    required String contractId,
    required String taId,
    required String sectionKey,
    required String sectionDocId,
  }) {
    final cleanSectionKey = _requireSectionKey(sectionKey);
    final cleanSectionDocId = _requireSectionDocId(sectionDocId);

    return _taDoc(
      contractId: contractId,
      taId: taId,
    ).collection(cleanSectionKey).doc(cleanSectionDocId);
  }

  String _filesPath({
    required String contractId,
    required String taId,
    required String pecasDocId,
  }) {
    final cleanContractId = _requireContractId(contractId);
    final cleanTaId = _requireTaId(taId);
    final cleanPecasDocId = _requireSectionDocId(pecasDocId);

    return 'tenants/$_tenantId/contracts/$cleanContractId/'
        'hiring/main/arquivamento/$cleanTaId/'
        '${TermoArquivamentoData.sectionPecas}/$cleanPecasDocId/files';
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
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Map<String, dynamic> _cleanSystemFields(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..remove('createdBy')
      ..remove('updatedBy');
  }

  String _preferredRootMergeSectionKey() {
    const preferred = 'metadados';

    if (TermoArquivamentoData.sectionKeys.contains(preferred)) {
      return preferred;
    }

    if (TermoArquivamentoData.sectionKeys.isNotEmpty) {
      return TermoArquivamentoData.sectionKeys.first;
    }

    return preferred;
  }

  Future<({String taId, Map<String, String> sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final cleanContractId = _requireContractId(contractId);

    final sectionIds = <String, String>{
      for (final section in TermoArquivamentoData.sectionKeys) section: _mainDocId,
    };

    final root = _taDoc(
      contractId: cleanContractId,
      taId: _mainDocId,
    );

    await root.set(
      <String, dynamic>{
        'id': _mainDocId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'module': _arquivamentoCollectionId,
        'recordPath': root.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return (taId: _mainDocId, sectionIds: sectionIds);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String taId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanTaId = _requireTaId(taId);

    final root = _taDoc(
      contractId: cleanContractId,
      taId: cleanTaId,
    );

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

        final data = _cleanSystemFields(
          snap.data() ?? const <String, dynamic>{},
        );

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
    required String taId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanTaId = _requireTaId(taId);

    if (sectionsData.isEmpty) return;

    final batch = _db.batch();

    final root = _taDoc(
      contractId: cleanContractId,
      taId: cleanTaId,
    );

    batch.set(
      root,
      <String, dynamic>{
        'id': cleanTaId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'module': _arquivamentoCollectionId,
        'recordPath': root.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key.trim();
      final sectionDocId = sectionIds[sectionKey]?.trim();

      if (sectionKey.isEmpty) continue;
      if (sectionDocId == null || sectionDocId.isEmpty) continue;

      final sectionRef = root.collection(sectionKey).doc(sectionDocId);

      final sectionData = _cleanSystemFields(entry.value);

      batch.set(
        sectionRef,
        <String, dynamic>{
          ...sectionData,
          'id': sectionDocId,
          'tenantId': _tenantId,
          'companyId': _tenantId,
          'contractId': cleanContractId,
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'taId': cleanTaId,
          'termoArquivamentoId': cleanTaId,
          'sectionKey': sectionKey,
          'recordPath': sectionRef.path,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> saveSection({
    required String contractId,
    required String taId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanTaId = _requireTaId(taId);
    final cleanSectionKey = _requireSectionKey(sectionKey);
    final cleanSectionDocId = _requireSectionDocId(sectionDocId);

    final root = _taDoc(
      contractId: cleanContractId,
      taId: cleanTaId,
    );

    final ref = _sectionDoc(
      contractId: cleanContractId,
      taId: cleanTaId,
      sectionKey: cleanSectionKey,
      sectionDocId: cleanSectionDocId,
    );

    final cleanData = _cleanSystemFields(data);

    final batch = _db.batch();

    batch.set(
      root,
      <String, dynamic>{
        'id': cleanTaId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'module': _arquivamentoCollectionId,
        'recordPath': root.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      ref,
      <String, dynamic>{
        ...cleanData,
        'id': cleanSectionDocId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'taId': cleanTaId,
        'termoArquivamentoId': cleanTaId,
        'sectionKey': cleanSectionKey,
        'recordPath': ref.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<TermoArquivamentoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final rootRef = _taDoc(
      contractId: cleanContractId,
      taId: ids.taId,
    );

    final rootSnap = await rootRef.get();

    final rootData = _cleanSystemFields(
      rootSnap.data() ?? const <String, dynamic>{},
    );

    final sections = await loadAllSections(
      contractId: cleanContractId,
      taId: ids.taId,
      sectionIds: ids.sectionIds,
    );

    if (rootData.isNotEmpty) {
      final targetSection = _preferredRootMergeSectionKey();

      sections[targetSection] = <String, dynamic>{
        ...rootData,
        ...(sections[targetSection] ?? const <String, dynamic>{}),
      };
    }

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return TermoArquivamentoData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listFiles({
    required String contractId,
    required String taId,
    required String pecasDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();
    final cleanPecasDocId = pecasDocId.trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = _storage.ref(
      _filesPath(
        contractId: cleanContractId,
        taId: cleanTaId,
        pecasDocId: cleanPecasDocId,
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
    required String taId,
    required String pecasDocId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'doc',
      'docx',
    ],
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();
    final cleanPecasDocId = pecasDocId.trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty) {
      throw Exception('Caminho inválido para upload do termo de arquivamento.');
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

    final fileName = file.name.trim();

    if (fileName.isEmpty) {
      throw Exception('Nome do arquivo inválido.');
    }

    return uploadBytes(
      contractId: cleanContractId,
      taId: cleanTaId,
      pecasDocId: cleanPecasDocId,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    required String taId,
    required String pecasDocId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();
    final cleanPecasDocId = pecasDocId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty ||
        cleanFileName.isEmpty) {
      throw Exception('Caminho inválido para upload do termo de arquivamento.');
    }

    if (bytes.isEmpty) {
      throw Exception('Bytes do arquivo vazios.');
    }

    final ext = _extractExt(cleanFileName);

    final ref = _storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        taId: cleanTaId,
        pecasDocId: cleanPecasDocId,
      )}/$cleanFileName',
    );

    final task = ref.putData(
      bytes,
      metadata ??
          SettableMetadata(
            contentType: _contentTypeForExt(ext),
            customMetadata: <String, String>{
              'tenantId': _tenantId,
              'companyId': _tenantId,
              'contractId': cleanContractId,
              'uidContract': cleanContractId,
              'uidcontract': cleanContractId,
              'taId': cleanTaId,
              'termoArquivamentoId': cleanTaId,
              'pecasDocId': cleanPecasDocId,
              'module': _arquivamentoCollectionId,
              'originalName': cleanFileName,
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
    required String taId,
    required String pecasDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();
    final cleanPecasDocId = pecasDocId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = _storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          taId: cleanTaId,
          pecasDocId: cleanPecasDocId,
        )}/$cleanFileName',
      );

      await ref.delete();
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
}