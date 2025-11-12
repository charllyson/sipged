import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_sections.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

class DfdRepository {
  final FirebaseFirestore _firestore;
  DfdRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _dfdCol(String contractId) =>
      _firestore.collection('contracts').doc(contractId).collection('dfd');

  /// Garante o doc raiz do DFD e um doc em cada subcoleção de seção.
  Future<({String dfdId, SectionIds sectionIds})> ensureDfdStructure(
      String contractId,
      ) async {
    // Doc raiz
    final dfdQ = await _dfdCol(contractId).limit(1).get();
    final dfdRef = dfdQ.docs.isEmpty
        ? await _dfdCol(contractId).add({'createdAt': FieldValue.serverTimestamp()})
        : dfdQ.docs.first.reference;

    // Um doc por seção
    final SectionIds sectionIds = {};
    for (final sec in DfdSections.all) {
      final col = dfdRef.collection(sec);
      final q = await col.limit(1).get();
      final ref = q.docs.isEmpty
          ? await col.add({'createdAt': FieldValue.serverTimestamp()})
          : q.docs.first.reference;
      sectionIds[sec] = ref.id;
    }
    return (dfdId: dfdRef.id, sectionIds: sectionIds);
  }

  /// Salva UMA seção
  Future<void> saveSection({
    required String contractId,
    required String dfdId,
    required String sectionKey,
    required String sectionDocId,
    required Map<String, dynamic> data,
  }) async {
    await _dfdCol(contractId)
        .doc(dfdId)
        .collection(sectionKey)
        .doc(sectionDocId)
        .set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Salva VÁRIAS seções em batch
  Future<void> saveSectionsBatch({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
    required SectionsMap sectionsData,
  }) async {
    final batch = _firestore.batch();
    final dfdRef = _dfdCol(contractId).doc(dfdId);

    sectionsData.forEach((sectionKey, data) {
      final id = sectionIds[sectionKey];
      if (id == null) return;
      batch.set(
        dfdRef.collection(sectionKey).doc(id),
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    });

    await batch.commit();
  }

  /// Carrega todos os mapas por seção: {secao: Map}
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final dfdRef = _dfdCol(contractId).doc(dfdId);

    for (final entry in sectionIds.entries) {
      final sec = entry.key;
      final id = entry.value;
      final snap = await dfdRef.collection(sec).doc(id).get();
      final data = (snap.data() ?? <String, dynamic>{});
      data.remove('createdAt');
      out[sec] = data;
    }
    return out;
  }

  /// Leitura leve de rótulo da rodovia
  Future<String?> readRoadLabel(String contractId) async {
    final dfdQ = await _dfdCol(contractId).limit(1).get();
    if (dfdQ.docs.isEmpty) return null;
    final dfdRef = dfdQ.docs.first.reference;

    // 1) localizacao
    final locQ = await dfdRef.collection(DfdSections.localizacao).limit(1).get();
    if (locQ.docs.isNotEmpty) {
      final m = locQ.docs.first.data();
      final v = (m['roadName'] ?? m['rodovia'])?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }

    // 2) identificacao (compat)
    final idQ = await dfdRef.collection(DfdSections.identificacao).limit(1).get();
    if (idQ.docs.isNotEmpty) {
      final m = idQ.docs.first.data();
      final v = (m['roadName'] ?? m['rodovia'])?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Leitura leve de Regional
  Future<String?> readRegionalLabel(String contractId) async {
    final dfdQ = await _dfdCol(contractId).limit(1).get();
    if (dfdQ.docs.isEmpty) return null;
    final dfdRef = dfdQ.docs.first.reference;

    final locQ = await dfdRef.collection(DfdSections.localizacao).limit(1).get();
    if (locQ.docs.isNotEmpty) {
      final m = locQ.docs.first.data();
      final v = m['regional']?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }

    final idQ = await dfdRef.collection(DfdSections.identificacao).limit(1).get();
    if (idQ.docs.isNotEmpty) {
      final m = idQ.docs.first.data();
      final v = m['regional']?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Nº do processo (identificacao.numeroProcessoContratacao)
  Future<String?> readProcessNumber(String contractId) async {
    final dfdQ = await _dfdCol(contractId).limit(1).get();
    if (dfdQ.docs.isEmpty) return null;
    final dfdRef = dfdQ.docs.first.reference;

    final idQ = await dfdRef.collection(DfdSections.identificacao).limit(1).get();
    if (idQ.docs.isNotEmpty) {
      final m = idQ.docs.first.data();
      final v = m['numeroProcessoContratacao']?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// 🔹 Leitura leve consolidada: status + tipoObra + extensaoKm
  Future<({String? status, String? tipoObra, double? extensaoKm})> readLightFields(
      String contractId,
      ) async {
    try {
      final dfdQ = await _dfdCol(contractId).limit(1).get();
      if (dfdQ.docs.isEmpty) {
        return (status: null, tipoObra: null, extensaoKm: null);
      }
      final dfdRef = dfdQ.docs.first.reference;

      String? status, tipoObra;
      double? extensaoKm;

      // identificacao.statusContrato
      final idQ = await dfdRef.collection(DfdSections.identificacao).limit(1).get();
      if (idQ.docs.isNotEmpty) {
        final m = idQ.docs.first.data();
        final v = (m['statusContrato'] ?? '').toString().trim();
        if (v.isNotEmpty) status = v;
      }

      // objeto.tipoObra
      final objQ = await dfdRef.collection(DfdSections.objeto).limit(1).get();
      if (objQ.docs.isNotEmpty) {
        final m = objQ.docs.first.data();
        final v = (m['tipoObra'] ?? '').toString().trim();
        if (v.isNotEmpty) tipoObra = v;
      }

      // localizacao.extensaoKm
      final locQ = await dfdRef.collection(DfdSections.localizacao).limit(1).get();
      if (locQ.docs.isNotEmpty) {
        final m = locQ.docs.first.data();
        extensaoKm = _parseToDouble(m['extensaoKm']);
      }

      return (status: status, tipoObra: tipoObra, extensaoKm: extensaoKm);
    } catch (_) {
      return (status: null, tipoObra: null, extensaoKm: null);
    }
  }

  /// Retrocompat — mantido
  Future<({String? tipoObra, double? extensaoKm})> readWorkTypeAndExtent(
      String contractId,
      ) async {
    final r = await readLightFields(contractId);
    return (tipoObra: r.tipoObra, extensaoKm: r.extensaoKm);
  }

  double? _parseToDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final cleaned = raw.replaceAll('.', '').replaceAll(',', '.').trim();
      return double.tryParse(cleaned);
    }
    return null;
  }
}
