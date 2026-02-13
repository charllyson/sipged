import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

import 'dfd_sections.dart';
import 'dfd_data.dart';

class DfdRepository {
  final FirebaseFirestore _db;
  DfdRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('dfd');

  /// Estrutura fixa:
  ///   - doc DFD sempre "main"
  ///   - cada seção sempre doc "main"
  Future<({String dfdId, SectionIds sectionIds})> ensureStructure(String contractId) async {
    final SectionIds sectionIds = {for (final sec in DfdSections.all) sec: 'main'};
    return (dfdId: 'main', sectionIds: sectionIds);
  }

  /// Carrega todas as seções em um mapa {secao: Map}
  Future<SectionsMap> loadAllSections({
    required String contractId,
    required String dfdId,
    required SectionIds sectionIds,
  }) async {
    final SectionsMap out = {};
    final dfdRef = _col(contractId).doc(dfdId);

    final futures = sectionIds.entries.map((entry) async {
      final secName = entry.key;
      final secId = entry.value;

      final snap = await dfdRef.collection(secName).doc(secId).get();
      final data = Map<String, dynamic>.from(snap.data() ?? <String, dynamic>{});

      data.remove('createdAt');
      data.remove('updatedAt');

      out[secName] = data;
    }).toList();

    await Future.wait(futures);
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
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
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
    final ref = _col(contractId).doc(dfdId).collection(sectionKey).doc(sectionDocId);

    await ref.set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Leitura direta de um DfdData completo para o contrato
  Future<DfdData?> readDataForContract(String contractId) async {
    final ids = await ensureStructure(contractId);

    final sections = await loadAllSections(
      contractId: contractId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
    );

    final hasAnyData = sections.values.any((m) => m.isNotEmpty);
    if (!hasAnyData) return null;

    return DfdData.fromSectionsMap(sections, contractId: contractId);
  }

  /// Cria (se necessário) o contrato e salva o DFD completo.
  Future<String> ensureContractAndSaveDfd({
    String? contractId,
    required DfdData data,
  }) async {
    String effectiveId = (contractId ?? '').trim();

    if (effectiveId.isEmpty) {
      final contractsRef = _db.collection('contracts');
      final docRef = await contractsRef.add({'createdAt': FieldValue.serverTimestamp()});
      effectiveId = docRef.id;
    }

    final ids = await ensureStructure(effectiveId);

    await saveSectionsBatch(
      contractId: effectiveId,
      dfdId: ids.dfdId,
      sectionIds: ids.sectionIds,
      sectionsData: data.toSectionsMap(),
    );

    return effectiveId;
  }

  // =======================================================================
  // ✅ BENCHMARK: sementes (contractId + km) vindas do localizacao
  // =======================================================================

  /// Retorna lista de contratos com a mesma naturezaIntervencao já trazendo o km do doc localizacao.
  ///
  /// Isso evita reler o km por contrato e corrige o caso em que readExtensaoKmForContract retorna 0.
  Future<List<({String contractId, double km})>> listBenchmarkSeedsByNaturezaIntervencao(
      String natureza,
      ) async {
    final n = natureza.trim();
    if (n.isEmpty) return <({String contractId, double km})>[];

    final sw = Stopwatch()..start();
    if (kDebugMode) {
      debugPrint('[DfdRepository] listBenchmarkSeedsByNaturezaIntervencao("$n") START');
    }

    // ✅ 1) Faz query exata (rápida) — que você já usa
    final qs = await _db
        .collectionGroup(DfdSections.localizacao)
        .where('naturezaIntervencao', isEqualTo: n)
        .get();

    // ✅ 2) Se vier pouco (ex: 1 ou 2), roda diagnóstico (somente debug)
    if (kDebugMode && qs.docs.length < 5) {
      final diag = await _db
          .collectionGroup(DfdSections.localizacao)
          .limit(300) // ajuste se quiser
          .get();

      final Map<String, int> freq = {};
      for (final d in diag.docs) {
        final raw = d.data()['naturezaIntervencao'];
        final s = (raw ?? '').toString().trim();
        if (s.isEmpty) continue;
        freq[s] = (freq[s] ?? 0) + 1;
      }

      final top = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      debugPrint('[DfdRepository][DIAG] Top naturezas encontradas em localizacao (amostra 300):');
      for (final e in top.take(20)) {
        debugPrint('  - "${e.key}" -> ${e.value}');
      }
      debugPrint('[DfdRepository][DIAG] Procurando exatamente: "$n"');
    }

    final Map<String, double> out = <String, double>{};

    for (final doc in qs.docs) {
      final path = doc.reference.path;
      final parts = path.split('/');

      if (parts.length < 2 || parts[0] != 'contracts') continue;

      final contractId = parts[1].trim();
      if (contractId.isEmpty) continue;

      final data = doc.data();

      final dynamic rawKm = data['extensaoKm'];

      double km = 0.0;
      if (rawKm is num) {
        km = rawKm.toDouble();
      } else if (rawKm is String) {
        km = double.tryParse(rawKm.replaceAll('.', '').replaceAll(',', '.')) ??
            double.tryParse(rawKm.replaceAll(',', '.')) ??
            0.0;
      }

      if (km > (out[contractId] ?? 0.0)) {
        out[contractId] = km;
      }
    }

    final seeds = out.entries
        .map((e) => (contractId: e.key, km: e.value))
        .toList()
      ..sort((a, b) => a.contractId.compareTo(b.contractId));

    sw.stop();
    if (kDebugMode) {
      final zeros = seeds.where((s) => s.km <= 0).length;
      debugPrint(
        '[DfdRepository] natureza="$n" -> seeds=${seeds.length}, km<=0: $zeros '
            '(elapsed=${sw.elapsedMilliseconds}ms)',
      );
    }

    return seeds;
  }


  // =======================================================================
  // Leitura base value (objeto) - mantém
  // =======================================================================

  /// Lê apenas o valor base do contrato no DFD.objeto/main:
  ///   valorDemanda (preferencial), senão estimativaValor.
  Future<double> readBaseValueForContract(String contractId) async {
    final id = contractId.trim();
    if (id.isEmpty) return 0.0;

    final ref = _db
        .collection('contracts')
        .doc(id)
        .collection('dfd')
        .doc('main')
        .collection(DfdSections.objeto)
        .doc('main');

    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return 0.0;

    double readNum(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        // tenta lidar com "1.234.567,89"
        return double.tryParse(v.replaceAll('.', '').replaceAll(',', '.')) ??
            double.tryParse(v.replaceAll(',', '.')) ??
            0.0;
      }
      return 0.0;
    }

    final valorDemanda = readNum(data['valorDemanda']);
    if (valorDemanda > 0) return valorDemanda;

    return readNum(data['estimativaValor']);
  }
}
