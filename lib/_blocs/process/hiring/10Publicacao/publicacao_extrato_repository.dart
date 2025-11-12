import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'publicacao_extrato_sections.dart';

class PublicacaoExtratoRepository {
  final FirebaseFirestore _db;
  PublicacaoExtratoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('publicacao');

  Future<({String pubId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final pubRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in PublicacaoExtratoSections.all) {
      final col = pubRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }
    return (pubId: pubRef.id, sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String pubId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final pubRef = _col(contractId).doc(pubId);

    for (final entry in sectionIds.entries) {
      final secName = entry.key;
      final secId = entry.value;
      final snap = await pubRef.collection(secName).doc(secId).get();
      final data = snap.data() ?? <String, dynamic>{};
      data.remove('createdAt');
      out[secName] = data;
    }
    return out;
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String pubId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final pubRef = _col(contractId).doc(pubId);
    final wb = _db.batch();

    sectionsData.forEach((sec, data) {
      final id = sectionIds[sec];
      if (id == null) return;
      final ref = pubRef.collection(sec).doc(id);
      wb.set(
        ref,
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await wb.commit();
  }

  Future<void> saveSection({
    required String contractId,
    required String pubId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _col(contractId).doc(pubId).collection(sectionKey).doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
