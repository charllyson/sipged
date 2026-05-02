// lib/_blocs/modules/transit/infractions/infractions_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'infractions_data.dart';

class InfractionsRepository {
  InfractionsRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _containers {
    return _db.collection('trafficInfractions');
  }

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateContainerForYear(
      int year,
      ) async {
    final query = await _containers
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    final ref = _containers.doc();

    await ref.set({
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser?.uid ?? '',
    });

    return ref;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  listYearContainers() async {
    final query = await _containers.orderBy('year', descending: true).get();

    return query.docs;
  }

  Future<List<int>> listAvailableYears() async {
    final containers = await listYearContainers();

    final years = containers
        .map((doc) => (doc.data()['year'] as num?)?.toInt())
        .whereType<int>()
        .where((year) => year > 0)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return years;
  }

  Future<List<InfractionsData>> getAllInfractions() async {
    final snapshot = await _db.collectionGroup('records').get();

    return snapshot.docs.map((doc) {
      return InfractionsData.fromMap(
        doc.data(),
        id: doc.id,
      );
    }).toList();
  }

  Future<List<InfractionsData>> getInfractionsByYear(int year) async {
    final containers = await _containers
        .where('year', isEqualTo: year)
        .get();

    final List<InfractionsData> results = <InfractionsData>[];

    for (final container in containers.docs) {
      final records = await container.reference.collection('records').get();

      results.addAll(
        records.docs.map((doc) {
          return InfractionsData.fromMap(
            doc.data(),
            id: doc.id,
          );
        }),
      );
    }

    return results;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> pageRecordsByYear({
    required int year,
    DocumentSnapshot? lastDoc,
    int limit = 200,
  }) async {
    final containers = await _containers
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (containers.docs.isEmpty) {
      return _containers.doc('fake').collection('records').limit(0).get();
    }

    Query<Map<String, dynamic>> query = containers.docs.first.reference
        .collection('records')
        .orderBy('orderInfraction');

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.limit(limit).get();
  }

  Future<List<InfractionsData>> findDuplicatesByAitInYear(int year) async {
    final list = await getInfractionsByYear(year);

    final Map<String, InfractionsData> seen = <String, InfractionsData>{};
    final List<InfractionsData> duplicates = <InfractionsData>[];

    for (final infraction in list) {
      final String key = (infraction.aitNumber ?? '').trim().toUpperCase();

      if (key.isEmpty) continue;

      if (seen.containsKey(key)) {
        duplicates.add(infraction);
      } else {
        seen[key] = infraction;
      }
    }

    return duplicates;
  }

  Future<int> countWithGeolocationByYear(int year) async {
    final list = await getInfractionsByYear(year);

    return list.where((item) {
      return item.latitude != null && item.longitude != null;
    }).length;
  }

  Future<void> salvarOuAtualizarInfracao({
    required int year,
    required InfractionsData data,
  }) async {
    final user = _auth.currentUser;

    final containerRef = await _getOrCreateContainerForYear(year);
    final recordsRef = containerRef.collection('records');

    final docRef = data.id != null && data.id!.isNotEmpty
        ? recordsRef.doc(data.id)
        : recordsRef.doc();

    data.id ??= docRef.id;

    final snap = await docRef.get();

    final bool hasCreatedAt =
        snap.exists && snap.data()?['createdAt'] != null;

    final Map<String, dynamic> json = data.toJson()
      ..addAll({
        'id': docRef.id,
        'year': year,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
      });

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = user?.uid ?? '';
    } else {
      json.remove('createdAt');
      json.remove('createdBy');
    }

    await docRef.set(
      json,
      SetOptions(merge: true),
    );
  }

  Future<void> deleteInfraction({
    required int year,
    required String recordId,
  }) async {
    final containers = await _containers
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (containers.docs.isEmpty) {
      throw Exception('Container do ano $year não encontrado.');
    }

    await containers.docs.first.reference
        .collection('records')
        .doc(recordId)
        .delete();
  }

  Future<int> countByYear(int year) async {
    final list = await getInfractionsByYear(year);
    return list.length;
  }

  Future<List<InfractionsData>> searchByAit(String ait) async {
    final query = await _db
        .collectionGroup('records')
        .where('aitNumber', isEqualTo: ait)
        .get();

    return query.docs.map((doc) {
      return InfractionsData.fromMap(
        doc.data(),
        id: doc.id,
      );
    }).toList();
  }

  Future<Map<String, List<String>>> debugYearSources(
      int year, {
        int sample = 5,
      }) async {
    final containers = await _containers
        .where('year', isEqualTo: year)
        .get();

    final Map<String, List<String>> duplicateKeyCount =
    <String, List<String>>{};

    for (final container in containers.docs) {
      final records = await container.reference.collection('records').get();

      for (final doc in records.docs) {
        final data = doc.data();

        final String ait = (data['aitNumber'] ?? '')
            .toString()
            .trim()
            .toUpperCase();

        final dynamic ts = data['dateInfraction'];

        String stamp;

        if (ts is Timestamp) {
          final dt = ts.toDate();

          stamp = '${dt.year}-'
              '${dt.month.toString().padLeft(2, '0')}-'
              '${dt.day.toString().padLeft(2, '0')} '
              '${dt.hour.toString().padLeft(2, '0')}:'
              '${dt.minute.toString().padLeft(2, '0')}';
        } else {
          stamp = (ts ?? 'nodate').toString();
        }

        final String key = '$ait|$stamp';

        (duplicateKeyCount[key] ??= <String>[]).add(doc.reference.path);
      }
    }

    duplicateKeyCount.removeWhere((_, paths) => paths.length <= 1);

    return duplicateKeyCount;
  }
}