// lib/_blocs/modules/contracts/hiring/3Cotacao/cotacao_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_sections.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class CotacaoRepository {
  final FirebaseFirestore _db;
  CotacaoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('cotacao');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA (mesmo padrão do DFD/TR)
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Não faz leitura nem criação prévia no Firestore, apenas monta em memória.
  /// ===========================================================================
  Future<({String cotacaoId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in CotacaoSections.all) sec: 'main',
    };
    return (cotacaoId: 'main', sectionIds: sectionIds);
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
        .set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
      batch.set(
        ref.collection(key).doc(id),
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Carrega todas as seções (padrão DFD/TR: Future.wait + limpa campos técnicos)
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String cotacaoId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final ref = _col(contractId).doc(cotacaoId);

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

  /// Leitura direta de uma CotacaoData completa para o contrato
  ///
  /// - chama ensureStructure (cotacaoId = "main" e sectionIds = {sec: "main"})
  /// - lê todas as seções
  /// - se tudo estiver vazio, retorna null
  /// - monta CotacaoData.fromSectionsMap(sections)
  Future<CotacaoData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      cotacaoId: ids.cotacaoId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return CotacaoData.fromSectionsMap(sections);
  }
}
