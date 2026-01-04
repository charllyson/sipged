// lib/_blocs/process/hiring/10Arquivamento/termo_arquivamento_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'termo_arquivamento_sections.dart';
import 'termo_arquivamento_data.dart'; // 🆕 para readDataForContract

class TermoArquivamentoRepository {
  final FirebaseFirestore _db;
  TermoArquivamentoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('arquivamento');

  /// ===========================================================================
  /// ESTRUTURA FIXA OTIMIZADA
  ///
  ///   - doc raiz SEMPRE "main"
  ///   - cada seção SEMPRE doc "main"
  ///   - sem I/O aqui, só IDs em memória
  /// ===========================================================================
  Future<({String taId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final SectionIds sectionIds = {
      for (final sec in TermoArquivamentoSections.all) sec: 'main',
    };
    return (taId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  ///   - lê tudo em paralelo com Future.wait
  ///   - remove createdAt/updatedAt
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String taId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final taRef = _col(contractId).doc(taId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await taRef.collection(secName).doc(secId).get();
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
    required String taId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final taRef = _col(contractId).doc(taId);
    final wb = _db.batch();

    sectionsData.forEach((sec, data) {
      final id = sectionIds[sec];
      if (id == null) return;
      final ref = taRef.collection(sec).doc(id);
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
    required String taId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    final ref =
    _col(contractId).doc(taId).collection(sectionKey).doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Leitura direta de um TermoArquivamentoData completo para o contrato
  ///
  ///   - assume sempre taId = "main" e sectionId = "main"
  ///   - lê todas as seções em paralelo
  ///   - se TODAS vierem vazias, retorna null
  Future<TermoArquivamentoData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      taId: ids.taId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return TermoArquivamentoData.fromSectionsMap(sections);
  }
}
