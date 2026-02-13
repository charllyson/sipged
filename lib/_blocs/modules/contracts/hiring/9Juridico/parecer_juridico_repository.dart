// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'parecer_juridico_sections.dart';
import 'parecer_juridico_data.dart'; // 🆕 para readDataForContract

class ParecerJuridicoRepository {
  final FirebaseFirestore _db;
  ParecerJuridicoRepository({FirebaseFirestore? db, FirebaseFirestore? firestore})
      : _db = db ?? firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('parecer');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Portanto:
  ///   - NÃO fazemos nenhum acesso ao Firestore aqui
  ///   - somento montamos os IDs fixos em memória
  /// ===========================================================================
  Future<({String parecerId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in ParecerSections.all) sec: 'main',
    };
    return (parecerId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  ///   - Usa Future.wait para ler todas as seções em paralelo
  ///   - Remove createdAt/updatedAt antes de devolver
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String parecerId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final ref = _col(contractId).doc(parecerId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await ref.collection(secName).doc(secId).get();
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
    required String parecerId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(parecerId).collection(sectionKey).doc(sectionDocId);

    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(), // 🆕 padrão
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String parecerId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final ref = _col(contractId).doc(parecerId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return; // robustez

      final docRef = ref.collection(key).doc(id);
      batch.set(
        docRef,
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(), // 🆕 padrão
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Leitura direta de um ParecerJuridicoData completo para o contrato
  ///
  ///   - assume sempre parecerId = "main" e sectionId = "main"
  ///   - lê todas as seções em paralelo
  ///   - se TODAS as seções vierem vazias, retorna null
  Future<ParecerJuridicoData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      parecerId: ids.parecerId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return ParecerJuridicoData.fromSectionsMap(sections);
  }
}
