// lib/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'dfd_data.dart';

class DfdRepository {
  DfdRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('dfd');
  }

  String _filesPath({
    required String contractId,
    required String dfdId,
    required String documentosId,
  }) {
    return 'contracts/$contractId/dfd/$dfdId/documentos/$documentosId/files';
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

  Future<({String dfdId, Map<String, String> sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in DfdData.sectionKeys) section: 'main',
    };

    return (dfdId: 'main', sectionIds: sectionIds);
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String dfdId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = dfdId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanDfdId.isEmpty) {
      throw Exception('dfdId não informado.');
    }

    final dfdRef = _col(cleanContractId).doc(cleanDfdId);

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

        final snap = await dfdRef.collection(sectionName).doc(sectionDocId).get();

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
    required String dfdId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = dfdId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanDfdId.isEmpty) {
      throw Exception('dfdId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final dfdRef = _col(cleanContractId).doc(cleanDfdId);
    final batch = _db.batch();

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key.trim();
      final sectionData = Map<String, dynamic>.from(entry.value);
      final sectionDocId = sectionIds[sectionKey]?.trim();

      if (sectionKey.isEmpty) continue;
      if (sectionDocId == null || sectionDocId.isEmpty) continue;

      sectionData.remove('createdAt');
      sectionData.remove('updatedAt');
      sectionData.remove('createdBy');
      sectionData.remove('updatedBy');

      final ref = dfdRef.collection(sectionKey).doc(sectionDocId);

      batch.set(
        ref,
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
    required String dfdId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = dfdId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanDfdId.isEmpty) {
      throw Exception('dfdId não informado.');
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
        .doc(cleanDfdId)
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

  Future<DfdData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);
    if (!hasAnyData) return null;

    return DfdData.fromSectionsMap(
      sections,
      contractId: cleanContractId,
    );
  }

  Future<String> ensureContractAndSaveDfd({
    String? contractId,
    required DfdData data,
  }) async {
    String effectiveId = (contractId ?? '').trim();

    if (effectiveId.isEmpty) {
      final contractsRef = _db.collection('contracts');

      final docRef = await contractsRef.add(
        <String, dynamic>{
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      effectiveId = docRef.id;
    } else {
      await _db.collection('contracts').doc(effectiveId).set(
        <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    final ids = await ensureStructure(effectiveId);

    await saveSectionsBatch(
      contractId: effectiveId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
      sectionsData: data.toSectionsMap(),
    );

    return effectiveId;
  }

  Future<List<({String contractId, double km})>>
  listBenchmarkSeedsByNaturezaIntervencao(String natureza) async {
    final n = natureza.trim();

    if (n.isEmpty) return <({String contractId, double km})>[];

    final qs = await _db
        .collectionGroup(DfdData.sectionLocalizacao)
        .where('naturezaIntervencao', isEqualTo: n)
        .get();

    final out = <String, double>{};

    for (final doc in qs.docs) {
      final pathParts = doc.reference.path.split('/');

      if (pathParts.length < 2 || pathParts[0] != 'contracts') continue;

      final contractId = pathParts[1].trim();
      if (contractId.isEmpty) continue;

      final data = doc.data();
      final km = _readDouble(data['extensaoKm']);

      if (km > (out[contractId] ?? 0.0)) {
        out[contractId] = km;
      }
    }

    final seeds = out.entries
        .map((entry) => (contractId: entry.key, km: entry.value))
        .toList()
      ..sort((a, b) => a.contractId.compareTo(b.contractId));

    return seeds;
  }

  Future<double> readBaseValueForContract(String contractId) async {
    final id = contractId.trim();

    if (id.isEmpty) return 0.0;

    final ref = _db
        .collection('contracts')
        .doc(id)
        .collection('dfd')
        .doc('main')
        .collection(DfdData.sectionObjeto)
        .doc('main');

    final snap = await ref.get();
    final data = snap.data();

    if (data == null) return 0.0;

    final valorDemanda = _readDouble(data['valorDemanda']);
    if (valorDemanda > 0) return valorDemanda;

    return _readDouble(data['estimativaValor']);
  }

  Future<List<Attachment>> listarDocsDfd({
    required String contractId,
    required String dfdId,
    required String documentosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = dfdId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty ||
        cleanDfdId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = _storage.ref(
      _filesPath(
        contractId: cleanContractId,
        dfdId: cleanDfdId,
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

  Future<Attachment> uploadDocDfd({
    required String contractId,
    required String dfdId,
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
    final cleanDfdId = dfdId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty ||
        cleanDfdId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload do DFD.');
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
        dfdId: cleanDfdId,
        documentosId: cleanDocumentosId,
      )}/$name',
    );

    final upload = ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
        customMetadata: <String, String>{
          'originalName': name,
          'contractId': cleanContractId,
          'dfdId': cleanDfdId,
          'documentosId': cleanDocumentosId,
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

  Future<bool> deleteDocDfd({
    required String contractId,
    required String dfdId,
    required String documentosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = dfdId.trim();
    final cleanDocumentosId = documentosId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanDfdId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = _storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          dfdId: cleanDfdId,
          documentosId: cleanDocumentosId,
        )}/$cleanFileName',
      );

      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDocDfdByPath(String path) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) return false;

    try {
      await _storage.ref(cleanPath).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  double _readDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) return value.toDouble();

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return 0.0;

      return double.tryParse(
        text.replaceAll('.', '').replaceAll(',', '.'),
      ) ??
          double.tryParse(text.replaceAll(',', '.')) ??
          0.0;
    }

    return 0.0;
  }
}