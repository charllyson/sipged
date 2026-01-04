// lib/_blocs/process/hiring/2Etp/etp_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'etp_sections.dart';
import 'etp_data.dart';

class EtpRepository {
  final FirebaseFirestore _db;
  EtpRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('etp');

  /// Doc principal do ETP: contracts/{contractId}/etp/main
  DocumentReference<Map<String, dynamic>> _etpDoc(String contractId) =>
      _col(contractId).doc('main');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA (igual ao DFD)
  ///
  /// Agora assumimos que:
  ///   - o doc raiz SEMPRE é "main"
  ///   - cada seção tem SEMPRE um doc "main" na subcoleção
  ///
  /// Portanto:
  ///   - NÃO fazemos nenhum acesso ao Firestore aqui
  ///   - NÃO migramos nada
  ///   - somente montamos os IDs fixos em memória
  /// ===========================================================================
  Future<({String etpId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in EtpSections.all) sec: 'main',
    };
    return (etpId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  ///   - Usa Future.wait para ler todas as seções em paralelo
  ///   - Remove createdAt/updatedAt antes de devolver (mesmo padrão do DFD)
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String etpId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final etpRef = _col(contractId).doc(etpId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await etpRef.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
    return out;
  }

  /// Salva todas as seções em lote (batch), com updatedAt (padrão DFD)
  Future<void> saveSectionsBatch({
    required String contractId,
    required String etpId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final etpRef = _col(contractId).doc(etpId);
    final wb = _db.batch();

    sectionsData.forEach((sec, data) {
      final id = sectionIds[sec];
      if (id == null) return;
      final ref = etpRef.collection(sec).doc(id);
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

  /// Salva uma única seção (com updatedAt)
  Future<void> saveSection({
    required String contractId,
    required String etpId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(etpId).collection(sectionKey).doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Leitura direta de um EtpData completo para o contrato (útil pra dashboards, etc.)
  ///
  ///   - assume sempre etpId = "main" e sectionId = "main"
  ///   - lê todas as seções em paralelo
  ///   - se TODAS as seções vierem vazias, retorna null
  Future<EtpData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      etpId: ids.etpId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return EtpData.fromSectionsMap(sections);
  }
}
