import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisged/_blocs/sectors/transit/infractions/infractions_data.dart';

/// Esquema:
/// trafficInfractions/{containerId(yearDoc) [campos: year:int,...]}/records/{recordId [campos da infração]}
class InfractionsBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  InfractionsBloc();

  // =======================
  // CONTAINERS (PAI - POR ANO)
  // =======================

  /// Retorna (ou cria) o container de um ano em `trafficInfractions` (doc pai com campo year).
  Future<DocumentReference> _getOrCreateContainerForYear(int year) async {
    final q = await _db
        .collection('trafficInfractions')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.reference;

    final ref = _db.collection('trafficInfractions').doc();
    await ref.set({'year': year, 'createdAt': FieldValue.serverTimestamp()});
    return ref;
  }

  /// Lista os containers disponíveis (útil para diagnosticar)
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> listYearContainers() async {
    final q = await _db.collection('trafficInfractions').orderBy('year', descending: true).get();
    return q.docs;
  }

  // =======================
  // LISTAGENS
  // =======================

  /// Busca *todas* as infrações do sistema (varre todos os containers) com collectionGroup.
  Future<List<InfractionsData>> getAllInfractions() async {
    final snap = await _db.collectionGroup('records').get();
    return snap.docs.map((d) => InfractionsData.fromMap(d.data(), id: d.id)).toList();
  }

  /// Busca todas as infrações de um ANO específico.
  /// Obs.: como o campo `year` está no documento pai (container), não dá para usar `collectionGroup` filtrando `year`.
  /// Por isso, buscamos os containers do ano e, para cada um, lemos `records`.
  Future<List<InfractionsData>> getInfractionsByYear(int year) async {
    final containers = await _db
        .collection('trafficInfractions')
        .where('year', isEqualTo: year)
        .get();

    final results = <InfractionsData>[];
    for (final c in containers.docs) {
      final rec = await c.reference.collection('records').get();
      results.addAll(rec.docs.map((d) => InfractionsData.fromMap(d.data(), id: d.id)));
    }
    return results;
  }

  /// Paginação simples por ano (use lastDoc para continuar)
  Future<QuerySnapshot<Map<String, dynamic>>> pageRecordsByYear({
    required int year,
    DocumentSnapshot? lastDoc,
    int limit = 200,
  }) async {
    final containers = await _db
        .collection('trafficInfractions')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (containers.docs.isEmpty) {
      // Retorna uma QuerySnapshot vazia simulando lista de docs vazia
      return await _db.collection('trafficInfractions').doc('fake').collection('records').limit(0).get();
    }

    Query<Map<String, dynamic>> q =
    containers.docs.first.reference.collection('records').orderBy('orderInfraction');

    if (lastDoc != null) {
      q = q.startAfterDocument(lastDoc);
    }

    return await q.limit(limit).get();
  }

  /// Localiza possíveis duplicados por AIT dentro de um ANO (container).
  Future<List<InfractionsData>> findDuplicatesByAitInYear(int year) async {
    final list = await getInfractionsByYear(year);
    final seen = <String, InfractionsData>{};
    final dups = <InfractionsData>[];

    for (final i in list) {
      final key = (i.aitNumber ?? '').trim().toUpperCase();
      if (key.isEmpty) continue;
      if (seen.containsKey(key)) {
        dups.add(i);
      } else {
        seen[key] = i;
      }
    }
    return dups;
  }

  /// Contagem de registros com geolocalização dentro do ANO.
  Future<int> countWithGeolocationByYear(int year) async {
    final list = await getInfractionsByYear(year);
    return list.where((i) => i.latitude != null && i.longitude != null).length;
  }

  // =======================
  // CRUD EM trafficInfractions/{container}/records
  // =======================

  /// Salva/atualiza uma infração dentro do container do ano informado.
  Future<void> salvarOuAtualizarInfracao({
    required int year,
    required InfractionsData data,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final containerRef = await _getOrCreateContainerForYear(year);
    final records = containerRef.collection('records');

    final docRef = (data.id != null && data.id!.isNotEmpty)
        ? records.doc(data.id)
        : records.doc();

    data.id ??= docRef.id;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
        // dica: se quiser facilitar consultas, grave o 'year' também dentro do record
        'year': year,
      });

    final snap = await docRef.get();
    final hasCreatedAt = snap.exists && snap.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = user?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
  }

  /// Deleta uma infração dentro do container do ano.
  Future<void> deleteInfraction({
    required int year,
    required String recordId,
  }) async {
    try {
      final containers = await _db
          .collection('trafficInfractions')
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (containers.docs.isEmpty) {
        throw Exception('Container do ano $year não encontrado.');
      }

      await containers.docs.first.reference.collection('records').doc(recordId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar infração: $e');
    }
  }

  // =======================
  // AJUDANTES
  // =======================

  /// Conta registros de um ano (rápido para selectorDates)
  Future<int> countByYear(int year) async {
    final list = await getInfractionsByYear(year);
    return list.length;
  }

  /// Busca por AIT exato no sistema todo (útil para diagnóstico global)
  Future<List<InfractionsData>> searchByAit(String ait) async {
    final q = await _db.collectionGroup('records').where('aitNumber', isEqualTo: ait).get();
    return q.docs.map((d) => InfractionsData.fromMap(d.data(), id: d.id)).toList();
  }

  // INSIRA no InfractionsBloc
  Future<void> debugYearSources(int year, {int sample = 5}) async {
    debugPrint('====== DEBUG trafficInfractions/$year ======');
    final containers = await _db
        .collection('trafficInfractions')
        .where('year', isEqualTo: year)
        .get();

    if (containers.docs.isEmpty) {
      debugPrint('Nenhum container para o ano $year.');
      return;
    }

    debugPrint('Containers encontrados para $year: ${containers.docs.length}');
    for (final c in containers.docs) {
      final path = c.reference.path;
      final recSnap = await c.reference.collection('records').get();
      debugPrint(' - $path => ${recSnap.docs.length} records');

      // amostra
      for (final d in recSnap.docs.take(sample)) {
        final m = d.data();
        debugPrint('   • ${d.reference.path} | '
            'order=${m['orderInfraction']} | '
            'ait=${m['aitNumber']} | '
            'data=${m['dateInfraction']} | '
            'cod=${m['codeInfraction']}');
      }
    }

    // mapa para detectar duplicados (AIT + data ao minuto)
    final dupKeyCount = <String, List<String>>{};
    for (final c in containers.docs) {
      final recSnap = await c.reference.collection('records').get();
      for (final d in recSnap.docs) {
        final m = d.data();
        final ait = (m['aitNumber'] ?? '').toString().trim().toUpperCase();
        final ts = m['dateInfraction'];
        String stamp;
        if (ts is Timestamp) {
          final dt = ts.toDate();
          stamp = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-'
              '${dt.day.toString().padLeft(2,'0')} '
              '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
        } else {
          stamp = (ts ?? 'nodate').toString();
        }
        final key = '$ait|$stamp';
        (dupKeyCount[key] ??= []).add(d.reference.path);
      }
    }

    final dups = dupKeyCount.entries.where((e) => e.value.length > 1).toList();
    if (dups.isEmpty) {
      debugPrint('Nenhuma duplicata (por AIT+data) detectada.');
    } else {
      debugPrint('DUPLICATAS DETECTADAS: ${dups.length}');
      for (final e in dups.take(20)) {
        debugPrint(' - ${e.key} => ${e.value.length} docs');
        for (final p in e.value) {
          debugPrint('     • $p');
        }
      }
      if (dups.length > 20) debugPrint('... (${dups.length - 20} restantes)');
    }

    debugPrint('====== FIM DEBUG ======');
  }

}
