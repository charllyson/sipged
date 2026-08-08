import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'publicacao_extrato_data.dart';

class PublicacaoExtratoRepository {
  PublicacaoExtratoRepository({
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
  static const String _publicacaoCollectionId = 'publicacao';

  static String _requireTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório em PublicacaoExtratoRepository.',
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

  String _requirePubId(String pubId) {
    final cleanPubId = pubId.trim();

    if (cleanPubId.isEmpty) {
      throw Exception('pubId não informado.');
    }

    return cleanPubId;
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
    return _hiringMainDoc(contractId).collection(_publicacaoCollectionId);
  }

  DocumentReference<Map<String, dynamic>> _pubDoc({
    required String contractId,
    required String pubId,
  }) {
    final cleanContractId = _requireContractId(contractId);
    final cleanPubId = _requirePubId(pubId);

    return _col(cleanContractId).doc(cleanPubId);
  }

  DocumentReference<Map<String, dynamic>> _sectionDoc({
    required String contractId,
    required String pubId,
    required String sectionKey,
    required String sectionDocId,
  }) {
    final cleanSectionKey = _requireSectionKey(sectionKey);
    final cleanSectionDocId = _requireSectionDocId(sectionDocId);

    return _pubDoc(
      contractId: contractId,
      pubId: pubId,
    ).collection(cleanSectionKey).doc(cleanSectionDocId);
  }

  String _filesPath({
    required String contractId,
    required String pubId,
    required String veiculoDocId,
  }) {
    final cleanContractId = _requireContractId(contractId);
    final cleanPubId = _requirePubId(pubId);
    final cleanVeiculoDocId = _requireSectionDocId(veiculoDocId);

    return 'tenants/$_tenantId/contracts/$cleanContractId/'
        'hiring/main/publicacao/$cleanPubId/'
        '${PublicacaoExtratoData.sectionVeiculo}/$cleanVeiculoDocId/files';
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
    final cleanContractId = _requireContractId(contractId);

    await _contractDoc(cleanContractId).set(
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _ensureHiringMain(String contractId) async {
    final cleanContractId = _requireContractId(contractId);

    await _ensureContractParent(cleanContractId);

    await _hiringMainDoc(cleanContractId).set(
      <String, dynamic>{
        'id': _mainDocId,
        'module': _hiringCollectionId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _cleanSystemFields(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..remove('createdBy')
      ..remove('updatedBy')
      ..remove('migratedAt')
      ..remove('migrationSourcePath')
      ..remove('migrationSourceDocId')
      ..remove('migrationTargetPath')
      ..remove('legacySourceId')
      ..remove('legacySourcePath')
      ..remove('recordPath')
      ..remove('sourcePath')
      ..remove('path')
      ..remove('sourceCollectionModel')
      ..remove('tenantId')
      ..remove('companyId')
      ..remove('uidContract')
      ..remove('uidcontract')
      ..remove('contractId')
      ..remove('module')
      ..remove('id')
      ..remove('pubId')
      ..remove('publicacaoId')
      ..remove('sectionKey');
  }

  Map<String, dynamic> _writeCleanFields(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..remove('createdBy')
      ..remove('updatedBy');
  }

  Future<({String pubId, Map<String, String> sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final cleanContractId = _requireContractId(contractId);

    await _ensureHiringMain(cleanContractId);

    final sectionIds = <String, String>{
      for (final section in PublicacaoExtratoData.sectionKeys) section: _mainDocId,
    };

    final root = _pubDoc(
      contractId: cleanContractId,
      pubId: _mainDocId,
    );

    await root.set(
      <String, dynamic>{
        'id': _mainDocId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'module': _publicacaoCollectionId,
        'recordPath': root.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return (
    pubId: _mainDocId,
    sectionIds: sectionIds,
    );
  }

  Future<Map<String, PublicacaoExtratoData?>> getSummaryForContracts(
      Iterable<String> contractIds, {
        bool debug = false,
      }) async {
    final ids = contractIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final result = <String, PublicacaoExtratoData?>{
      for (final id in ids) id: null,
    };

    if (ids.isEmpty) {
      return result;
    }

    final sw = Stopwatch()..start();

    final entries = await Future.wait(
      ids.map((contractId) async {
        try {
          final data = await readSummaryForContract(contractId);
          return MapEntry<String, PublicacaoExtratoData?>(contractId, data);
        } catch (error) {
          if (debug) {
            debugPrint(
              '[PublicacaoExtratoRepository] Erro summary '
                  'contractId=$contractId: $error',
            );
          }

          return MapEntry<String, PublicacaoExtratoData?>(contractId, null);
        }
      }),
    );

    for (final entry in entries) {
      result[entry.key] = entry.value;
    }

    sw.stop();

    if (debug) {
      final loaded = result.values.whereType<PublicacaoExtratoData>().length;

      debugPrint(
        '[PublicacaoExtratoRepository] getSummaryForContracts '
            'tenantId=$_tenantId contratos=${ids.length} '
            'comDados=$loaded em ${sw.elapsedMilliseconds}ms',
      );
    }

    return result;
  }

  Future<PublicacaoExtratoData?> readSummaryForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final rootRef = _pubDoc(
      contractId: cleanContractId,
      pubId: _mainDocId,
    );

    final rootSnap = await rootRef.get();
    final rootRaw = rootSnap.data();

    if (rootRaw != null && rootRaw.isNotEmpty) {
      final rootData = _cleanSystemFields(rootRaw);

      final hasFlatSummary = _hasAnyValue(
        rootData,
        const <String>[
          'tipoExtrato',
          'numeroContrato',
          'processo',
          'objetoResumo',
          'contratadaRazao',
          'contratadaCnpj',
          'valor',
          'vigencia',
          'veiculo',
          'dataPublicacao',
          'linkPublicacao',
          'status',
        ],
      );

      if (hasFlatSummary) {
        return PublicacaoExtratoData.fromFlatMap(rootData);
      }
    }

    final sections = await _loadSummarySections(cleanContractId);

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return PublicacaoExtratoData.fromSectionsMap(sections);
  }

  Future<Map<String, Map<String, dynamic>>> _loadSummarySections(
      String contractId,
      ) async {
    final root = _pubDoc(
      contractId: contractId,
      pubId: _mainDocId,
    );

    final keys = <String>[
      PublicacaoExtratoData.sectionMetadados,
      PublicacaoExtratoData.sectionPartes,
      PublicacaoExtratoData.sectionVeiculo,
      PublicacaoExtratoData.sectionStatus,
      PublicacaoExtratoData.sectionResponsavel,
    ];

    final entries = await Future.wait(
      keys.map((sectionKey) async {
        final snap = await root.collection(sectionKey).doc(_mainDocId).get();

        final data = _cleanSystemFields(
          snap.data() ?? const <String, dynamic>{},
        );

        return MapEntry<String, Map<String, dynamic>>(sectionKey, data);
      }),
    );

    return <String, Map<String, dynamic>>{
      for (final entry in entries) entry.key: entry.value,
    };
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String pubId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanPubId = _requirePubId(pubId);

    final root = _pubDoc(
      contractId: cleanContractId,
      pubId: cleanPubId,
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
    required String pubId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanPubId = _requirePubId(pubId);

    if (sectionsData.isEmpty) return;

    await _ensureHiringMain(cleanContractId);

    final batch = _db.batch();

    final root = _pubDoc(
      contractId: cleanContractId,
      pubId: cleanPubId,
    );

    final summary = PublicacaoExtratoData.fromSectionsMap(sectionsData).toFlatMap()
      ..removeWhere((_, value) => value == null);

    batch.set(
      _contractDoc(cleanContractId),
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _hiringMainDoc(cleanContractId),
      <String, dynamic>{
        'id': _mainDocId,
        'module': _hiringCollectionId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
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
        'id': cleanPubId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'module': _publicacaoCollectionId,
        'recordPath': root.path,
        ...summary,
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
      final sectionData = _writeCleanFields(entry.value);

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
          'pubId': cleanPubId,
          'publicacaoId': cleanPubId,
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
    required String pubId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanPubId = _requirePubId(pubId);
    final cleanSectionKey = _requireSectionKey(sectionKey);
    final cleanSectionDocId = _requireSectionDocId(sectionDocId);

    await _ensureHiringMain(cleanContractId);

    final root = _pubDoc(
      contractId: cleanContractId,
      pubId: cleanPubId,
    );

    final ref = _sectionDoc(
      contractId: cleanContractId,
      pubId: cleanPubId,
      sectionKey: cleanSectionKey,
      sectionDocId: cleanSectionDocId,
    );

    final cleanData = _writeCleanFields(data);
    final rootSummary = _summaryRootFieldsFromSingleSection(
      sectionKey: cleanSectionKey,
      data: cleanData,
    );

    final batch = _db.batch();

    batch.set(
      _contractDoc(cleanContractId),
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _hiringMainDoc(cleanContractId),
      <String, dynamic>{
        'id': _mainDocId,
        'module': _hiringCollectionId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
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
        'id': cleanPubId,
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'module': _publicacaoCollectionId,
        'recordPath': root.path,
        ...rootSummary,
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
        'pubId': cleanPubId,
        'publicacaoId': cleanPubId,
        'sectionKey': cleanSectionKey,
        'recordPath': ref.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<PublicacaoExtratoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final rootRef = _pubDoc(
      contractId: cleanContractId,
      pubId: ids.pubId,
    );

    final rootSnap = await rootRef.get();

    final rootData = _cleanSystemFields(
      rootSnap.data() ?? const <String, dynamic>{},
    );

    final sections = await loadAllSections(
      contractId: cleanContractId,
      pubId: ids.pubId,
      sectionIds: ids.sectionIds,
    );

    if (rootData.isNotEmpty) {
      sections[PublicacaoExtratoData.sectionMetadados] = <String, dynamic>{
        ...rootData,
        ...(sections[PublicacaoExtratoData.sectionMetadados] ??
            const <String, dynamic>{}),
      };
    }

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return PublicacaoExtratoData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listFiles({
    required String contractId,
    required String pubId,
    required String veiculoDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = pubId.trim();
    final cleanVeiculoDocId = veiculoDocId.trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = _storage.ref(
      _filesPath(
        contractId: cleanContractId,
        pubId: cleanPubId,
        veiculoDocId: cleanVeiculoDocId,
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
    required String pubId,
    required String veiculoDocId,
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
    final cleanPubId = pubId.trim();
    final cleanVeiculoDocId = veiculoDocId.trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty) {
      throw Exception('Caminho inválido para upload da publicação.');
    }

    await _ensureHiringMain(cleanContractId);

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

    final fileName = file.name.trim();

    if (fileName.isEmpty) {
      throw Exception('Nome do arquivo inválido.');
    }

    return uploadBytes(
      contractId: cleanContractId,
      pubId: cleanPubId,
      veiculoDocId: cleanVeiculoDocId,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    required String pubId,
    required String veiculoDocId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = pubId.trim();
    final cleanVeiculoDocId = veiculoDocId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty ||
        cleanFileName.isEmpty) {
      throw Exception('Caminho inválido para upload da publicação.');
    }

    if (bytes.isEmpty) {
      throw Exception('Bytes do arquivo vazios.');
    }

    await _ensureHiringMain(cleanContractId);

    final ext = _extractExt(cleanFileName);

    final ref = _storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        pubId: cleanPubId,
        veiculoDocId: cleanVeiculoDocId,
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
              'pubId': cleanPubId,
              'publicacaoId': cleanPubId,
              'veiculoDocId': cleanVeiculoDocId,
              'module': _publicacaoCollectionId,
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
    required String pubId,
    required String veiculoDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = pubId.trim();
    final cleanVeiculoDocId = veiculoDocId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = _storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          pubId: cleanPubId,
          veiculoDocId: cleanVeiculoDocId,
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

  Map<String, dynamic> _summaryRootFieldsFromSingleSection({
    required String sectionKey,
    required Map<String, dynamic> data,
  }) {
    switch (sectionKey) {
      case PublicacaoExtratoData.sectionMetadados:
        return <String, dynamic>{
          if (data.containsKey('tipoExtrato')) 'tipoExtrato': data['tipoExtrato'],
          if (data.containsKey('numeroContrato'))
            'numeroContrato': data['numeroContrato'],
          if (data.containsKey('processo')) 'processo': data['processo'],
          if (data.containsKey('objetoResumo'))
            'objetoResumo': data['objetoResumo'],
        };

      case PublicacaoExtratoData.sectionPartes:
        return <String, dynamic>{
          if (data.containsKey('contratadaRazao'))
            'contratadaRazao': data['contratadaRazao'],
          if (data.containsKey('contratadaCnpj'))
            'contratadaCnpj': data['contratadaCnpj'],
          if (data.containsKey('valor')) 'valor': data['valor'],
          if (data.containsKey('vigencia')) 'vigencia': data['vigencia'],
          if (data.containsKey('cnoRef')) 'cnoRef': data['cnoRef'],
        };

      case PublicacaoExtratoData.sectionVeiculo:
        return <String, dynamic>{
          if (data.containsKey('veiculo')) 'veiculo': data['veiculo'],
          if (data.containsKey('edicaoNumero'))
            'edicaoNumero': data['edicaoNumero'],
          if (data.containsKey('dataEnvio')) 'dataEnvio': data['dataEnvio'],
          if (data.containsKey('dataPublicacao'))
            'dataPublicacao': data['dataPublicacao'],
          if (data.containsKey('linkPublicacao'))
            'linkPublicacao': data['linkPublicacao'],
        };

      case PublicacaoExtratoData.sectionStatus:
        return <String, dynamic>{
          if (data.containsKey('status')) 'status': data['status'],
          if (data.containsKey('prazoLegal')) 'prazoLegal': data['prazoLegal'],
          if (data.containsKey('observacoes')) 'observacoes': data['observacoes'],
        };

      case PublicacaoExtratoData.sectionResponsavel:
        return <String, dynamic>{
          if (data.containsKey('responsavelUserId'))
            'responsavelUserId': data['responsavelUserId'],
        };

      default:
        return const <String, dynamic>{};
    }
  }

  bool _hasAnyValue(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      if (value is String && value.trim().isEmpty) continue;

      return true;
    }

    return false;
  }
}