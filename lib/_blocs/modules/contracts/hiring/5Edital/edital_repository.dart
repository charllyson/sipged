
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'edital_data.dart';

class EditalRepository {
  EditalRepository({
    required String tenantId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = _requireTenantId(tenantId);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final String _tenantId;

  static const String _hiringCollectionId = 'hiring';
  static const String _mainDocId = 'main';
  static const String _editalCollectionId = 'edital';

  String get tenantId => _tenantId;

  static String _requireTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em EditalRepository.');
    }

    return cleanTenantId;
  }

  String _requireContractId(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    return cleanContractId;
  }

  String _requireEditalId(String editalId) {
    final cleanEditalId = editalId.trim();

    if (cleanEditalId.isEmpty) {
      throw Exception('editalId não informado.');
    }

    return cleanEditalId;
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

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = _requireContractId(contractId);

    return _contractsCol().doc(cleanContractId);
  }

  DocumentReference<Map<String, dynamic>> _hiringMainDoc(String contractId) {
    return _contractDoc(contractId).collection(_hiringCollectionId).doc(_mainDocId);
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    final cleanContractId = _requireContractId(contractId);

    return _hiringMainDoc(cleanContractId).collection(_editalCollectionId);
  }

  DocumentReference<Map<String, dynamic>> _editalDoc({
    required String contractId,
    required String editalId,
  }) {
    final cleanContractId = _requireContractId(contractId);
    final cleanEditalId = _requireEditalId(editalId);

    return _col(cleanContractId).doc(cleanEditalId);
  }


  String _filesPath({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
  }) {
    final cleanContractId = _requireContractId(contractId);
    final cleanEditalId = _requireEditalId(editalId);
    final cleanSectionKey = _requireSectionKey(sectionKey);
    final cleanSectionDocId = _requireSectionDocId(sectionDocId);

    return 'tenants/$tenantId/contracts/$cleanContractId/'
        'hiring/main/edital/$cleanEditalId/'
        '$cleanSectionKey/$cleanSectionDocId/files';
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
        'tenantId': tenantId,
        'companyId': tenantId,
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

  Future<({String editalId, Map<String, String> sectionIds})>
  ensureEditalStructure(String contractId) async {
    final cleanContractId = _requireContractId(contractId);

    await _ensureHiringMain(cleanContractId);

    final sectionIds = <String, String>{
      for (final section in EditalData.sectionKeys) section: _mainDocId,
    };

    final root = _editalDoc(
      contractId: cleanContractId,
      editalId: _mainDocId,
    );

    await root.set(
      <String, dynamic>{
        'id': _mainDocId,
        'module': _editalCollectionId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'recordPath': root.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return (
    editalId: _mainDocId,
    sectionIds: sectionIds,
    );
  }

  Future<Map<String, EditalData?>> getSummaryForContracts(
      Iterable<String> contractIds, {
        bool debug = false,
      }) async {
    final ids = contractIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final result = <String, EditalData?>{
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
          return MapEntry<String, EditalData?>(contractId, data);
        } catch (error) {
          if (debug) {
            debugPrint(
              '[EditalRepository] Erro summary contractId=$contractId: $error',
            );
          }

          return MapEntry<String, EditalData?>(contractId, null);
        }
      }),
    );

    for (final entry in entries) {
      result[entry.key] = entry.value;
    }

    sw.stop();

    if (debug) {
      final loaded = result.values.whereType<EditalData>().length;

      debugPrint(
        '[EditalRepository] getSummaryForContracts '
            'tenantId=$tenantId contratos=${ids.length} '
            'comDados=$loaded em ${sw.elapsedMilliseconds}ms',
      );
    }

    return result;
  }

  Future<EditalData?> readSummaryForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final rootRef = _editalDoc(
      contractId: cleanContractId,
      editalId: _mainDocId,
    );

    final rootSnap = await rootRef.get();
    final rootData = rootSnap.data();

    if (rootData != null && rootData.isNotEmpty) {
      final cleanRoot = Map<String, dynamic>.from(rootData);
      _removeSystemFields(cleanRoot);

      final hasFlatSummary = _hasAnyValue(
        cleanRoot,
        const <String>[
          'numero',
          'modalidade',
          'criterio',
          'idPncp',
          'linkPncp',
          'dataPublicacao',
          'dataSessao',
          'horaSessao',
          'vencedor',
          'valorVencedor',
          'linksDocumentos',
        ],
      );

      if (hasFlatSummary) {
        return EditalData.fromMap(cleanRoot);
      }
    }

    final sections = await _loadSummarySections(cleanContractId);

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return EditalData.fromSectionsMap(sections);
  }

  Future<Map<String, Map<String, dynamic>>> _loadSummarySections(
      String contractId,
      ) async {
    final root = _editalDoc(
      contractId: contractId,
      editalId: _mainDocId,
    );

    final keys = <String>[
      EditalData.sectionDivulgacao,
      EditalData.sectionSessao,
      EditalData.sectionJulgamento,
      EditalData.sectionResultado,
      EditalData.sectionRecursos,
      EditalData.sectionDocumentos,
    ];

    final entries = await Future.wait(
      keys.map((sectionKey) async {
        final snap = await root.collection(sectionKey).doc(_mainDocId).get();

        final data = Map<String, dynamic>.from(
          snap.data() ?? const <String, dynamic>{},
        );

        _removeSystemFields(data);

        return MapEntry<String, Map<String, dynamic>>(sectionKey, data);
      }),
    );

    return <String, Map<String, dynamic>>{
      for (final entry in entries) entry.key: entry.value,
    };
  }

  Future<Map<String, Map<String, dynamic>>> loadAllSections({
    required String contractId,
    required String editalId,
    required Map<String, String> sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = editalId.trim();

    if (cleanContractId.isEmpty) throw Exception('contractId não informado.');
    if (cleanEditalId.isEmpty) throw Exception('editalId não informado.');

    final root = _col(cleanContractId).doc(cleanEditalId);

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
    required String editalId,
    required Map<String, String> sectionIds,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = editalId.trim();

    if (cleanContractId.isEmpty) throw Exception('contractId não informado.');
    if (cleanEditalId.isEmpty) throw Exception('editalId não informado.');
    if (sectionsData.isEmpty) return;

    await _ensureHiringMain(cleanContractId);

    final root = _col(cleanContractId).doc(cleanEditalId);
    final hiringRef = _hiringMainDoc(cleanContractId);

    final batch = _db.batch();

    final summary = EditalData.fromSectionsMap(sectionsData).toMap()
      ..removeWhere((_, value) => value == null);

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
      hiringRef,
      <String, dynamic>{
        'id': _mainDocId,
        'module': _hiringCollectionId,
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
        'id': cleanEditalId,
        'module': _editalCollectionId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
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

      final sectionData = Map<String, dynamic>.from(entry.value);
      _removeWriteProtectedFields(sectionData);

      final ref = root.collection(sectionKey).doc(sectionDocId);

      batch.set(
        ref,
        <String, dynamic>{
          ...sectionData,
          'id': sectionDocId,
          'module': _editalCollectionId,
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'editalId': cleanEditalId,
          'sectionKey': sectionKey,
          'recordPath': ref.path,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> saveSection({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = editalId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) throw Exception('contractId não informado.');
    if (cleanEditalId.isEmpty) throw Exception('editalId não informado.');
    if (cleanSectionKey.isEmpty) throw Exception('sectionKey não informado.');
    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    await _ensureHiringMain(cleanContractId);

    final cleanData = Map<String, dynamic>.from(data);
    _removeWriteProtectedFields(cleanData);

    final root = _col(cleanContractId).doc(cleanEditalId);
    final hiringRef = _hiringMainDoc(cleanContractId);
    final ref = root.collection(cleanSectionKey).doc(cleanSectionDocId);

    final rootSummary = _summaryRootFieldsFromSingleSection(
      sectionKey: cleanSectionKey,
      data: cleanData,
    );

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
      hiringRef,
      <String, dynamic>{
        'id': _mainDocId,
        'module': _hiringCollectionId,
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
        'id': cleanEditalId,
        'module': _editalCollectionId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
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
        'module': _editalCollectionId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'editalId': cleanEditalId,
        'sectionKey': cleanSectionKey,
        'recordPath': ref.path,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<EditalData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureEditalStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      editalId: ids.editalId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return EditalData.fromSectionsMap(sections);
  }

  Future<List<Attachment>> listFiles({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = editalId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty ||
        cleanEditalId.isEmpty ||
        cleanSectionKey.isEmpty ||
        cleanSectionDocId.isEmpty) {
      return const <Attachment>[];
    }

    final result = await _storage
        .ref(
      _filesPath(
        contractId: cleanContractId,
        editalId: cleanEditalId,
        sectionKey: cleanSectionKey,
        sectionDocId: cleanSectionDocId,
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

  Future<Attachment> uploadFile({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
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
    final cleanEditalId = editalId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty ||
        cleanEditalId.isEmpty ||
        cleanSectionKey.isEmpty ||
        cleanSectionDocId.isEmpty) {
      throw Exception('Caminho inválido para upload do edital.');
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
        editalId: cleanEditalId,
        sectionKey: cleanSectionKey,
        sectionDocId: cleanSectionDocId,
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
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'editalId': cleanEditalId,
          'sectionKey': cleanSectionKey,
          'sectionDocId': cleanSectionDocId,
          'module': _editalCollectionId,
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

  Future<bool> deleteFile({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = editalId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanEditalId.isEmpty ||
        cleanSectionKey.isEmpty ||
        cleanSectionDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      await _storage
          .ref(
        '${_filesPath(
          contractId: cleanContractId,
          editalId: cleanEditalId,
          sectionKey: cleanSectionKey,
          sectionDocId: cleanSectionDocId,
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

  Map<String, dynamic> _summaryRootFieldsFromSingleSection({
    required String sectionKey,
    required Map<String, dynamic> data,
  }) {
    switch (sectionKey) {
      case EditalData.sectionDivulgacao:
        return <String, dynamic>{
          if (data.containsKey('numero')) 'numero': data['numero'],
          if (data.containsKey('modalidade')) 'modalidade': data['modalidade'],
          if (data.containsKey('criterio')) 'criterio': data['criterio'],
          if (data.containsKey('idPncp')) 'idPncp': data['idPncp'],
          if (data.containsKey('linkPncp')) 'linkPncp': data['linkPncp'],
          if (data.containsKey('linkSei')) 'linkSei': data['linkSei'],
          if (data.containsKey('linksPublicacoes'))
            'linksPublicacoes': data['linksPublicacoes'],
          if (data.containsKey('dataPublicacao'))
            'dataPublicacao': data['dataPublicacao'],
          if (data.containsKey('prazoImpugnacao'))
            'prazoImpugnacao': data['prazoImpugnacao'],
          if (data.containsKey('prazoPropostas'))
            'prazoPropostas': data['prazoPropostas'],
          if (data.containsKey('observacoes')) 'observacoes': data['observacoes'],
        };

      case EditalData.sectionSessao:
        return <String, dynamic>{
          if (data.containsKey('dataSessao')) 'dataSessao': data['dataSessao'],
          if (data.containsKey('horaSessao')) 'horaSessao': data['horaSessao'],
          if (data.containsKey('responsavel')) 'responsavel': data['responsavel'],
          if (data.containsKey('localPlataforma'))
            'localPlataforma': data['localPlataforma'],
        };

      case EditalData.sectionJulgamento:
        return <String, dynamic>{
          if (data.containsKey('parecer')) 'parecer': data['parecer'],
          if (data.containsKey('criterioAplicado'))
            'criterioAplicado': data['criterioAplicado'],
          if (data.containsKey('linkAta')) 'linkAta': data['linkAta'],
          if (data.containsKey('recursosHouve'))
            'recursosHouve': data['recursosHouve'],
          if (data.containsKey('decisaoRecursos'))
            'decisaoRecursos': data['decisaoRecursos'],
          if (data.containsKey('linksRecursos'))
            'linksRecursos': data['linksRecursos'],
        };

      case EditalData.sectionResultado:
        return <String, dynamic>{
          if (data.containsKey('vencedor')) 'vencedor': data['vencedor'],
          if (data.containsKey('vencedorCnpj'))
            'vencedorCnpj': data['vencedorCnpj'],
          if (data.containsKey('valorVencedor'))
            'valorVencedor': data['valorVencedor'],
          if (data.containsKey('dataResultado'))
            'dataResultado': data['dataResultado'],
          if (data.containsKey('adjudicacaoData'))
            'adjudicacaoData': data['adjudicacaoData'],
          if (data.containsKey('adjudicacaoLink'))
            'adjudicacaoLink': data['adjudicacaoLink'],
          if (data.containsKey('homologacaoData'))
            'homologacaoData': data['homologacaoData'],
          if (data.containsKey('homologacaoLink'))
            'homologacaoLink': data['homologacaoLink'],
          if (data.containsKey('highlightWinner'))
            'highlightWinner': data['highlightWinner'],
          if (data.containsKey('habilitarSomenteVencedor'))
            'habilitarSomenteVencedor': data['habilitarSomenteVencedor'],
        };

      case EditalData.sectionRecursos:
        return <String, dynamic>{
          if (data.containsKey('houve')) 'recursosHouve': data['houve'],
          if (data.containsKey('decisao')) 'decisaoRecursos': data['decisao'],
          if (data.containsKey('links')) 'linksRecursos': data['links'],
        };

      case EditalData.sectionDocumentos:
        return <String, dynamic>{
          if (data.containsKey('linksDocumentos'))
            'linksDocumentos': data['linksDocumentos'],
        };

      case EditalData.sectionObservacoes:
        return <String, dynamic>{
          if (data.containsKey('observacoes')) 'observacoes': data['observacoes'],
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
    data.remove('id');
    data.remove('editalId');
    data.remove('sectionKey');
  }
}