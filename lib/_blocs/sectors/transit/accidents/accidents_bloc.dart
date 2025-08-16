import 'dart:async';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../_datas/sectors/transit/accidents/accidents_data.dart';

class PageResult<T> {
  final List<T> items;
  final QueryDocumentSnapshot? lastDoc; // cursor da página
  PageResult(this.items, this.lastDoc);
}

class AccidentsBloc extends BlocBase {
  AccidentsBloc();

  // ---------- Helpers ----------
  int _yearFromDateTime(DateTime dt, {bool local = true}) =>
      local ? dt.toLocal().year : dt.toUtc().year;

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateYearRef(int year) async {
    final db = FirebaseFirestore.instance;
    final q = await db
        .collection('trafficAccidents')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.reference;
    return await db.collection('trafficAccidents').add({'year': year});
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getYearRef(int year) async {
    final db = FirebaseFirestore.instance;
    final q = await db
        .collection('trafficAccidents')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    return q.docs.isNotEmpty ? q.docs.first.reference : null;
  }

  // ---------- CRUD ----------
  /// Delete direto por ano + id (mais simples e seguro).
  Future<void> deletarAccident({
    required String id,
    required int year,
  }) async {
    final yearRef = await _getYearRef(year);
    if (yearRef == null) return;
    final doc = await yearRef.collection('records').doc(id).get();
    if (doc.exists) await doc.reference.delete();
  }

  Future<void> saveOrUpdateAccident(AccidentsData data) async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (data.date == null) {
      throw Exception("Campo 'date' é obrigatório em AccidentsData.");
    }

    final year = _yearFromDateTime(data.date!, local: true);
    final month = data.date!.toLocal().month;
    final yearRef = await _getOrCreateYearRef(year);

    final records = yearRef.collection('records');
    final docRef = (data.id != null && data.id!.isNotEmpty)
        ? records.doc(data.id)
        : records.doc(); // id automático se null
    data.id ??= docRef.id;

    // popular denormalizações no modelo (útil pra filtros locais)
    data.year = year;
    data.month = month;
    data.yearDocId = yearRef.id;
    data.recordPath = docRef.path;

    final json = data.toJson()
      ..addAll({
        // garantir/forçar denormalizações no Firestore também
        'year': year,
        'month': month,
        'yearDocId': yearRef.id,
        'recordPath': docRef.path,
        'yearMonthKey': '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
        'recordId': docRef.id, // útil para debug
        'sourcePath': '${yearRef.path}/records/${docRef.id}',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
      });

    final snap = await docRef.get();
    final isNew = !snap.exists || (snap.data()?['createdAt'] == null);
    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = user?.uid ?? '';
    }

    await db.runTransaction((tx) async {
      tx.set(yearRef, {'year': year}, SetOptions(merge: true));  // garante o campo year no doc pai
      tx.set(docRef, json, SetOptions(merge: true));
    });
  }

  // ---------- Consulta / Paginação ----------
  /// Página de acidentes por ano/mês (se ano omitido, consulta todos via collectionGroup).
  /// Retorna também o cursor (`lastDoc`) para a próxima página.
  Future<PageResult<AccidentsData>> getAccidentsPage({
    int? year,
    int? month, // 1..12
    QueryDocumentSnapshot? startAfter,
    int limit = 15,
    bool descending = true,
  }) async {
    final db = FirebaseFirestore.instance;

    Query q;
    if (year != null) {
      final yearRef = await _getYearRef(year);
      if (yearRef == null) return PageResult([], null);

      q = yearRef.collection('records').orderBy('date', descending: descending);

      if (month != null) {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 1);
        q = q
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
        // Alternativa eficiente se criou índices em 'month':
        // q = q.where('month', isEqualTo: month);
      }
    } else {
      // Todos os anos
      q = db.collectionGroup('records').orderBy('date', descending: descending);
      // Alternativa: q = q.orderBy('year', descending: true).orderBy('month', descending: true);
    }

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit);

    final snap = await q.get();
    final items = snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
    final last = snap.docs.isNotEmpty ? snap.docs.last : null;

    return PageResult(items, last);
  }

  /// Carrega todos os acidentes (cuidado com volume).
  Future<List<AccidentsData>> getAllAccidents({int? year, int? month}) async {
    final db = FirebaseFirestore.instance;
    Query q;

    if (year != null) {
      final yearRef = await _getYearRef(year);
      if (yearRef == null) return [];
      q = yearRef.collection('records').orderBy('date');

      if (month != null) {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 1);
        q = q
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
        // Ou: q = q.where('month', isEqualTo: month);
      }
    } else {
      q = db.collectionGroup('records').orderBy('date');
    }

    final snap = await q.get();
    return snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
  }

  /// Atualiza/gera 'order' dentro de UM ano (crescente por data).
  Future<void> updateOrderOfAccidents({required int year}) async {
    final yearRef = await _getYearRef(year);
    if (yearRef == null) return;

    final q = await yearRef.collection('records').orderBy('date').get();

    final batch = FirebaseFirestore.instance.batch();
    int i = 0;
    for (final d in q.docs) {
      i++;
      batch.update(d.reference, {'order': i});
    }
    await batch.commit();
    // ignore: avoid_print
    print('✅ Ordem atualizada no ano $year com sucesso!');
  }

  // ---------- Agregações utilitárias ----------
  Map<String, int> contarTiposDeAcidente(List<AccidentsData> lista) {
    final Map<String, int> mapa = {};
    for (final a in lista) {
      final tipo = AccidentsData.normalizarTipoAcidente(a.typeOfAccident ?? 'INDEFINIDO');
      mapa[tipo] = (mapa[tipo] ?? 0) + 1;
    }
    return mapa;
  }

  Map<String, Map<String, int>> agruparTiposDeAcidentePorRodovia(List<AccidentsData> acidentes) {
    final Map<String, Map<String, int>> dados = {};
    for (final a in acidentes) {
      final rodovia = (a.highway ?? 'INDEFINIDO').toUpperCase().trim();
      final tipo = AccidentsData.normalizarTipoAcidente(a.typeOfAccident ?? 'INDEFINIDO');
      dados.putIfAbsent(rodovia, () => {});
      dados[rodovia]![tipo] = (dados[rodovia]![tipo] ?? 0) + 1;
    }
    return dados;
  }

  Future<Map<String, double>> getTotaisPorTipoAcidente(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {
      for (final tipo in AccidentsData.accidentTypes) tipo.toUpperCase(): 0.0,
    };
    for (final c in acidentes) {
      final status = c.typeOfAccident?.toUpperCase();
      if (status != null && totais.containsKey(status)) {
        totais[status] = (totais[status]! + 1);
      }
    }
    return totais;
  }

  Future<double> getValorPorTypeAccident(List<AccidentsData> accidents, String statusDesejado) async {
    double total = 0.0;
    for (final a in accidents) {
      final status = a.typeOfAccident?.toUpperCase();
      if (status == statusDesejado.toUpperCase()) total += 1;
    }
    return total;
  }

  Future<Map<String, double>> getValoresPorCidade(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final cidade = a.city?.trim().toUpperCase() ?? 'NÃO INFORMADO';
      totais[cidade] = (totais[cidade] ?? 0.0) + 1.0;
    }
    return totais;
  }

  Future<Map<String, double>> getFeridosPorCidade(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final cidade = a.city?.trim().toUpperCase() ?? 'NÃO INFORMADO';
      final feridos = a.scoresVictims ?? 0;
      totais[cidade] = (totais[cidade] ?? 0.0) + feridos.toDouble();
    }
    return totais;
  }

  Future<Map<String, double>> getMortesPorCidade(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final cidade = a.city?.trim().toUpperCase() ?? 'NÃO INFORMADO';
      final mortos = a.death ?? 0;
      totais[cidade] = (totais[cidade] ?? 0.0) + mortos.toDouble();
    }
    return totais;
  }

  Future<Map<String, double>> getMortesTotaisAnoMes(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final dt = a.date;
      if (dt != null) {
        final chave =
            '${dt.year.toString().padLeft(4, '0')}/${dt.month.toString().padLeft(2, '0')}';
        final mortos = a.death ?? 0;
        totais[chave] = (totais[chave] ?? 0.0) + mortos.toDouble();
      }
    }
    return totais;
  }
  Future<List<AccidentsData>> getAccidentsByCity(String cityName) async {
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collectionGroup('records')
        .where('city', isEqualTo: cityName)
        .get();

    return snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
  }

  Future<Map<String, dynamic>> getAccidentsByCityWithTotal(String cityName) async {
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collectionGroup('records')
        .where('city', isEqualTo: cityName)
        .get();

    final list = snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
    final total = list.length;

    return {'total': total, 'lista': list};
  }

  // Retorna total e lista de acidentes de uma cidade (collectionGroup)
  // dentro de AccidentsBloc
  Future<List<AccidentsData>> getAccidentsByCityList({
    required String cityName,
    int? year,
    int? month,
  }) async {
    final db = FirebaseFirestore.instance;

    // Usa collectionGroup('records') com filtros pela denormalização year/month
    Query<Map<String, dynamic>> q = db
        .collectionGroup('records')
        .where('city', isEqualTo: cityName);

    if (year != null) {
      q = q.where('year', isEqualTo: year);
    }
    if (month != null) {
      q = q.where('month', isEqualTo: month);
    }

    // Opcional: ordenar por data
    q = q.orderBy('date', descending: true);

    final snap = await q.get();
    return snap.docs
        .map((d) => AccidentsData.fromDocument(snapshot: d))
        .toList();
  }


  /// Atalho semântico p/ buscar filtrado por ano/mês (já existe getAllAccidents com filtros,
  /// mas deixo esse nome mais autoexplicativo se preferir).
  Future<List<AccidentsData>> getAccidentsFiltered({int? year, int? month}) {
    return getAllAccidents(year: year, month: month);
  }

  // ---------- Utilitário legacy (converter strings para Timestamp) ----------
  Future<void> corrigirDatasAcidentesCollectionGroup() async {
    final db = FirebaseFirestore.instance;
    final DateFormat formato = DateFormat('dd/MM/yyyy');

    final snap = await db.collectionGroup('records').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final rawDate = data['date'];
      if (rawDate is String) {
        try {
          final parsed = formato.parseStrict(rawDate);
          await doc.reference.update({'date': Timestamp.fromDate(parsed)});
          // ignore: avoid_print
          print('✔️ ${doc.id} atualizado');
        } catch (e) {
          // ignore: avoid_print
          print('❌ Erro ao converter ${doc.id}: $e');
        }
      }
    }
  }
}
