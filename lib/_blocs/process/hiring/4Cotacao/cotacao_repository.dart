import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'cotacao_sections.dart';

class CotacaoRepository {
  final FirebaseFirestore _db;
  CotacaoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('cotacao');

  /// Garante 1 doc de cotação + 1 doc em cada subcoleção (seção)
  Future<({String cotacaoId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final cotRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in CotacaoSections.all) {
      final col = cotRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }
    return (cotacaoId: cotRef.id, sectionIds: sectionIds);
  }

  /// Salva uma seção específica
  Future<void> saveSection({
    required String contractId,
    required String cotacaoId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _col(contractId)
        .doc(cotacaoId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(data, SetOptions(merge: true));
  }

  /// Salva várias seções de uma vez (batch)
  Future<void> saveSectionsBatch({
    required String contractId,
    required String cotacaoId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final ref = _col(contractId).doc(cotacaoId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;
      batch.set(ref.collection(key).doc(id), data, SetOptions(merge: true));
    });

    await batch.commit();
  }

  /// Carrega todas as seções
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String cotacaoId,
    required SectionIds sectionIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final ref = _col(contractId).doc(cotacaoId);

    for (final sec in CotacaoSections.all) {
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
