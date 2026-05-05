// lib/_blocs/modules/contracts/hiring/10Arquivamento/termo_arquivamento_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'termo_arquivamento_data.dart';
import 'termo_arquivamento_sections.dart';

class TermoArquivamentoRepository {
  TermoArquivamentoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('arquivamento');
  }

  /// Estrutura fixa:
  /// - doc raiz: main
  /// - cada seção: doc main
  Future<({String taId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    final sectionIds = <String, String>{
      for (final section in TermoArquivamentoSections.all) section: 'main',
    };

    return (taId: 'main', sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String taId,
    required SectionIds sectionIds,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTaId.isEmpty) {
      throw Exception('taId não informado.');
    }

    final root = _col(cleanContractId).doc(cleanTaId);

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
    required String taId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTaId.isEmpty) {
      throw Exception('taId não informado.');
    }

    if (sectionsData.isEmpty) return;

    final batch = _db.batch();
    final root = _col(cleanContractId).doc(cleanTaId);

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
    required String taId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = taId.trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId = sectionDocId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanTaId.isEmpty) {
      throw Exception('taId não informado.');
    }

    if (cleanSectionKey.isEmpty) {
      throw Exception('sectionKey não informado.');
    }

    if (cleanSectionDocId.isEmpty) {
      throw Exception('sectionDocId não informado.');
    }

    final ref = _col(cleanContractId)
        .doc(cleanTaId)
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

  Future<TermoArquivamentoData?> readDataForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final ids = await ensureStructure(cleanContractId);

    final sections = await loadAllSections(
      contractId: cleanContractId,
      taId: ids.taId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((map) => map.isNotEmpty);

    if (!hasAnyData) return null;

    return TermoArquivamentoData.fromSectionsMap(sections);
  }
}