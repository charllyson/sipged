import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'tr_sections.dart';

class TrRepository {
  final FirebaseFirestore _db;
  TrRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('tr');

  /// Garante a estrutura TR + subcoleções
  Future<({String trId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final trRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in TrSections.all) {
      final col = trRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }

    return (trId: trRef.id, sectionIds: sectionIds);
  }

  /// Salva uma única seção
  Future<void> saveSection({
    required String contractId,
    required String trId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _col(contractId)
        .doc(trId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(data, SetOptions(merge: true));
  }

  /// Salva várias seções de uma vez (batch)
  Future<void> saveSectionsBatch({
    required String contractId,
    required String trId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final trRef = _col(contractId).doc(trId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;
      batch.set(trRef.collection(key).doc(id), data, SetOptions(merge: true));
    });

    await batch.commit();
  }

  /// Carrega todas as seções do TR
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String trId,
    required SectionIds sectionIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final trRef = _col(contractId).doc(trId);

    for (final sec in TrSections.all) {
      final id = sectionIds[sec];
      if (id == null) {
        out[sec] = const {};
        continue;
      }
      final snap = await trRef.collection(sec).doc(id).get();
      out[sec] = (snap.data() ?? const <String, dynamic>{});
    }

    return out;
  }
}
