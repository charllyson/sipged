// lib/_blocs/modules/contracts/hiring/2Tr/tr_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/3Tr/tr_sections.dart';
import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class TrRepository {
  final FirebaseFirestore _db;
  TrRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('tr');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA (mesmo padrão do DFD)
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Não faz nenhuma leitura/criação prévia no Firestore, apenas monta em memória.
  /// ===========================================================================
  Future<({String trId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in TrSections.all) sec: 'main',
    };
    return (trId: 'main', sectionIds: sectionIds);
  }

  /// Salva uma única seção
  Future<void> saveSection({
    required String contractId,
    required String trId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _col(contractId)
        .doc(trId)
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

  /// Salva várias seções de uma vez (batch), adicionando updatedAt
  Future<void> saveSectionsBatch({
    required String contractId,
    required String trId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _db.batch();
    final trRef = _col(contractId).doc(trId);

    sectionsData.forEach((key, data) {
      final id = sectionIds[key];
      if (id == null) return;
      batch.set(
        trRef.collection(key).doc(id),
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Carrega todas as seções do TR
  ///
  /// Mesmo padrão do DFD:
  ///   - lê tudo em paralelo com Future.wait
  ///   - remove createdAt/updatedAt antes de devolver
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String trId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final trRef = _col(contractId).doc(trId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await trRef.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }

  /// Leitura direta de um TrData completo para o contrato (útil pra dashboards etc.)
  ///
  /// Padrão idêntico ao DFD:
  ///   - chama ensureStructure (trId = "main", sectionIds = {sec: "main"})
  ///   - carrega todas as seções
  ///   - se estiver tudo vazio, retorna null
  ///   - monta um TrData a partir das seções
  Future<TrData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      trId: ids.trId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return TrData.fromSectionsMap(sections);
  }
}
