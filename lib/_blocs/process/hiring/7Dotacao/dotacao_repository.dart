// lib/_blocs/process/hiring/7Dotacao/dotacao_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'dotacao_sections.dart';

class DotacaoRepository {
  final FirebaseFirestore _db;
  DotacaoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('dotacao');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA (mesmo padrão do DFD)
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Nenhuma leitura prévia; só monta em memória.
  /// ===========================================================================
  Future<({String dotacaoId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in DotacaoSections.all) sec: 'main',
    };
    return (dotacaoId: 'main', sectionIds: sectionIds);
  }

  Future<void> saveSection({
    required String contractId,
    required String dotacaoId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _col(contractId)
        .doc(dotacaoId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String dotacaoId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final ref = _col(contractId).doc(dotacaoId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;
      batch.set(
        ref.collection(key).doc(id),
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dotacaoId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final ref = _col(contractId).doc(dotacaoId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await ref.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }
}
