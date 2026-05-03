// lib/_blocs/modules/transit/infractions/infractions_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'infractions_data.dart';

class InfractionsRepository {
  InfractionsRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    String? tenantId,
    String? baseCollectionPath,
    bool enableLegacyFallback = true,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tenantId = tenantId,
        _baseCollectionPath = baseCollectionPath,
        _enableLegacyFallback = enableLegacyFallback;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  final String? _tenantId;
  final String? _baseCollectionPath;
  final bool _enableLegacyFallback;

  /// ID fixo temporário para teste.
  static const String _manualTenantIdForTest = 'SZQmefRUqdtLB14ahcuh';

  /// Estrutura antiga.
  static const String legacyCollectionPath = 'trafficInfractions';

  /// Estrutura nova temporária para teste:
  ///
  /// tenants/SZQmefRUqdtLB14ahcuh/traffic/infractions/items
  ///
  /// Depois, remova o uso de [_manualTenantIdForTest] e volte para [_tenantId].
  String get collectionPath {
    final explicit = (_baseCollectionPath ?? '').trim();

    if (explicit.isNotEmpty) {
      return explicit;
    }

    final tenant = _manualTenantIdForTest.trim();

    if (tenant.isNotEmpty) {
      return 'tenants/$tenant/traffic/infractions/items';
    }

    final dynamicTenant = (_tenantId ?? '').trim();

    if (dynamicTenant.isNotEmpty) {
      return 'tenants/$dynamicTenant/traffic/infractions/items';
    }

    return 'traffic/infractions/items';
  }

  CollectionReference<Map<String, dynamic>> get _containers {
    return _db.collection(collectionPath);
  }

  CollectionReference<Map<String, dynamic>> get _legacyContainers {
    return _db.collection(legacyCollectionPath);
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getContainerByYearFrom(
      CollectionReference<Map<String, dynamic>> collection,
      int year,
      ) async {
    final deterministicRef = collection.doc(year.toString());
    final deterministicSnap = await deterministicRef.get();

    if (deterministicSnap.exists) {
      return deterministicRef;
    }

    final query = await collection.where('year', isEqualTo: year).limit(1).get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    return null;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getContainerByYearCompat(
      int year,
      ) async {
    final currentRef = await _getContainerByYearFrom(_containers, year);

    if (currentRef != null) {
      return currentRef;
    }

    if (!_enableLegacyFallback) {
      return null;
    }

    return _getContainerByYearFrom(_legacyContainers, year);
  }

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateContainerForYear(
      int year,
      ) async {
    final existing = await _getContainerByYearFrom(_containers, year);

    if (existing != null) {
      await existing.set(
        {
          'year': year,
          'module': 'traffic',
          'type': 'infractions',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      return existing;
    }

    final ref = _containers.doc(year.toString());

    await ref.set(
      {
        'year': year,
        'module': 'traffic',
        'type': 'infractions',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    return ref;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _listYearContainersFrom(
      CollectionReference<Map<String, dynamic>> collection,
      ) async {
    final query = await collection.orderBy('year', descending: true).get();
    return query.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  listYearContainers() async {
    final current = await _listYearContainersFrom(_containers);

    if (current.isNotEmpty || !_enableLegacyFallback) {
      return current;
    }

    return _listYearContainersFrom(_legacyContainers);
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

  Future<List<InfractionsData>> _getAllInfractionsFrom(
      CollectionReference<Map<String, dynamic>> collection,
      ) async {
    final containers = await collection.get();

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

  Future<List<InfractionsData>> getAllInfractions() async {
    final current = await _getAllInfractionsFrom(_containers);

    if (current.isNotEmpty || !_enableLegacyFallback) {
      return current;
    }

    return _getAllInfractionsFrom(_legacyContainers);
  }

  Future<List<InfractionsData>> getInfractionsByYear(int year) async {
    final container = await _getContainerByYearCompat(year);

    if (container == null) {
      return <InfractionsData>[];
    }

    final records = await container.collection('records').get();

    return records.docs.map((doc) {
      return InfractionsData.fromMap(
        doc.data(),
        id: doc.id,
      );
    }).toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> pageRecordsByYear({
    required int year,
    DocumentSnapshot? lastDoc,
    int limit = 200,
  }) async {
    final container = await _getContainerByYearCompat(year);

    if (container == null) {
      return _containers.doc('__empty__').collection('records').limit(0).get();
    }

    Query<Map<String, dynamic>> query =
    container.collection('records').orderBy('orderInfraction');

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.limit(limit.clamp(1, 500)).get();
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

    final bool hasCreatedAt = snap.exists && snap.data()?['createdAt'] != null;

    final Map<String, dynamic> json = data.toJson()
      ..addAll({
        'id': docRef.id,
        'year': year,
        'yearDocId': containerRef.id,
        'recordId': docRef.id,
        'recordPath': docRef.path,
        'sourcePath': docRef.path,
        'module': 'traffic',
        'type': 'infractions',
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

    await _db.runTransaction((tx) async {
      tx.set(
        containerRef,
        {
          'year': year,
          'module': 'traffic',
          'type': 'infractions',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      tx.set(
        docRef,
        json,
        SetOptions(merge: true),
      );
    });
  }

  Future<void> deleteInfraction({
    required int year,
    required String recordId,
  }) async {
    final container = await _getContainerByYearCompat(year);

    if (container == null) {
      throw Exception('Container do ano $year não encontrado.');
    }

    await container.collection('records').doc(recordId).delete();
  }

  Future<int> countByYear(int year) async {
    final list = await getInfractionsByYear(year);
    return list.length;
  }

  Future<List<InfractionsData>> searchByAit(String ait) async {
    final cleanAit = ait.trim();

    if (cleanAit.isEmpty) {
      return <InfractionsData>[];
    }

    final containers = await listYearContainers();

    final List<InfractionsData> results = <InfractionsData>[];

    for (final container in containers) {
      final query = await container.reference
          .collection('records')
          .where('aitNumber', isEqualTo: cleanAit)
          .get();

      results.addAll(
        query.docs.map((doc) {
          return InfractionsData.fromMap(
            doc.data(),
            id: doc.id,
          );
        }),
      );
    }

    return results;
  }

  Future<Map<String, List<String>>> debugYearSources(
      int year, {
        int sample = 5,
      }) async {
    final container = await _getContainerByYearCompat(year);

    final Map<String, List<String>> duplicateKeyCount =
    <String, List<String>>{};

    if (container == null) {
      return duplicateKeyCount;
    }

    final records = await container.collection('records').get();

    for (final doc in records.docs) {
      final data = doc.data();

      final String ait =
      (data['aitNumber'] ?? '').toString().trim().toUpperCase();

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

    duplicateKeyCount.removeWhere((_, paths) => paths.length <= 1);

    return duplicateKeyCount;
  }
}