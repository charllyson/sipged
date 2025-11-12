// lib/_blocs/process/hiring/1Dfd/dfd_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_sections.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

class DfdRepository {
  final FirebaseFirestore _firestore;
  DfdRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _dfdCol(String contractId) =>
      _firestore.collection('contracts').doc(contractId).collection('dfd');

  /// Garante o doc raiz do DFD e um doc em cada subcoleção de seção.
  Future<({String dfdId, SectionIds sectionIds})> ensureDfdStructure(
      String contractId,
      ) async {
    // Doc raiz
    final dfdQ = await _dfdCol(contractId).limit(1).get();
    final dfdRef = dfdQ.docs.isEmpty
        ? await _dfdCol(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : dfdQ.docs.first.reference;

    // Um doc por seção
    final SectionIds sectionIds = {};
    for (final sec in DfdSections.all) {
      final col = dfdRef.collection(sec);
      final q = await col.limit(1).get();
      final ref = q.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : q.docs.first.reference;
      sectionIds[sec] = ref.id;
    }

    return (dfdId: dfdRef.id, sectionIds: sectionIds);
  }

  /// Salva uma seção específica
  Future<void> saveSection({
    required String contractId,
    required String dfdId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _dfdCol(contractId)
        .doc(dfdId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Salva várias seções em batch
  Future<void> saveSectionsBatch({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _firestore.batch();
    final dfdRef = _dfdCol(contractId).doc(dfdId);

    sectionsData.forEach((sectionKey, data) {
      final id = sectionIds[sectionKey];
      if (id == null) return;
      batch.set(
        dfdRef.collection(sectionKey).doc(id),
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Carrega todos os mapas por seção: {secao: Map}
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final dfdRef = _dfdCol(contractId).doc(dfdId);

    // Varre pelas entries (garante alinhamento exato com IDs criados)
    for (final entry in sectionIds.entries) {
      final sec = entry.key;
      final id  = entry.value;
      final snap = await dfdRef.collection(sec).doc(id).get();
      final data = (snap.data() ?? <String, dynamic>{});
      data.remove('createdAt');
      out[sec] = data;
    }
    return out;
  }
}
