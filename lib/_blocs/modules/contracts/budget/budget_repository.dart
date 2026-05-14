// lib/_blocs/modules/contracts/budget/budget_repository.dart

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'budget_data.dart';

class BudgetRepository {
  BudgetRepository({
    required String tenantId,
    FirebaseFirestore? firestore,
  })  : _tenantId = tenantId.trim(),
        _db = firestore ?? FirebaseFirestore.instance {
    if (_tenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório no BudgetRepository.');
    }
  }

  final String _tenantId;
  final FirebaseFirestore _db;

  static const int kMaxBatchOps = 450;
  static const int kReadPageSize = 400;
  static const int kVersionsToKeep = 2;

  CollectionReference<Map<String, dynamic>> _budgetCollection(
      String contractId,
      ) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório no BudgetRepository.');
    }

    return _db
        .collection('tenants')
        .doc(_tenantId)
        .collection('contracts')
        .doc(cleanContractId)
        .collection('hiring')
        .doc('main')
        .collection('budget');
  }

  DocumentReference<Map<String, dynamic>> _metaRef(String contractId) {
    return _budgetCollection(contractId).doc('meta');
  }

  List<List<T>> _chunk<T>(List<T> source, int size) {
    if (source.isEmpty) return <List<T>>[];

    final chunks = <List<T>>[];

    for (var i = 0; i < source.length; i += size) {
      chunks.add(
        source.sublist(
          i,
          math.min(i + size, source.length),
        ),
      );
    }

    return chunks;
  }

  String _safeDocId(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (cleaned.isEmpty) return 'item';

    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  String _orderKeyFromCode(String code) {
    final parts = code
        .split('.')
        .map((item) => int.tryParse(item.trim()) ?? 0)
        .map((item) => item.toString().padLeft(5, '0'))
        .toList();

    if (parts.isEmpty) return '00000';

    return parts.join('_');
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getPaged(
      Query<Map<String, dynamic>> query, {
        int pageSize = kReadPageSize,
      }) async {
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      var currentQuery = query.limit(pageSize);

      if (lastDoc != null) {
        currentQuery = currentQuery.startAfterDocument(lastDoc);
      }

      final snap = await currentQuery.get();

      if (snap.docs.isEmpty) break;

      docs.addAll(snap.docs);
      lastDoc = snap.docs.last;

      if (snap.docs.length < pageSize) break;
    }

    return docs;
  }

  Future<BudgetData> load(String contractId) async {
    final metaRef = _metaRef(contractId);
    final metaSnap = await metaRef.get();

    if (!metaSnap.exists) {
      return BudgetData.empty();
    }

    final meta = metaSnap.data() ?? <String, dynamic>{};

    final schemaRaw = meta['schema'];
    final schema = schemaRaw is Map
        ? BudgetSchema.fromMap(Map<String, dynamic>.from(schemaRaw))
        : BudgetSchema.empty();

    if (schema.columns.isEmpty) {
      return BudgetData.empty();
    }

    final activeWriteId = (meta['activeWriteId'] ?? '').toString().trim();

    if (activeWriteId.isEmpty) {
      return BudgetData.withSchema(schema);
    }

    final versionRef = metaRef.collection('rows_v').doc(activeWriteId);

    final groupDocs = await _getPaged(
      versionRef.collection('groups').orderBy('entryIndex'),
    );

    final entries = <BudgetEntry>[];

    for (final groupDoc in groupDocs) {
      final groupData = groupDoc.data();

      final section = BudgetSection.fromMap(groupData);

      if (section.title.trim().isNotEmpty || section.order != 0) {
        entries.add(section);
      }

      final itemDocs = await _getPaged(
        groupDoc.reference.collection('items').orderBy('index'),
      );

      for (final itemDoc in itemDocs) {
        final item = BudgetItem.fromMap(itemDoc.data());

        entries.add(
          item.copyWith(
            values: normalizeRow(item.values, schema.columns.length),
          ),
        );
      }
    }

    return BudgetData(
      schema: schema,
      entries: List<BudgetEntry>.unmodifiable(entries),
    );
  }

  Future<void> save({
    required String contractId,
    required BudgetData data,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para salvar orçamento.');
    }

    final metaRef = _metaRef(cleanContractId);

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final writeId = nowMillis.toString();

    final versionRef = metaRef.collection('rows_v').doc(writeId);
    final groupsCollection = versionRef.collection('groups');

    final groupSets = <MapEntry<DocumentReference<Map<String, dynamic>>,
        Map<String, dynamic>>>[];

    final itemSets = <MapEntry<DocumentReference<Map<String, dynamic>>,
        Map<String, dynamic>>>[];

    var globalEntryIndex = 0;
    var itemIndex = 0;
    var sectionIndex = 0;

    String? currentGroupId;

    void createImplicitGroupIfNeeded() {
      if (currentGroupId != null) return;

      currentGroupId = 'section_000000_0';

      final groupRef = groupsCollection.doc(currentGroupId);

      groupSets.add(
        MapEntry(
          groupRef,
          <String, dynamic>{
            'kind': 'section',
            'order': 0,
            'title': '',
            'entryIndex': globalEntryIndex,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        ),
      );

      globalEntryIndex++;
      sectionIndex++;
    }

    for (final entry in data.entries) {
      if (entry is BudgetSection) {
        final groupId =
            'section_${sectionIndex.toString().padLeft(6, '0')}_${entry.order}';

        currentGroupId = groupId;

        final groupRef = groupsCollection.doc(groupId);

        groupSets.add(
          MapEntry(
            groupRef,
            <String, dynamic>{
              ...entry
                  .copyWith(
                entryIndex: globalEntryIndex,
              )
                  .toMap(),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        );

        sectionIndex++;
        globalEntryIndex++;
        continue;
      }

      if (entry is BudgetItem) {
        createImplicitGroupIfNeeded();

        final groupRef = groupsCollection.doc(currentGroupId);
        final itemsCollection = groupRef.collection('items');

        final orderKey = _orderKeyFromCode(entry.code);
        final docId = _safeDocId(
          '${itemIndex.toString().padLeft(8, '0')}_$orderKey',
        );

        final itemRef = itemsCollection.doc(docId);

        itemSets.add(
          MapEntry(
            itemRef,
            <String, dynamic>{
              ...entry
                  .copyWith(
                index: itemIndex,
                values: entry.normalizedValues(data.schema.columns.length),
              )
                  .toMap(
                schemaLength: data.schema.columns.length,
                orderKey: orderKey,
              ),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        );

        itemIndex++;
        globalEntryIndex++;
      }
    }

    await versionRef.set(
      <String, dynamic>{
        'writeId': writeId,
        'tenantId': _tenantId,
        'contractId': cleanContractId,
        'entryCount': data.entries.length,
        'itemCount': itemIndex,
        'sectionCount': sectionIndex,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final chunk in _chunk(groupSets, kMaxBatchOps)) {
      final batch = _db.batch();

      for (final item in chunk) {
        batch.set(item.key, item.value, SetOptions(merge: true));
      }

      await batch.commit();
    }

    for (final chunk in _chunk(itemSets, kMaxBatchOps)) {
      final batch = _db.batch();

      for (final item in chunk) {
        batch.set(item.key, item.value, SetOptions(merge: true));
      }

      await batch.commit();
    }

    await metaRef.set(
      <String, dynamic>{
        'tenantId': _tenantId,
        'contractId': cleanContractId,
        'schema': data.schema.toMap(),
        'activeWriteId': writeId,
        'entryCount': data.entries.length,
        'itemCount': itemIndex,
        'sectionCount': sectionIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await cleanupOldVersions(
      contractId: cleanContractId,
      keepLast: kVersionsToKeep,
    );
  }

  Future<void> saveFromTable({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    bool rowsIncludesHeader = true,
  }) async {
    final data = BudgetData.fromTable(
      headers: headers,
      colTypes: colTypes,
      colWidths: colWidths,
      rows: rows,
      rowsIncludesHeader: rowsIncludesHeader,
    );

    await save(
      contractId: contractId,
      data: data,
    );
  }

  Future<void> delete(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para excluir orçamento.');
    }

    final metaRef = _metaRef(cleanContractId);

    final versions = await metaRef.collection('rows_v').get();

    for (final version in versions.docs) {
      await _deleteVersion(version.reference);
    }

    await metaRef.delete();
  }

  Future<void> cleanupOldVersions({
    required String contractId,
    int keepLast = kVersionsToKeep,
  }) async {
    try {
      final metaRef = _metaRef(contractId);

      final versions = await metaRef.collection('rows_v').get();

      if (versions.docs.length <= keepLast) return;

      final docs = versions.docs.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      final toDelete = docs.take(math.max(0, docs.length - keepLast));

      for (final doc in toDelete) {
        await _deleteVersion(doc.reference);
      }
    } catch (_) {
      // Limpeza best-effort.
    }
  }

  Future<void> _deleteVersion(
      DocumentReference<Map<String, dynamic>> versionRef,
      ) async {
    final groups = await versionRef.collection('groups').get();

    for (final group in groups.docs) {
      final items = await group.reference.collection('items').get();

      for (final chunk in _chunk(items.docs, kMaxBatchOps)) {
        final batch = _db.batch();

        for (final item in chunk) {
          batch.delete(item.reference);
        }

        await batch.commit();
      }

      await group.reference.delete();
    }

    await versionRef.delete();
  }
}