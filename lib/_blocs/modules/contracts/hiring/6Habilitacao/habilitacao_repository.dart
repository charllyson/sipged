// lib/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'habilitacao_sections.dart';
import 'habilitacao_data.dart'; // 🆕 para readDataForContract

class HabilitacaoRepository {
  final FirebaseFirestore _db;
  HabilitacaoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('habilitacao');

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
  Future<({String habId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in HabilitacaoSections.all) sec: 'main',
    };
    return (habId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  /// Agora:
  ///   - Usa Future.wait para ler todas as seções em paralelo
  ///   - Remove createdAt/updatedAt antes de devolver
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String habId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final habRef = _col(contractId).doc(habId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await habRef.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      // mesma limpeza feita no DfdRepository
      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }

  Future<void> saveSection({
    required String contractId,
    required String habId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(habId).collection(sectionKey).doc(sectionDocId);

    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(), // 🆕 igual DFD
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String habId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final habRef = _col(contractId).doc(habId);
    final batch = _db.batch();

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;

      final ref = habRef.collection(key).doc(id);
      batch.set(
        ref,
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(), // 🆕 igual DFD
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Leitura direta de um HabilitacaoData completo para o contrato
  ///
  /// Igual ao DfdRepository.readDataForContract:
  ///   - assume sempre habId = "main" e sectionId = "main"
  ///   - lê todas as seções em paralelo
  ///   - se TODAS as seções vierem vazias, retorna null
  Future<HabilitacaoData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      habId: ids.habId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return HabilitacaoData.fromSectionsMap(sections);
  }
}
