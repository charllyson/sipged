// lib/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'publicacao_extrato_sections.dart';
import 'publicacao_extrato_data.dart';

class PublicacaoExtratoRepository {
  final FirebaseFirestore _db;
  PublicacaoExtratoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('publicacao');


  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Portanto:
  ///   - NÃO fazemos nenhum acesso ao Firestore aqui
  ///   - NÃO migramos nada
  ///   - apenas montamos os IDs fixos em memória
  /// ===========================================================================
  Future<({String pubId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in PublicacaoExtratoSections.all) sec: 'main',
    };
    return (pubId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  ///   - Usa Future.wait para ler todas as seções em paralelo
  ///   - Remove createdAt/updatedAt antes de devolver
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String pubId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final pubRef = _col(contractId).doc(pubId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await pubRef.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }

  Future<void> saveSectionsBatch({
    required String contractId,
    required String pubId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final pubRef = _col(contractId).doc(pubId);
    final wb = _db.batch();

    sectionsData.forEach((sec, data) {
      final id = sectionIds[sec];
      if (id == null) return;
      final ref = pubRef.collection(sec).doc(id);
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
    required String pubId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(pubId).collection(sectionKey).doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Leitura direta de um PublicacaoExtratoData completo para o contrato
  ///
  ///   - assume sempre pubId = "main" e sectionId = "main"
  ///   - lê todas as seções em paralelo
  ///   - se TODAS as seções vierem vazias, retorna null
  Future<PublicacaoExtratoData?> readDataForContract(
      String contractId,
      ) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      pubId: ids.pubId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return PublicacaoExtratoData.fromSectionsMap(sections);
  }
}
