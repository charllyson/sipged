import 'package:cloud_firestore/cloud_firestore.dart';

int _extractYearFromTimestamp(Timestamp ts, {bool useLocal = true}) {
  final dt = ts.toDate();
  return useLocal ? dt.toLocal().year : dt.toUtc().year;
}

class _YearDocCache {
  final _cache = <int, DocumentReference>{};

  Future<DocumentReference> getOrCreateYearDoc(int year) async {
    if (_cache.containsKey(year)) return _cache[year]!;

    final db = FirebaseFirestore.instance;
    // Procura se já existe um doc de ano
    final q = await db
        .collection('trafficAccidents')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      final ref = q.docs.first.reference;
      _cache[year] = ref;
      return ref;
    }

    // Cria com ID automático contendo o campo year
    final ref = await db.collection('trafficAccidents').add({'year': year});
    _cache[year] = ref;
    return ref;
  }
}

/// Rode uma vez para migrar todos os acidentes
Future<void> migrarAcidentesPorAno({
  bool usarAnoLocal = true,
  int pageSize = 500,
  int maxOpsPorBatch = 400,
}) async {
  final db = FirebaseFirestore.instance;
  final yearCache = _YearDocCache();

  DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  var terminou = false;

  while (!terminou) {
    var query = db.collection('accidents').orderBy('date').limit(pageSize);
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);

    final snap = await query.get();
    if (snap.docs.isEmpty) break;

    WriteBatch batch = db.batch();
    var ops = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['date'];
      if (ts is! Timestamp) continue;

      final year = _extractYearFromTimestamp(ts, useLocal: usarAnoLocal);

      // Obtém (ou cria) o doc do ano com ID automático
      final yearRef = await yearCache.getOrCreateYearDoc(year);

      // Escreve/atualiza o registro na subcoleção "records" com o mesmo ID do acidente
      final recordRef = yearRef.collection('records').doc(doc.id);
      final newData = {
        ...data,
        'year': year,
        'sourcePath': 'accidents/${doc.id}',
      };

      // Garante também que o doc do ano tenha o campo year correto (id é auto)
      batch.set(yearRef, {'year': year}, SetOptions(merge: true));
      ops++;

      batch.set(recordRef, newData, SetOptions(merge: true));
      ops++;

      if (ops >= maxOpsPorBatch) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }

    await batch.commit();
    lastDoc = snap.docs.last;
    if (snap.docs.length < pageSize) terminou = true;
  }
}
