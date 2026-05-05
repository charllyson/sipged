// lib/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'tr_data.dart';
import 'tr_sections.dart';

class TrRepository {
  TrRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('tr');
  }

  Future<({String trId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in TrSections.all) section: 'main',
    };

    return (trId: 'main', sectionIds: sectionIds);
  }

  Future<void> saveSection({
    required String contractId,
    required String trId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw Exception('trId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final ref = _col(cleanContractId)
        .doc(cleanTrId)
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

  Future<void> saveSectionsBatch({
    required String contractId,
    required String trId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw Exception('trId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final batch = _db.batch();
    final trRef = _col(cleanContractId).doc(cleanTrId);

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key;
      final sectionData = entry.value;
      final sectionDocId = sectionIds[sectionKey];

      if (sectionDocId == null || sectionDocId.trim().isEmpty) continue;

      batch.set(
        trRef.collection(sectionKey).doc(sectionDocId),
        <String, dynamic>{
          ...sectionData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String trId,
    required SectionIds sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTrId = trId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTrId.isEmpty) {
      throw Exception('trId não informado.');
    }

    final trRef = _col(cleanContractId).doc(cleanTrId);

    final entries = await Future.wait(
      sectionIds.entries.map((entry) async {
        final sectionName = entry.key;
        final sectionDocId = entry.value;

        final snap = await trRef.collection(sectionName).doc(sectionDocId).get();

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

  Future<TrData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      trId: ids.trId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return TrData.fromSectionsMap(sections);
  }
}