import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'publicacao_extrato_sections.dart';
import 'publicacao_extrato_data.dart';

class PublicacaoExtratoRepository {
  final FirebaseFirestore _db;
  PublicacaoExtratoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('publicacao');

  /// Doc da publicação principal: contracts/{contractId}/publicacao/main
  DocumentReference<Map<String, dynamic>> _pubDoc(String contractId) =>
      _col(contractId).doc('main');

  bool _isSectionDataEmpty(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return true;
    // se só tiver campos técnicos, considero "vazio"
    final keys = data.keys.toSet();
    keys.remove('createdAt');
    keys.remove('updatedAt');
    return keys.isEmpty;
  }

  /// Garante a estrutura usando IDs fixos "main" E faz migração lazy dos dados antigos:
  ///
  /// - Se não existir `publicacao/main`, copia os dados da 1ª publicação antiga.
  /// - Para cada seção, se `main` estiver vazia, copia a 1ª seção da publicação antiga.
  ///
  /// NÃO APAGA NADA ANTIGO.
  Future<({String pubId, SectionIds sectionIds})> ensureStructure(
      String contractId,
      ) async {
    final mainRef = _pubDoc(contractId);
    var mainSnap = await mainRef.get();

    DocumentReference<Map<String, dynamic>>? legacyPubRef;

    // 1) Se não existe "main", tenta achar uma publicação antiga para migrar
    if (!mainSnap.exists) {
      final legacyQ = await _col(contractId).limit(1).get();

      if (legacyQ.docs.isNotEmpty) {
        final legacyDoc = legacyQ.docs.first;
        legacyPubRef = legacyDoc.reference;

        final legacyData =
        Map<String, dynamic>.from(legacyDoc.data() ?? <String, dynamic>{});

        // não faz sentido carregar updatedAt antigo aqui, mas pode manter se quiser
        await mainRef.set(
          {
            ...legacyData,
            'migratedFrom': legacyDoc.id,
            'migratedAt': FieldValue.serverTimestamp(),
            'createdAt': legacyData['createdAt'] ?? FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        // nenhum doc de publicacao existia -> cria um main limpo
        await mainRef.set(
          {
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      mainSnap = await mainRef.get();
    } else {
      // main já existe -> ainda podemos usar uma publicação antiga como fonte para seções
      final legacyQ = await _col(contractId).limit(1).get();
      if (legacyQ.docs.isNotEmpty) {
        final legacyDoc = legacyQ.docs.first;
        if (legacyDoc.id != 'main') {
          legacyPubRef = legacyDoc.reference;
        }
      }
    }

    // 2) Garante um doc "main" em cada subcoleção de seção,
    //    migrando dados das seções antigas se existirem
    final SectionIds sectionIds = {};
    for (final sec in PublicacaoExtratoSections.all) {
      final mainSecRef = mainRef.collection(sec).doc('main');
      var mainSecSnap = await mainSecRef.get();

      Map<String, dynamic>? mainData =
      mainSecSnap.exists ? mainSecSnap.data() : null;

      if (!mainSecSnap.exists || _isSectionDataEmpty(mainData)) {
        Map<String, dynamic>? sourceData;

        // tenta achar seção em publicação legada, se existir
        if (legacyPubRef != null) {
          final legacySecQ =
          await legacyPubRef.collection(sec).limit(1).get();
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

    return (pubId: mainRef.id, sectionIds: sectionIds);
  }

  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String pubId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final pubRef = _col(contractId).doc(pubId);

    for (final entry in sectionIds.entries) {
      final secName = entry.key;
      final secId = entry.value;
      final snap = await pubRef.collection(secName).doc(secId).get();

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
    final ref = _col(contractId)
        .doc(pubId)
        .collection(sectionKey)
        .doc(sectionDocId);
    await ref.set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<PublicacaoExtratoData?> readDataForContract(String contractId) async {
    final mainRef = _pubDoc(contractId);
    var pubSnap = await mainRef.get();

    if (!pubSnap.exists) {
      final legacyQ = await _col(contractId).limit(1).get();
      if (legacyQ.docs.isEmpty) return null;
      pubSnap = legacyQ.docs.first;
    }

    final pubRef = pubSnap.reference;
    final Map<String, Map<String, dynamic>> sections = {};

    for (final sec in PublicacaoExtratoSections.all) {
      final mainSecRef = pubRef.collection(sec).doc('main');
      var secSnap = await mainSecRef.get();

      if (!secSnap.exists) {
        final legacySecQ = await pubRef.collection(sec).limit(1).get();
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

    return PublicacaoExtratoData.fromSectionsMap(sections);
  }
}
