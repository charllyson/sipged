// lib/_blocs/process/hiring/8Minuta/minuta_contrato_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'minuta_contrato_sections.dart';
import 'minuta_contrato_data.dart'; // 🆕 modelo para readDataForContract

class MinutaContratoRepository {
  final FirebaseFirestore _db;
  MinutaContratoRepository({FirebaseFirestore? db, FirebaseFirestore? firestore})
      : _db = db ?? firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('minuta');

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
  Future<({String minutaId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in MinutaSections.all) sec: 'main',
    };
    return (minutaId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  /// Agora:
  ///   - Usa Future.wait para ler todas as seções em paralelo
  ///   - Remove createdAt/updatedAt antes de devolver
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String minutaId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final ref = _col(contractId).doc(minutaId);

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
    required String minutaId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(minutaId).collection(sectionKey).doc(sectionDocId);

    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(), // 🆕
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String minutaId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final ref = _col(contractId).doc(minutaId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return; // robustez

      final docRef = ref.collection(key).doc(id);
      batch.set(
        docRef,
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(), // 🆕
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Leitura direta de uma MinutaContratoData completa para o contrato
  ///
  /// Igual ao DfdRepository/HabilitacaoRepository:
  ///   - assume sempre minutaId = "main" e sectionId = "main"
  ///   - lê todas as seções em paralelo
  ///   - se TODAS as seções vierem vazias, retorna null
  Future<MinutaContratoData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      minutaId: ids.minutaId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return MinutaContratoData.fromSectionsMap(sections);
  }
}
