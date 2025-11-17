// lib/_blocs/process/hiring/1Dfd/dfd_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'dfd_sections.dart';
import 'dfd_data.dart';

class DfdRepository {
  final FirebaseFirestore _db;
  DfdRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('dfd');

  /// Doc principal do DFD: contracts/{contractId}/dfd/main
  DocumentReference<Map<String, dynamic>> _dfdDoc(String contractId) =>
      _col(contractId).doc('main');

  bool _isSectionDataEmpty(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return true;
    // se só tiver campos técnicos, considero "vazio"
    final keys = data.keys.toSet();
    keys.remove('createdAt');
    keys.remove('updatedAt');
    return keys.isEmpty;
  }

  /// ===========================================================================
  /// Garante a estrutura usando IDs fixos "main" E faz migração lazy dos dados antigos:
  ///
  /// - Se não existir `dfd/main`, copia os dados do 1º DFD antigo.
  /// - Para cada seção, se `main` estiver vazia, copia a 1ª seção antiga.
  ///
  /// NÃO APAGA NADA ANTIGO.
  /// ===========================================================================
  Future<({String dfdId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final mainRef = _dfdDoc(contractId);
    var mainSnap = await mainRef.get();

    DocumentReference<Map<String, dynamic>>? legacyDfdRef;

    // 1) Se não existe "main", tenta achar um DFD antigo para migrar
    if (!mainSnap.exists) {
      final legacyQ = await _col(contractId).limit(1).get();

      if (legacyQ.docs.isNotEmpty) {
        final legacyDoc = legacyQ.docs.first;
        legacyDfdRef = legacyDoc.reference;

        final legacyData =
        Map<String, dynamic>.from(legacyDoc.data() ?? <String, dynamic>{});

        await mainRef.set(
          {
            ...legacyData,
            'migratedFrom': legacyDoc.id,
            'migratedAt': FieldValue.serverTimestamp(),
            'createdAt':
            legacyData['createdAt'] ?? FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        // nenhum doc de dfd existia -> cria um main limpo
        await mainRef.set(
          {
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      mainSnap = await mainRef.get();
    } else {
      // main já existe -> ainda podemos usar um DFD antigo como fonte para seções
      final legacyQ = await _col(contractId).limit(1).get();
      if (legacyQ.docs.isNotEmpty) {
        final legacyDoc = legacyQ.docs.first;
        if (legacyDoc.id != 'main') {
          legacyDfdRef = legacyDoc.reference;
        }
      }
    }

    // 2) Garante um doc "main" em cada subcoleção de seção,
    //    migrando dados das seções antigas se existirem
    final SectionIds sectionIds = {};
    for (final sec in DfdSections.all) {
      final mainSecRef = mainRef.collection(sec).doc('main');
      var mainSecSnap = await mainSecRef.get();

      Map<String, dynamic>? mainData =
      mainSecSnap.exists ? mainSecSnap.data() : null;

      if (!mainSecSnap.exists || _isSectionDataEmpty(mainData)) {
        Map<String, dynamic>? sourceData;

        // tenta achar seção em DFD legado, se existir
        if (legacyDfdRef != null) {
          final legacySecQ =
          await legacyDfdRef.collection(sec).limit(1).get();
          if (legacySecQ.docs.isNotEmpty) {
            sourceData = Map<String, dynamic>.from(
              legacySecQ.docs.first.data() ?? <String, dynamic>{},
            );
          }
        }

        if (sourceData != null && !_isSectionDataEmpty(sourceData)) {
          // Migra dados da seção antiga para main
          await mainSecRef.set(
            sourceData,
            SetOptions(merge: false), // sobrescreve completamente a seção main
          );
        } else {
          // não havia seção antiga -> apenas garante o doc main vazio com createdAt
          await mainSecRef.set(
            {
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        mainSecSnap = await mainSecRef.get();
      }

      sectionIds[sec] = mainSecRef.id; // sempre "main"
    }

    return (dfdId: mainRef.id, sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final dfdRef = _col(contractId).doc(dfdId);

    for (final entry in sectionIds.entries) {
      final secName = entry.key;
      final secId = entry.value;
      final snap = await dfdRef.collection(secName).doc(secId).get();

      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');
      out[secName] = data;
    }
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

  /// Leitura direta de um DfdData completo para o contrato (útil pra dashboards, etc.)
  Future<DfdData?> readDataForContract(String contractId) async {
    final mainRef = _dfdDoc(contractId);
    var dfdSnap = await mainRef.get();

    // Se não existir main, procura um DFD legado qualquer
    if (!dfdSnap.exists) {
      final legacyQ = await _col(contractId).limit(1).get();
      if (legacyQ.docs.isEmpty) return null;
      dfdSnap = legacyQ.docs.first;
    }

    final dfdRef = dfdSnap.reference;
    final Map<String, Map<String, dynamic>> sections = {};

    for (final sec in DfdSections.all) {
      final mainSecRef = dfdRef.collection(sec).doc('main');
      var secSnap = await mainSecRef.get();

      if (!secSnap.exists) {
        final legacySecQ = await dfdRef.collection(sec).limit(1).get();
        if (legacySecQ.docs.isEmpty) continue;
        secSnap = legacySecQ.docs.first;
      }

      final data =
      Map<String, dynamic>.from(secSnap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');
      sections[sec] = data;
    }

    if (sections.isEmpty) return null;

    return DfdData.fromSectionsMap(sections);
  }
}
