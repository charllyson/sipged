import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'dfd_sections.dart';
import 'dfd_data.dart';

class DfdRepository {
  final FirebaseFirestore _db;
  DfdRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('dfd');

  /// Estrutura fixa:
  ///   - doc DFD sempre "main"
  ///   - cada seção sempre doc "main"
  Future<({String dfdId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in DfdSections.all) sec: 'main',
    };
    return (dfdId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final dfdRef = _col(contractId).doc(dfdId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await dfdRef.collection(secName).doc(secId).get();
      final data = Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final dfdRef = _col(contractId).doc(dfdId);
    final wb = _db.batch();

    sectionsData.forEach((sec, data) {
      final id = sectionIds[sec];
      if (id == null) return;

      final ref = dfdRef.collection(sec).doc(id);
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
    required String dfdId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(dfdId).collection(sectionKey).doc(sectionDocId);

    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Leitura direta de um DfdData completo para o contrato
  Future<DfdData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return DfdData.fromSectionsMap(
      sections,
      contractId: contractId, // runtime only
    );
  }

  /// Cria (se necessário) o contrato e salva o DFD completo.
  Future<String> ensureContractAndSaveDfd({
    String? contractId,
    required DfdData data,
  }) async {
    String effectiveId = (contractId ?? '').trim();

    if (effectiveId.isEmpty) {
      final contractsRef = _db.collection('contracts');
      final docRef = await contractsRef.add({
        'createdAt': FieldValue.serverTimestamp(),
      });
      effectiveId = docRef.id;
    }

    final ids = await ensureStructure(effectiveId);

    await saveSectionsBatch(
      contractId: effectiveId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
      sectionsData: data.toSectionsMap(), // contractId não é persistido
    );

    return effectiveId;
  }
}
