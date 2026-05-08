// lib/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'minuta_contrato_data.dart';

class MinutaContratoRepository {
  MinutaContratoRepository({
    FirebaseFirestore? db,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = db ?? firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('minuta');
  }

  String _filesPath({
    required String contractId,
    required String minutaId,
    required String gestaoId,
  }) {
    return 'contracts/$contractId/minuta/$minutaId/${MinutaContratoData.sectionGestaoRefs}/$gestaoId/files';
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
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<({String minutaId, Map<String, String> sectionIds})>
  ensureStructure(
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in MinutaContratoData.sectionKeys) section: 'main',
    };

    return (minutaId: 'main', sectionIds: sectionIds);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String minutaId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanMinutaId.isEmpty) {
      throw Exception('minutaId não informado.');
    }

    final root = _col(cleanContractId).doc(cleanMinutaId);

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

        final snap =
        await root.collection(sectionName).doc(sectionDocId).get();

        final data = Map<String, dynamic>.from(
          snap.data() ?? const <String, dynamic>{},
        );

        data.remove('createdAt');
        data.remove('updatedAt');
        data.remove('createdBy');
        data.remove('updatedBy');

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
    required String minutaId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanMinutaId.isEmpty) {
      throw Exception('minutaId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final batch = _db.batch();
    final root = _col(cleanContractId).doc(cleanMinutaId);

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key.trim();
      final sectionDocId = sectionIds[sectionKey]?.trim();

      if (sectionKey.isEmpty) continue;
      if (sectionDocId == null || sectionDocId.isEmpty) continue;

      final sectionData = Map<String, dynamic>.from(entry.value)
        ..remove('createdAt')
        ..remove('updatedAt')
        ..remove('createdBy')
        ..remove('updatedBy');

      batch.set(
        root.collection(sectionKey).doc(sectionDocId),
        <String, dynamic>{
          ...sectionData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> saveSection({
    required String contractId,
    required String minutaId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanMinutaId.isEmpty) {
      throw Exception('minutaId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final cleanData = Map<String, dynamic>.from(data)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..remove('createdBy')
      ..remove('updatedBy');

    final ref = _col(cleanContractId)
        .doc(cleanMinutaId)
        .collection(cleanSectionKey)
        .doc(cleanSectionDocId);

    await ref.set(
      <String, dynamic>{
        ...cleanData,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<MinutaContratoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      minutaId: ids.minutaId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return MinutaContratoData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listFiles({
    required String contractId,
    required String minutaId,
    required String gestaoId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();
    final cleanGestaoId = gestaoId.trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = _storage.ref(
      _filesPath(
        contractId: cleanContractId,
        minutaId: cleanMinutaId,
        gestaoId: cleanGestaoId,
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
    required String minutaId,
    required String gestaoId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'docx',
    ],
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();
    final cleanGestaoId = gestaoId.trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty) {
      throw Exception('Caminho inválido para upload da minuta.');
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
      minutaId: cleanMinutaId,
      gestaoId: cleanGestaoId,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    required String minutaId,
    required String gestaoId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();
    final cleanGestaoId = gestaoId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty ||
        cleanFileName.isEmpty) {
      throw Exception('Caminho inválido para upload da minuta.');
    }

    if (bytes.isEmpty) {
      throw Exception('Bytes do arquivo vazios.');
    }

    final ext = _extractExt(cleanFileName);

    final ref = _storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        minutaId: cleanMinutaId,
        gestaoId: cleanGestaoId,
      )}/$cleanFileName',
    );

    final task = ref.putData(
      bytes,
      metadata ??
          SettableMetadata(
            contentType: _contentTypeForExt(ext),
            customMetadata: <String, String>{
              'originalName': cleanFileName,
              'contractId': cleanContractId,
              'minutaId': cleanMinutaId,
              'gestaoId': cleanGestaoId,
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
    required String minutaId,
    required String gestaoId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = minutaId.trim();
    final cleanGestaoId = gestaoId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = _storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          minutaId: cleanMinutaId,
          gestaoId: cleanGestaoId,
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