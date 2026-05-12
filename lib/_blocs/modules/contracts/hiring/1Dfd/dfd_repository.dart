// lib/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'dfd_data.dart';

class DfdRepository {
  DfdRepository({
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
      throw ArgumentError('tenantId é obrigatório para DfdRepository.');
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

    return _hiringMainDoc(cleanContractId).collection('dfd');
  }

  String _filesPath({
    required String contractId,
    required String dfdId,
    required String documentosId,
  }) {
    final cleanContractId = contractId.trim();
    final cleanDfdId = dfdId.trim();
    final cleanDocumentosId = documentosId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId não informado.');
    }

    if (cleanDfdId.isEmpty) {
      throw ArgumentError('dfdId não informado.');
    }

    if (cleanDocumentosId.isEmpty) {
      throw ArgumentError('documentosId não informado.');
    }

    return 'tenants/$tenantId/contracts/$cleanContractId/hiring/main/dfd/$cleanDfdId/documentos/$cleanDocumentosId/files';
  }

  String _extractExt(String nameOrUrl) {
    final clean = nameOrUrl.trim();
    final queryFree = clean.split('?').first.split('#').first;
    final index = queryFree.lastIndexOf('.');

    if (index <= 0 || index == queryFree.length - 1) {
      return '';
    }

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

  Future<({String dfdId, Map<String, String> sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    await _ensureHiringMain(id);

    final sectionIds = <String, String>{
      for (final section in DfdData.sectionKeys) section: 'main',
    };

    return (
    dfdId: 'main',
    sectionIds: sectionIds,
    );
  }

  Map<String, dynamic> _cleanLoadedSectionData(Map<String, dynamic> data) {
    final clean = Map<String, dynamic>.from(data);

    clean.remove('createdAt');
    clean.remove('updatedAt');
    clean.remove('createdBy');
    clean.remove('updatedBy');
    clean.remove('migratedAt');
    clean.remove('migrationSourcePath');
    clean.remove('migrationSourceDocId');
    clean.remove('migrationTargetPath');
    clean.remove('legacySourceId');
    clean.remove('legacySourcePath');
    clean.remove('recordPath');
    clean.remove('sourceCollectionModel');
    clean.remove('tenantId');
    clean.remove('companyId');
    clean.remove('uidContract');
    clean.remove('uidcontract');
    clean.remove('contractId');
    clean.remove('module');
    clean.remove('id');

    return clean;
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

        final data = _cleanLoadedSectionData(
          Map<String, dynamic>.from(
            snap.data() ?? const <String, dynamic>{},
          ),
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

    if (sectionsData.isEmpty) {
      return;
    }

    await _ensureHiringMain(cleanContractId);

    final dfdRef = _col(cleanContractId).doc(cleanDfdId);
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
      dfdRef,
      <String, dynamic>{
        'id': cleanDfdId,
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
      final sectionDocId = sectionIds[sectionKey]?.trim();

      if (sectionKey.isEmpty) continue;
      if (sectionDocId == null || sectionDocId.isEmpty) continue;

      final sectionData = _cleanLoadedSectionData(
        Map<String, dynamic>.from(entry.value),
      );

      final ref = dfdRef.collection(sectionKey).doc(sectionDocId);

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

    await _ensureHiringMain(cleanContractId);

    final cleanData = _cleanLoadedSectionData(
      Map<String, dynamic>.from(data),
    );

    final dfdRef = _col(cleanContractId).doc(cleanDfdId);
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
      dfdRef,
      <String, dynamic>{
        'id': cleanDfdId,
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

    final ref = dfdRef.collection(cleanSectionKey).doc(cleanSectionDocId);

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

  String? _contractIdFromAnyDfdSectionDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    final contractIdFromField = data['contractId']?.toString().trim();

    if (contractIdFromField != null && contractIdFromField.isNotEmpty) {
      return contractIdFromField;
    }

    final uidContractFromField = data['uidContract']?.toString().trim();

    if (uidContractFromField != null && uidContractFromField.isNotEmpty) {
      return uidContractFromField;
    }

    final uidcontractFromField = data['uidcontract']?.toString().trim();

    if (uidcontractFromField != null && uidcontractFromField.isNotEmpty) {
      return uidcontractFromField;
    }

    return _contractIdFromTenantPathParts(doc.reference.path.split('/'));
  }

  Future<int> _loadSectionGroupIntoMap({
    required String sectionKey,
    required Set<String> wantedContractIds,
    required Map<String, Map<String, Map<String, dynamic>>> sectionsByContract,
  }) async {
    final cleanSectionKey = sectionKey.trim();

    if (cleanSectionKey.isEmpty || wantedContractIds.isEmpty) {
      return 0;
    }

    final snapshot = await _db
        .collectionGroup(cleanSectionKey)
        .where('tenantId', isEqualTo: tenantId)
        .get();

    var usedDocs = 0;

    for (final doc in snapshot.docs) {
      final contractId = _contractIdFromAnyDfdSectionDoc(doc);

      if (contractId == null || contractId.trim().isEmpty) {
        continue;
      }

      final cleanContractId = contractId.trim();

      if (!wantedContractIds.contains(cleanContractId)) {
        continue;
      }

      final sectionData = _cleanLoadedSectionData(doc.data());

      if (sectionData.isEmpty) {
        continue;
      }

      sectionsByContract
          .putIfAbsent(
        cleanContractId,
            () => <String, Map<String, dynamic>>{},
      )
          .update(
        cleanSectionKey,
            (current) => <String, dynamic>{
          ...current,
          ...sectionData,
        },
        ifAbsent: () => sectionData,
      );

      usedDocs++;
    }

    return usedDocs;
  }

  Future<Map<String, DfdData?>> readDataForContractsSummary(
      Iterable<String> contractIds, {
        bool debug = false,
      }) async {
    final stopwatch = Stopwatch()..start();

    final wantedIds = contractIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final output = <String, DfdData?>{
      for (final id in wantedIds) id: null,
    };

    if (wantedIds.isEmpty) {
      return output;
    }

    final sectionsByContract =
    <String, Map<String, Map<String, dynamic>>>{};

    const summarySections = <String>[
      DfdData.sectionIdentificacao,
      DfdData.sectionObjeto,
      DfdData.sectionLocalizacao,
    ];

    var totalUsedDocs = 0;

    for (final sectionKey in summarySections) {
      final usedDocs = await _loadSectionGroupIntoMap(
        sectionKey: sectionKey,
        wantedContractIds: wantedIds,
        sectionsByContract: sectionsByContract,
      );

      totalUsedDocs += usedDocs;
    }

    for (final contractId in wantedIds) {
      final sections = sectionsByContract[contractId];

      if (sections == null || sections.isEmpty) {
        output[contractId] = null;
        continue;
      }

      final hasAnyData = sections.values.any((map) => map.isNotEmpty);

      if (!hasAnyData) {
        output[contractId] = null;
        continue;
      }

      output[contractId] = DfdData.fromSectionsMap(
        sections,
        contractId: contractId,
      );
    }

    stopwatch.stop();

    if (debug) {
      debugPrint(
        '[DfdRepository] readDataForContractsSummary | '
            'tenantId=$tenantId | '
            'contratos=${wantedIds.length} | '
            'docsUsados=$totalUsedDocs | '
            'comDfd=${output.values.whereType<DfdData>().length} | '
            'tempo=${stopwatch.elapsedMilliseconds}ms',
      );
    }

    return output;
  }

  Future<DfdData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return null;
    }

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) {
      return null;
    }

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
      final docRef = _contractsCol().doc();
      effectiveId = docRef.id;

      await docRef.set(
        <String, dynamic>{
          'id': effectiveId,
          'tenantId': tenantId,
          'companyId': tenantId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      await _contractDoc(effectiveId).set(
        <String, dynamic>{
          'id': effectiveId,
          'tenantId': tenantId,
          'companyId': tenantId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await _ensureHiringMain(effectiveId);

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
  listBenchmarkSeedsByNaturezaIntervencao(
      String natureza,
      ) async {
    final cleanNatureza = natureza.trim();

    debugPrint('');
    debugPrint(
      '[DfdRepository][BENCHMARK] listBenchmarkSeedsByNaturezaIntervencao',
    );
    debugPrint('  tenantId=$tenantId');
    debugPrint('  naturezaIntervencao=$cleanNatureza');

    if (cleanNatureza.isEmpty) {
      debugPrint('  natureza vazia. Retornando lista vazia.');
      return <({String contractId, double km})>[];
    }

    final qs = await _db
        .collectionGroup(DfdData.sectionLocalizacao)
        .where('tenantId', isEqualTo: tenantId)
        .where('naturezaIntervencao', isEqualTo: cleanNatureza)
        .get();

    debugPrint('  docs encontrados=${qs.docs.length}');

    final out = <String, double>{};

    for (final doc in qs.docs) {
      final path = doc.reference.path;
      final pathParts = path.split('/');

      final contractId = _contractIdFromTenantPathParts(pathParts);

      if (contractId == null || contractId.trim().isEmpty) {
        debugPrint('  ignorado: contractId não localizado no path=$path');
        continue;
      }

      final data = doc.data();
      final km = _readDouble(data['extensaoKm']);

      debugPrint(
        '  doc path=$path | contractId=$contractId | '
            'natureza=${data['naturezaIntervencao']} | '
            'naturezaId=${data['naturezaIntervencaoId']} | '
            'km=$km',
      );

      if (km <= 0) {
        debugPrint('  ignorado: km inválido para contractId=$contractId');
        continue;
      }

      final currentKm = out[contractId];

      if (currentKm == null || km > currentKm) {
        out[contractId] = km;
      }
    }

    final seeds = out.entries
        .map(
          (entry) => (
      contractId: entry.key,
      km: entry.value,
      ),
    )
        .toList()
      ..sort(
            (a, b) => a.contractId.compareTo(b.contractId),
      );

    debugPrint('  seeds finais=${seeds.length}');

    for (final seed in seeds.take(20)) {
      debugPrint('  seed contractId=${seed.contractId} | km=${seed.km}');
    }

    if (seeds.length > 20) {
      debugPrint('  ... mais ${seeds.length - 20} seed(s)');
    }

    debugPrint('[DfdRepository][BENCHMARK] END');
    debugPrint('');

    return seeds;
  }

  Future<List<({String contractId, double km})>>
  listBenchmarkSeedsByNaturezaIntervencaoId(
      String naturezaIntervencaoId,
      ) async {
    final cleanNaturezaId = naturezaIntervencaoId.trim();

    debugPrint('');
    debugPrint(
      '[DfdRepository][BENCHMARK] listBenchmarkSeedsByNaturezaIntervencaoId',
    );
    debugPrint('  tenantId=$tenantId');
    debugPrint('  naturezaIntervencaoId=$cleanNaturezaId');

    if (cleanNaturezaId.isEmpty) {
      debugPrint('  naturezaIntervencaoId vazio. Retornando lista vazia.');
      return <({String contractId, double km})>[];
    }

    final qs = await _db
        .collectionGroup(DfdData.sectionLocalizacao)
        .where('tenantId', isEqualTo: tenantId)
        .where('naturezaIntervencaoId', isEqualTo: cleanNaturezaId)
        .get();

    debugPrint('  docs encontrados=${qs.docs.length}');

    final out = <String, double>{};

    for (final doc in qs.docs) {
      final path = doc.reference.path;
      final pathParts = path.split('/');

      final contractId = _contractIdFromTenantPathParts(pathParts);

      if (contractId == null || contractId.trim().isEmpty) {
        debugPrint('  ignorado: contractId não localizado no path=$path');
        continue;
      }

      final data = doc.data();
      final km = _readDouble(data['extensaoKm']);

      debugPrint(
        '  doc path=$path | contractId=$contractId | '
            'natureza=${data['naturezaIntervencao']} | '
            'naturezaId=${data['naturezaIntervencaoId']} | '
            'km=$km',
      );

      if (km <= 0) {
        debugPrint('  ignorado: km inválido para contractId=$contractId');
        continue;
      }

      final currentKm = out[contractId];

      if (currentKm == null || km > currentKm) {
        out[contractId] = km;
      }
    }

    final seeds = out.entries
        .map(
          (entry) => (
      contractId: entry.key,
      km: entry.value,
      ),
    )
        .toList()
      ..sort(
            (a, b) => a.contractId.compareTo(b.contractId),
      );

    debugPrint('  seeds finais=${seeds.length}');

    for (final seed in seeds.take(20)) {
      debugPrint('  seed contractId=${seed.contractId} | km=${seed.km}');
    }

    if (seeds.length > 20) {
      debugPrint('  ... mais ${seeds.length - 20} seed(s)');
    }

    debugPrint('[DfdRepository][BENCHMARK] END');
    debugPrint('');

    return seeds;
  }

  Future<double> readBaseValueForContract(String contractId) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      return 0.0;
    }

    final dfdMainRef = _contractsCol()
        .doc(id)
        .collection('hiring')
        .doc('main')
        .collection('dfd')
        .doc('main');

    final objetoSnap = await dfdMainRef
        .collection(DfdData.sectionObjeto)
        .doc('main')
        .get();

    final objetoData = objetoSnap.data();

    if (objetoData != null) {
      final valorDemanda = _readDouble(objetoData['valorDemanda']);

      if (valorDemanda > 0) {
        return valorDemanda;
      }
    }

    final estimativaSnap = await dfdMainRef
        .collection(DfdData.sectionEstimativa)
        .doc('main')
        .get();

    final estimativaData = estimativaSnap.data();

    if (estimativaData != null) {
      final estimativaValor = _readDouble(estimativaData['estimativaValor']);

      if (estimativaValor > 0) {
        return estimativaValor;
      }
    }

    return 0.0;
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
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'dfdId': cleanDfdId,
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

    if (cleanPath.isEmpty) {
      return false;
    }

    try {
      await _storage.ref(cleanPath).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _contractIdFromTenantPathParts(List<String> pathParts) {
    for (int i = 0; i < pathParts.length - 1; i++) {
      if (pathParts[i] != 'tenants') {
        continue;
      }

      if (i + 3 >= pathParts.length) {
        continue;
      }

      final foundTenantId = pathParts[i + 1].trim();
      final contractsSegment = pathParts[i + 2].trim();
      final contractId = pathParts[i + 3].trim();

      if (foundTenantId == tenantId &&
          contractsSegment == 'contracts' &&
          contractId.isNotEmpty) {
        return contractId;
      }
    }

    return null;
  }

  double _readDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      final parsed = value.toDouble();
      return parsed.isFinite ? parsed : 0.0;
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return 0.0;
      }

      final normalized = text.replaceAll('.', '').replaceAll(',', '.');

      final parsed = double.tryParse(normalized) ??
          double.tryParse(text.replaceAll(',', '.')) ??
          0.0;

      return parsed.isFinite ? parsed : 0.0;
    }

    return 0.0;
  }
}