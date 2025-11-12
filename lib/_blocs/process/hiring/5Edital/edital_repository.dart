import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'edital_sections.dart';

class EditalRepository {
  final FirebaseFirestore _db;
  EditalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('edital');

  /// Garante doc raiz e 1 doc em cada subcoleção (uma “página” por seção).
  Future<({String editalId, SectionIds sectionIds})> ensureEditalStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final rootRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in EditalSections.all) {
      final col = rootRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }
    return (editalId: rootRef.id, sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String editalId,
    required SectionIds sectionIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final root = _col(contractId).doc(editalId);
    for (final sec in EditalSections.all) {
      final id = sectionIds[sec];
      if (id == null) {
        out[sec] = const {};
        continue;
      }
      final snap = await root.collection(sec).doc(id).get();
      out[sec] = (snap.data() ?? const <String, dynamic>{});
    }
    return out;
  }

  Future<void> saveSection({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) {
    return _col(contractId)
        .doc(editalId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String editalId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final root = _col(contractId).doc(editalId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;
      batch.set(root.collection(key).doc(id), data, SetOptions(merge: true));
    });

    await batch.commit();
  }
}
