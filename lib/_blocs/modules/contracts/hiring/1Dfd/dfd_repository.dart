// lib/_blocs/modules/contracts/hiring/dfd/dfd_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'dfd_data.dart';
import 'dfd_sections.dart';

class DfdRepository {
  DfdRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('dfd');
  }

  Future<({String dfdId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in DfdSections.all) section: 'main',
    };

    return (dfdId: 'main', sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
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
        final sectionName = entry.key;
        final sectionDocId = entry.value;

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
      for (final entry in entries) entry.key: entry.value,
    };
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
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
      final sectionKey = entry.key;
      final sectionData = entry.value;
      final sectionDocId = sectionIds[sectionKey];

      if (sectionDocId == null || sectionDocId.trim().isEmpty) continue;

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

    final ref = _col(cleanContractId)
        .doc(cleanDfdId)
        .collection(cleanSectionKey)
        .doc(cleanSectionDocId);

    await ref.set(
      <String, dynamic>{
        ...data,
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
        .collectionGroup(DfdSections.localizacao)
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
        .collection(DfdSections.objeto)
        .doc('main');

    final snap = await ref.get();
    final data = snap.data();

    if (data == null) return 0.0;

    final valorDemanda = _readDouble(data['valorDemanda']);
    if (valorDemanda > 0) return valorDemanda;

    return _readDouble(data['estimativaValor']);
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