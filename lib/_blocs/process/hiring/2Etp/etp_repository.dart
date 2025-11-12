import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'etp_sections.dart';

class EtpRepository {
  final FirebaseFirestore _db;
  EtpRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('etp');

  /// Garante a estrutura básica: ETP + subcoleções de seções
  Future<({String etpId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final etpRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in EtpSections.all) {
      final col = etpRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }

    return (etpId: etpRef.id, sectionIds: sectionIds);
  }

  /// Salva uma única seção
  Future<void> saveSection({
    required String contractId,
    required String etpId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _col(contractId)
        .doc(etpId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(data, SetOptions(merge: true));
  }

  /// Salva todas as seções em lote (batch)
  Future<void> saveSectionsBatch({
    required String contractId,
    required String etpId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final etpRef = _col(contractId).doc(etpId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return; // ignora chaves desconhecidas
      batch.set(etpRef.collection(key).doc(id), data, SetOptions(merge: true));
    });

    await batch.commit();
  }

  /// Carrega todos os documentos das subcoleções do ETP
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String etpId,
    required SectionIds sectionIds,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final etpRef = _col(contractId).doc(etpId);

    for (final sec in EtpSections.all) {
      final id = sectionIds[sec];
      if (id == null) {
        out[sec] = const {};
        continue;
      }
      final snap = await etpRef.collection(sec).doc(id).get();
      out[sec] = (snap.data() ?? const <String, dynamic>{});
    }

    return out;
  }
}
