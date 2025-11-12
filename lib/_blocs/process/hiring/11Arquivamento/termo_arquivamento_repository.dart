import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'termo_arquivamento_sections.dart';

class TermoArquivamentoRepository {
  final FirebaseFirestore _db;
  TermoArquivamentoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('arquivamento');

  Future<({String taId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final q = await _col(contractId).limit(1).get();
    final taRef = q.docs.isEmpty
        ? await _col(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : q.docs.first.reference;

    final SectionIds sectionIds = {};
    for (final sec in TermoArquivamentoSections.all) {
      final col = taRef.collection(sec);
      final qq = await col.limit(1).get();
      final ref = qq.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : qq.docs.first.reference;
      sectionIds[sec] = ref.id;
    }
    return (taId: taRef.id, sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String taId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final taRef = _col(contractId).doc(taId);

    for (final entry in sectionIds.entries) {
      final secName = entry.key;
      final secId = entry.value;
      final snap = await taRef.collection(secName).doc(secId).get();
      final data = snap.data() ?? <String, dynamic>{};
      data.remove('createdAt');
      out[secName] = data;
    }
    return out;
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String taId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final taRef = _col(contractId).doc(taId);
    final wb = _db.batch();

    sectionsData.forEach((sec, data) {
      final id = sectionIds[sec];
      if (id == null) return;
      final ref = taRef.collection(sec).doc(id);
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
    required String taId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _col(contractId).doc(taId).collection(sectionKey).doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
