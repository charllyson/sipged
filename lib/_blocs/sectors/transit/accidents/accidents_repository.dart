// lib/_repository/sectors/traffic/accidents_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

class PageResult<T> {
  final List<T> items;
  final QueryDocumentSnapshot? lastDoc;
  PageResult(this.items, this.lastDoc);
}

class AccidentsRepository {
  AccidentsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  int _yearFromDateTime(DateTime dt, {bool local = true}) =>
      local ? dt.toLocal().year : dt.toUtc().year;

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateYearRef(int year) async {
    final q = await _db
        .collection('trafficAccidents')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.reference;
    return await _db.collection('trafficAccidents').add({'year': year});
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getYearRef(int year) async {
    final q = await _db
        .collection('trafficAccidents')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    return q.docs.isNotEmpty ? q.docs.first.reference : null;
  }

  // ---------- CRUD ----------
  Future<void> deleteAccident({required String id, required int year}) async {
    final yearRef = await _getYearRef(year);
    if (yearRef == null) return;
    final doc = await yearRef.collection('records').doc(id).get();
    if (doc.exists) await doc.reference.delete();
  }

  Future<void> saveOrUpdateAccident(AccidentsData data) async {
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
        : records.doc();
    data.id ??= docRef.id;

    data.year = year;
    data.month = month;
    data.yearDocId = yearRef.id;
    data.recordPath = docRef.path;

    final json = data.toJson()
      ..addAll({
        'year': year,
        'month': month,
        'yearDocId': yearRef.id,
        'recordPath': docRef.path,
        'yearMonthKey': '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
        'recordId': docRef.id,
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

    await _db.runTransaction((tx) async {
      tx.set(yearRef, {'year': year}, SetOptions(merge: true));
      tx.set(docRef, json, SetOptions(merge: true));
    });
  }

  // ---------- Consulta / Paginação ----------
  Future<PageResult<AccidentsData>> getAccidentsPage({
    int? year,
    int? month,
    String? city,
    QueryDocumentSnapshot? startAfter,
    int limit = 15,
    bool descending = true,
  }) async {
    Query q;

    if (year != null) {
      final yearRef = await _getYearRef(year);
      if (yearRef == null) return PageResult<AccidentsData>([], null);

      q = yearRef.collection('records').orderBy('date', descending: descending);

      if (month != null) {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 1);
        q = q
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
      }
      if (city != null && city.trim().isNotEmpty) {
        q = q.where('city', isEqualTo: city);
      }
    } else {
      q = _db.collectionGroup('records').orderBy('date', descending: descending);
      if (city != null && city.trim().isNotEmpty) {
        q = q.where('city', isEqualTo: city);
      }
      if (month != null) q = q.where('month', isEqualTo: month);
    }

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit);

    final snap = await q.get();
    final items = snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
    final last = snap.docs.isNotEmpty ? snap.docs.last : null;

    return PageResult(items, last);
  }

  Future<List<AccidentsData>> getAllAccidents({int? year, int? month, String? city}) async {
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
      }
      if (city != null && city.trim().isNotEmpty) {
        q = q.where('city', isEqualTo: city);
      }
    } else {
      q = _db.collectionGroup('records').orderBy('date');
      if (city != null && city.trim().isNotEmpty) q = q.where('city', isEqualTo: city);
      if (month != null) q = q.where('month', isEqualTo: month);
    }

    final snap = await q.get();
    return snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
  }

  Future<void> updateOrderOfAccidents({required int year}) async {
    final yearRef = await _getYearRef(year);
    if (yearRef == null) return;
    final q = await yearRef.collection('records').orderBy('date').get();

    final batch = _db.batch();
    int i = 0;
    for (final d in q.docs) {
      i++;
      batch.update(d.reference, {'order': i});
    }
    await batch.commit();
  }

  // ---------- Agregações ----------
  Map<String, int> contarTiposDeAcidente(List<AccidentsData> lista) {
    final Map<String, int> mapa = {};
    for (final a in lista) {
      final tipo = AccidentsData.normalizarTipoAcidente(a.typeOfAccident ?? 'INDEFINIDO');
      mapa[tipo] = (mapa[tipo] ?? 0) + 1;
    }
    return mapa;
  }

  /// Nova: totais por tipo de acidente como double (útil p/ gráficos)
  Future<Map<String, double>> getTotaisPorTipoAcidente(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {
      for (final t in AccidentsData.accidentTypes) t.toUpperCase(): 0.0,
    };
    for (final a in acidentes) {
      final raw = (a.typeOfAccident ?? '').toUpperCase().trim();
      if (raw.isEmpty) continue;
      final title = AccidentsData.getTitleByAccidentType(raw).toUpperCase();
      final key = (title == 'OUTROS') ? 'OUTROS' : raw;
      totais[key] = (totais[key] ?? 0) + 1.0;
    }
    return totais;
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

  // ---------- City helpers ----------
  Future<List<AccidentsData>> getAccidentsByCityList({
    required String cityName,
    int? year,
    int? month,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collectionGroup('records')
        .where('city', isEqualTo: cityName);

    if (year != null) q = q.where('year', isEqualTo: year);
    if (month != null) q = q.where('month', isEqualTo: month);

    q = q.orderBy('date', descending: true);

    final snap = await q.get();
    return snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
  }

  // ---------- Legacy fix ----------
  Future<void> corrigirDatasAcidentesCollectionGroup() async {
    final DateFormat formato = DateFormat('dd/MM/yyyy');
    final snap = await _db.collectionGroup('records').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final rawDate = data['date'];
      if (rawDate is String) {
        try {
          final parsed = formato.parseStrict(rawDate);
          await doc.reference.update({'date': Timestamp.fromDate(parsed)});
        } catch (_) {/* continua */}
      }
    }
  }
}
