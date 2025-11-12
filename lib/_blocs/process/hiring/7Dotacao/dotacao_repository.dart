import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'dotacao_sections.dart';

class DotacaoRepository {
  final FirebaseFirestore _db;
  DotacaoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('dotacao');

  Future<({String dotacaoId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final ref = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in DotacaoSections.all) {
      final col = ref.collection(sec);
      final qq = await col.limit(1).get();
      final docRef = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = docRef.id;
    }
    return (dotacaoId: ref.id, sectionIds: sectionIds);
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
        .set(data, SetOptions(merge: true));
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
      batch.set(ref.collection(key).doc(id), data, SetOptions(merge: true));
    });

    await batch.commit();
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dotacaoId,
    required SectionIds sectionIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final ref = _col(contractId).doc(dotacaoId);

    for (final sec in DotacaoSections.all) {
      final id = sectionIds[sec];
      if (id == null) {
        out[sec] = const {};
        continue;
      }
      final snap = await ref.collection(sec).doc(id).get();
      out[sec] = (snap.data() ?? const <String, dynamic>{});
    }
    return out;
  }
}
