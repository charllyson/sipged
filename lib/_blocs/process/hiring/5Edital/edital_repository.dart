// lib/_blocs/process/hiring/5Edital/edital_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'edital_sections.dart';
import 'edital_data.dart'; // 👈 modelo tipado do Edital

class EditalRepository {
  final FirebaseFirestore _db;
  EditalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('edital');

  /// Doc principal do Edital: contracts/{contractId}/edital/main
  DocumentReference<Map<String, dynamic>> _editalDoc(String contractId) =>
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
  /// - Se não existir `edital/main`, copia os dados do 1º Edital antigo.
  /// - Para cada seção, se `main` estiver vazia, copia a 1ª seção antiga.
  ///
  /// NÃO APAGA NADA ANTIGO.
  /// ===========================================================================
  Future<({String editalId, SectionIds sectionIds})> ensureEditalStructure(
      String contractId,
      ) async {
    final mainRef = _editalDoc(contractId);
    var mainSnap = await mainRef.get();

    DocumentReference<Map<String, dynamic>>? legacyEditalRef;

    // 1) Se não existe "main", tenta achar um Edital antigo para migrar
    if (!mainSnap.exists) {
      final legacyQ = await _col(contractId).limit(1).get();

      if (legacyQ.docs.isNotEmpty) {
        final legacyDoc = legacyQ.docs.first;
        legacyEditalRef = legacyDoc.reference;

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
        // nenhum doc de edital existia -> cria um main limpo
        await mainRef.set(
          {
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      mainSnap = await mainRef.get();
    } else {
      // main já existe -> ainda podemos usar um Edital antigo como fonte para seções
      final legacyQ = await _col(contractId).limit(1).get();
      if (legacyQ.docs.isNotEmpty) {
        final legacyDoc = legacyQ.docs.first;
        if (legacyDoc.id != 'main') {
          legacyEditalRef = legacyDoc.reference;
        }
      }
    }

    // 2) Garante um doc "main" em cada subcoleção de seção,
    //    migrando dados das seções antigas se existirem
    final SectionIds sectionIds = {};
    for (final sec in EditalSections.all) {
      final mainSecRef = mainRef.collection(sec).doc('main');
      var mainSecSnap = await mainSecRef.get();

      Map<String, dynamic>? mainData =
      mainSecSnap.exists ? mainSecSnap.data() : null;

      if (!mainSecSnap.exists || _isSectionDataEmpty(mainData)) {
        Map<String, dynamic>? sourceData;

        // tenta achar seção em Edital legado, se existir
        if (legacyEditalRef != null) {
          final legacySecQ =
          await legacyEditalRef.collection(sec).limit(1).get();
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

    return (editalId: mainRef.id, sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String editalId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final root = _col(contractId).doc(editalId);

    for (final entry in sectionIds.entries) {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await root.collection(secName).doc(secId).get();
      final data =
      Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }

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
  // Leitura direta de um EditalData completo para o contrato (útil pra dashboards)
  // ===========================================================================
  Future<EditalData?> readDataForContract(String contractId) async {
    // 1) tenta usar o doc "main"
    final mainRef = _editalDoc(contractId);
    var editalSnap = await mainRef.get();

    // Se não existir main, procura um Edital legado qualquer
    if (!editalSnap.exists) {
      final legacyQ = await _col(contractId).limit(1).get();
      if (legacyQ.docs.isEmpty) return null;
      editalSnap = legacyQ.docs.first;
    }

    final editalRef = editalSnap.reference;
    final Map<String, Map<String, dynamic>> sections = {};

    // 2) para cada seção, tenta pegar o doc "main",
    //    senão cai no primeiro doc legado da subcoleção
    for (final sec in EditalSections.all) {
      final mainSecRef = editalRef.collection(sec).doc('main');
      var secSnap = await mainSecRef.get();

      if (!secSnap.exists) {
        final legacySecQ = await editalRef.collection(sec).limit(1).get();
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

    // 3) monta o EditalData a partir do mapa de seções
    return EditalData.fromSectionsMap(sections);
  }
}
