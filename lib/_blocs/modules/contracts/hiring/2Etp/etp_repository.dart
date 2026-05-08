// lib/_blocs/modules/contracts/hiring/2Etp/etp_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/sections_types.dart';

import 'etp_data.dart';
import 'etp_sections.dart';

class EtpRepository {
  EtpRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('etp');
  }

  Future<({String etpId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final id = contractId.trim();

    if (id.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in EtpSections.all) section: 'main',
    };

    return (etpId: 'main', sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String etpId,
    required SectionIds sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEtpId = etpId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanEtpId.isEmpty) {
      throw Exception('etpId não informado.');
    }

    final etpRef = _col(cleanContractId).doc(cleanEtpId);

    final entries = await Future.wait(
      sectionIds.entries.map((entry) async {
        final sectionName = entry.key;
        final sectionDocId = entry.value;

        final snap = await etpRef.collection(sectionName).doc(sectionDocId).get();

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
    required String etpId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEtpId = etpId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanEtpId.isEmpty) {
      throw Exception('etpId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final etpRef = _col(cleanContractId).doc(cleanEtpId);
    final batch = _db.batch();

    for (final entry in sectionsData.entries) {
      final sectionKey = entry.key;
      final sectionData = entry.value;
      final sectionDocId = sectionIds[sectionKey];

      if (sectionDocId == null || sectionDocId.trim().isEmpty) continue;

      final ref = etpRef.collection(sectionKey).doc(sectionDocId);

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
    required String etpId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEtpId = etpId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanEtpId.isEmpty) {
      throw Exception('etpId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final ref = _col(cleanContractId)
        .doc(cleanEtpId)
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

  Future<EtpData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      etpId: ids.etpId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return EtpData.fromSectionsMap(sections);
  }
}