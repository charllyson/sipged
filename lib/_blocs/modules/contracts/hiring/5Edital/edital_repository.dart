// lib/_blocs/modules/contracts/hiring/5Edital/edital_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'edital_sections.dart';
import 'edital_data.dart'; // 👈 modelo tipado do Edital

class EditalRepository {
  final FirebaseFirestore _db;
  EditalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('edital');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Portanto:
  ///   - NÃO fazemos acesso ao Firestore aqui
  ///   - NÃO migramos nada
  /// ===========================================================================
  Future<({String editalId, SectionIds sectionIds})> ensureEditalStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in EditalSections.all) sec: 'main',
    };
    return (editalId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  ///   - leituras em paralelo
  ///   - remove createdAt/updatedAt
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String editalId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final root = _col(contractId).doc(editalId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await root.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }

  Future<void> saveSection({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(editalId).collection(sectionKey).doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
      final ref = root.collection(key).doc(id);
      batch.set(
        ref,
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  // ===========================================================================
  // Leitura direta de um EditalData completo para o contrato
  // ===========================================================================
  Future<EditalData?> readDataForContract(String contractId) async {
    final ids = await ensureEditalStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      editalId: ids.editalId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return EditalData.fromSectionsMap(sections);
  }
}
