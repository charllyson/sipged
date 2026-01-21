/*
// lib/_blocs/modules/contracts/budget/budget_bloc.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/modules/contracts/budget/budget_data.dart'; // <- seu domínio tipado
// Repo interno nesta mesma classe (para manter o nome "Bloc" que você já usa)

class BudgetBloc {
  BudgetBloc();

  // ======================= Infra (Firestore) =======================
  CollectionReference<Map<String, dynamic>> _base(String contractId) =>
      FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('budget');

  static const int _kMaxBatchOps = 500;

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, math.min(i + size, list.length)));
    }
    return chunks;
  }

  String _orderKeyFromCode(String code) {
    final parts = code.split('.');
    return parts.map((p) => p.padLeft(4, '0')).join('');
  }

  // ======================= API NOVA (Domínio) =======================

  /// Carrega e entrega **BudgetData** (domínio), independente do schema antigo.
  Future<BudgetData> load(String contractId) async {
    final metaRef = _base(contractId).doc('meta');
    final metaSnap = await metaRef.get();
    if (!metaSnap.exists) {
      return BudgetData.withSchema(BudgetSchema(const []));
    }

    final meta = metaSnap.data()!;
    final List<dynamic> headersDyn = (meta['headers'] ?? []) as List<dynamic>;
    final List<dynamic> colTypesDyn = (meta['colTypes'] ?? []) as List<dynamic>;
    final List<dynamic> colWidthsDyn = (meta['colWidths'] ?? []) as List<dynamic>;
    final String? activeWriteId = (meta['activeWriteId'] as String?);

    final headers = headersDyn.map((e) => (e ?? '').toString()).toList();
    final colTypes = colTypesDyn.map((e) => (e ?? '').toString()).toList();
    final colWidths = colWidthsDyn
        .map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 120.0)
        .toList();

    // Reconstrói uma table "legada" para reaproveitar o parser do domínio
    final List<List<String>> table = [];
    if (headers.isNotEmpty) table.add(headers);

    List<String> _padRow(List<String> r) {
      if (headers.isEmpty) return r;
      if (r.length >= headers.length) return r.take(headers.length).toList();
      return [...r, for (int i = r.length; i < headers.length; i++) ''];
    }

    if (activeWriteId != null && activeWriteId.isNotEmpty) {
      final groups = await metaRef
          .collection('rows_v')
          .doc(activeWriteId)
          .collection('groups')
          .orderBy('order')
          .get();

      for (final g in groups.docs) {
        final gData = g.data();
        final order = (gData['order'] ?? '').toString();
        final title = (gData['title'] ?? '').toString();

        if (order.isNotEmpty || title.isNotEmpty) {
          table.add(_padRow([order, title, '', '', '', '']));
        }

        Query<Map<String, dynamic>> q = g.reference.collection('items').orderBy('index');
        try {
          final itSnap = await q.get();
          for (final it in itSnap.docs) {
            final data = it.data();
            final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
            table.add(_padRow(values.map((e) => (e ?? '').toString()).toList()));
          }
        } catch (_) {
          final itSnap = await g.reference.collection('items').orderBy('orderKey').get();
          for (final it in itSnap.docs) {
            final data = it.data();
            final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
            table.add(_padRow(values.map((e) => (e ?? '').toString()).toList()));
          }
        }
      }

      return BudgetData.fromLegacy(
        headers: headers,
        colTypes: colTypes,
        colWidths: colWidths,
        tableData: table,
      );
    }

    // Fallback: caminho antigo (rows/)
    final rowsCol = metaRef.collection('rows');
    final groups = await rowsCol.orderBy('order').get();
    for (final g in groups.docs) {
      final gData = g.data();
      final order = (gData['order'] ?? '').toString();
      final title = (gData['title'] ?? '').toString();
      if (order.isNotEmpty || title.isNotEmpty) {
        table.add(_padRow([order, title, '', '', '', '']));
      }
      final items = await g.reference.collection('items').orderBy('index').get();
      for (final it in items.docs) {
        final data = it.data();
        final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
        table.add(_padRow(values.map((e) => (e ?? '').toString()).toList()));
      }
    }

    return BudgetData.fromLegacy(
      headers: headers,
      colTypes: colTypes,
      colWidths: colWidths,
      tableData: table,
    );
  }

  /// Salva um **BudgetData** do domínio (swap de versão).
  Future<void> save({
    required String contractId,
    required BudgetData data,
  }) async {
    final metaRef = _base(contractId).doc('meta');

    // 1) metadados do schema
    await metaRef.set({
      'headers': data.schema.headerNames,
      'colTypes': data.schema.headerTypes,
      'colWidths': data.schema.headerWidths,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2) versão nova
    final writeId = DateTime.now().millisecondsSinceEpoch.toString();
    final rowsVersionDoc = metaRef.collection('rows_v').doc(writeId);
    final groupsCol = rowsVersionDoc.collection('groups');

    final pendingGroupSets = <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];
    final pendingItemSets = <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];

    int runningIndex = 0;
    int currentGroupOrder = -1;
    String currentGroupId = '';

    for (final entry in data.entries) {
      if (entry is BudgetSection) {
        currentGroupOrder = entry.order;
        currentGroupId = currentGroupOrder.toString();
        final gRef = groupsCol.doc(currentGroupId);
        pendingGroupSets.add(MapEntry(gRef, {
          'order': entry.order,
          'title': entry.title,
          'updatedAt': FieldValue.serverTimestamp(),
        }));
      } else if (entry is BudgetItem) {
        if (currentGroupId.isEmpty) {
          currentGroupOrder = 0;
          currentGroupId = '0';
          final gRef = groupsCol.doc(currentGroupId);
          pendingGroupSets.add(MapEntry(gRef, {
            'order': currentGroupOrder,
            'title': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }));
        }
        final itemsCol = groupsCol.doc(currentGroupId).collection('items');
        final orderKey = _orderKeyFromCode(entry.code);
        final docId = '${orderKey}_$runningIndex'.padRight(40, '0').substring(0, 40);
        final iRef = itemsCol.doc(docId);

        final fixedRow = List<String>.generate(
          data.schema.columns.length,
              (i) => (i < entry.values.length) ? entry.values[i] : '',
        );

        pendingItemSets.add(MapEntry(iRef, {
          'code': entry.code,
          'depth': entry.depth,
          'index': runningIndex,
          'orderKey': orderKey,
          'values': fixedRow,
          'updatedAt': FieldValue.serverTimestamp(),
        }));

        runningIndex++;
      }
    }

    // 3) batches
    for (final chunk in _chunk(pendingGroupSets, _kMaxBatchOps)) {
      final batch = FirebaseFirestore.instance.batch();
      for (final e in chunk) {
        batch.set(e.key, e.value, SetOptions(merge: true));
      }
      await batch.commit();
    }
    for (final chunk in _chunk(pendingItemSets, _kMaxBatchOps)) {
      final batch = FirebaseFirestore.instance.batch();
      for (final e in chunk) {
        batch.set(e.key, e.value, SetOptions(merge: true));
      }
      await batch.commit();
    }

    // 4) swap
    await metaRef.set({
      'activeWriteId': writeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 5) limpeza best-effort
    _cleanupOldVersions(metaRef, keepLast: 2);
  }

  Future<void> _cleanupOldVersions(
      DocumentReference<Map<String, dynamic>> metaRef, {
        int keepLast = 2,
      }) async {
    try {
      final rowsV = await metaRef.collection('rows_v').get();
      if (rowsV.docs.length <= keepLast) return;
      final docs = rowsV.docs..sort((a, b) => a.id.compareTo(b.id));
      final toDelete = docs.take(math.max(0, docs.length - keepLast)).toList();

      for (final d in toDelete) {
        final groups = await d.reference.collection('groups').get();
        for (final g in groups.docs) {
          final items = await g.reference.collection('items').get();
          for (final chunk in _chunk(items.docs, _kMaxBatchOps)) {
            final batch = FirebaseFirestore.instance.batch();
            for (final it in chunk) {
              batch.delete(it.reference);
            }
            await batch.commit();
          }
          await g.reference.delete();
        }
        await d.reference.delete();
      }
    } catch (_) {}
  }

  // ======================= SHIMS DE COMPATIBILIDADE =======================
  // Permitem manter chamadas antigas enquanto migra UI/Store.

  /// LEGADO: carrega no formato de domínio (mesmo nome antigo).
  Future<BudgetData> loadBudgetNested(String contractId) => load(contractId);

  /// LEGADO: recebe arrays, converte para domínio e salva.
  Future<void> saveBudgetNested({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    bool rowsIncludesHeader = true,
  }) async {
    // Garante que a primeira linha seja header
    final table = <List<String>>[];
    if (rowsIncludesHeader) {
      if (rows.isEmpty) return;
      table.add(headers.isNotEmpty ? headers : rows.first);
      table.addAll(rows.skip(1));
    } else {
      table.add(headers);
      table.addAll(rows);
    }

    final data = BudgetData.fromLegacy(
      headers: headers.isNotEmpty ? headers : (rows.isNotEmpty ? rows.first : <String>[]),
      colTypes: colTypes,
      colWidths: colWidths,
      tableData: table,
    );

    await save(contractId: contractId, data: data);
  }

  void dispose() {}
}
*/
