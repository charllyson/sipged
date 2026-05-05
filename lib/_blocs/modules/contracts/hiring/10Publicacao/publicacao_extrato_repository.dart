// lib/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'publicacao_extrato_data.dart';
import 'publicacao_extrato_sections.dart';

class PublicacaoExtratoRepository {
  PublicacaoExtratoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('publicacao');
  }

  Future<({String pubId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in PublicacaoExtratoSections.all) section: 'main',
    };

    return (pubId: 'main', sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String pubId,
    required SectionIds sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = pubId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanPubId.isEmpty) {
      throw Exception('pubId não informado.');
    }

    final root = _col(cleanContractId).doc(cleanPubId);

    final entries = await Future.wait(
      sectionIds.entries.map((entry) async {
        final sectionName = entry.key;
        final sectionDocId = entry.value;

        final snap = await root.collection(sectionName).doc(sectionDocId).get();

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
    required String pubId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = pubId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanPubId.isEmpty) {
      throw Exception('pubId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final batch = _db.batch();
    final root = _col(cleanContractId).doc(cleanPubId);

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key;
      final sectionData = entry.value;
      final sectionDocId = sectionIds[sectionKey];

      if (sectionDocId == null || sectionDocId.trim().isEmpty) continue;

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
    required String pubId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = pubId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanPubId.isEmpty) {
      throw Exception('pubId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final ref = _col(cleanContractId)
        .doc(cleanPubId)
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

  Future<PublicacaoExtratoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      pubId: ids.pubId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return PublicacaoExtratoData.fromSectionsMap(sections);
  }
}