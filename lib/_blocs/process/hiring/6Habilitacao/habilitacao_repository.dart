import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'habilitacao_sections.dart';

class HabilitacaoRepository {
  final FirebaseFirestore _db;
  HabilitacaoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('habilitacao');

  /// Garante Habilitação + subcoleções por seção (1 doc por seção)
  Future<({String habId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final habRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in HabilitacaoSections.all) {
      final col = habRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }
    return (habId: habRef.id, sectionIds: sectionIds);
  }

  Future<void> saveSection({
    required String contractId,
    required String habId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _col(contractId)
        .doc(habId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String habId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final habRef = _col(contractId).doc(habId);
    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;
      batch.set(habRef.collection(key).doc(id), data, SetOptions(merge: true));
    });
    await batch.commit();
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String habId,
    required SectionIds sectionIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final habRef = _col(contractId).doc(habId);
    for (final sec in HabilitacaoSections.all) {
      final id = sectionIds[sec];
      if (id == null) {
        out[sec] = const {};
        continue;
      }
      final snap = await habRef.collection(sec).doc(id).get();
      out[sec] = (snap.data() ?? const <String, dynamic>{});
    }
    return out;
  }
}
