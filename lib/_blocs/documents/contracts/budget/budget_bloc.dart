import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetBloc {
  CollectionReference<Map<String, dynamic>> _base(String contractId) =>
      FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('budget');

  // ---------- Utils de chunk/batch ----------
  static const int _kMaxBatchOps = 500;

  Future<void> _commitBatches(List<WriteBatch> batches) async {
    for (final b in batches) {
      await b.commit();
    }
  }

  /// Quebra uma lista em sublistas de até [size]
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, math.min(i + size, list.length)));
    }
    return chunks;
  }

  // ---------- SAVE (versão segura com swap) ----------
  Future<void> saveBudgetNested({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    bool rowsIncludesHeader = true,
  }) async {
    final metaRef = _base(contractId).doc('meta');

    // 0) writeId único desta gravação
    final writeId = DateTime.now().millisecondsSinceEpoch.toString();
    final rowsVersionDoc = metaRef.collection('rows_v').doc(writeId);
    final groupsCol = rowsVersionDoc.collection('groups');

    // 1) salva meta base (ainda sem trocar activeWriteId)
    await metaRef.set({
      'headers': headers,
      'colTypes': colTypes,
      'colWidths': colWidths,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ---------------- Helpers de parsing ----------------
    List<String> _padRow(List<String> r, int headerLen) {
      if (r.length >= headerLen) return r.take(headerLen).toList();
      return [...r, for (int i = r.length; i < headerLen; i++) ''];
    }

    bool _isSectionRow(List<String> r) {
      if (r.isEmpty) return false;
      final c0 = r[0].trim();
      if (int.tryParse(c0) == null) return false;
      if (r.length < 2) return true;
      final title = r[1].trim();
      final onlyLetters = title.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ ]'), '');
      return onlyLetters.isNotEmpty && onlyLetters == onlyLetters.toUpperCase();
    }

    final codeRe = RegExp(r'^\d+(?:\.\d+)+$');

    String _orderKeyFromCode(String code) {
      final parts = code.split('.');
      return parts.map((p) => p.padLeft(4, '0')).join('');
    }

    // 2) processa linhas e guarda operações a escrever
    final startIndex = rowsIncludesHeader ? 1 : 0;
    final headerLen = headers.length;

    int currentGroupOrder = -1;
    String currentGroupId = '';
    String currentGroupTitle = '';
    int runningIndex = 0;

    // acumuladores para batch
    final pendingGroupSets = <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];
    final pendingItemSets = <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];

    for (int r = startIndex; r < rows.length; r++) {
      final row = _padRow(
        rows[r].map((e) => (e ?? '').toString()).toList(),
        headerLen,
      );

      if (row.every((c) => c.trim().isEmpty)) continue;

      final c0 = row[0].trim();

      // Seção (grupo)
      if (_isSectionRow(row)) {
        currentGroupOrder = int.tryParse(c0) ?? (currentGroupOrder + 1);
        currentGroupId = currentGroupOrder.toString();
        currentGroupTitle = (row.length > 1 ? row[1].trim() : '');

        final gRef = groupsCol.doc(currentGroupId);
        pendingGroupSets.addAll([
          MapEntry(
            gRef,
            {
              'order': currentGroupOrder,
              'title': currentGroupTitle,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          )
        ]);
        continue;
      }

      // Item (tem código “1.2.3”)
      if (codeRe.hasMatch(c0)) {
        if (currentGroupId.isEmpty) {
          currentGroupOrder = 0;
          currentGroupId = '0';
          currentGroupTitle = '';
          final gRef = groupsCol.doc(currentGroupId);
          pendingGroupSets.addAll([
            MapEntry(
              gRef,
              {
                'order': currentGroupOrder,
                'title': currentGroupTitle,
                'updatedAt': FieldValue.serverTimestamp(),
              },
            )
          ]);
        }

        final itemsCol = groupsCol.doc(currentGroupId).collection('items');
        final depth = c0.split('.').length;
        final orderKey = _orderKeyFromCode(c0);

        // docId estável (orderKey + runningIndex) evita “add()” sequencial
        final docId = '${orderKey}_$runningIndex'.padRight(40, '0').substring(0, 40);
        final iRef = itemsCol.doc(docId);

        pendingItemSets.addAll([
          MapEntry(
            iRef,
            {
              'code': c0,
              'depth': depth,
              'index': runningIndex,
              'orderKey': orderKey,
              'values': row,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          )
        ]);

        runningIndex++;
      }
    }

    // 3) grava grupos e itens em batches (≤500)
    final groupEntries = pendingGroupSets.toList();
    final itemEntries = pendingItemSets.toList();

    // Escreve groups
    for (final chunk in _chunk(groupEntries, _kMaxBatchOps)) {
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in chunk) {
        batch.set(entry.key, entry.value, SetOptions(merge: true));
      }
      await batch.commit();
    }

    // Escreve items
    for (final chunk in _chunk(itemEntries, _kMaxBatchOps)) {
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in chunk) {
        batch.set(entry.key, entry.value, SetOptions(merge: true));
      }
      await batch.commit();
    }

    // 4) por último, troca a versão ativa (swap atômico)
    await metaRef.set({
      'activeWriteId': writeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 5) (opcional) dispara limpeza “melhor esforço” de versões antigas (não bloqueia)
    _cleanupOldVersions(metaRef, keepLast: 2);
  }

  /// Limpeza “best-effort” de versões antigas.
  Future<void> _cleanupOldVersions(
      DocumentReference<Map<String, dynamic>> metaRef, {
        int keepLast = 2,
      }) async {
    try {
      final rowsV = await metaRef.collection('rows_v').get();
      if (rowsV.docs.length <= keepLast) return;

      // ordena por id (timestamp como string crescente)
      final docs = rowsV.docs..sort((a, b) => a.id.compareTo(b.id));
      final toDelete = docs.take(math.max(0, docs.length - keepLast)).toList();

      for (final d in toDelete) {
        // apaga subcoleção groups/items em lotes
        final groups = await d.reference.collection('groups').get();
        for (final g in groups.docs) {
          final items = await g.reference.collection('items').get();
          // deleta items em batches
          final itemChunks = _chunk(items.docs, _kMaxBatchOps);
          for (final chunk in itemChunks) {
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
    } catch (_) {
      // silencioso: limpeza é best-effort
    }
  }

  // ---------- LOAD (lendo activeWriteId; fallback p/ schema antigo) ----------
  Future<BudgetData> loadBudgetNested(String contractId) async {
    final metaRef = _base(contractId).doc('meta');
    final metaSnap = await metaRef.get();
    if (!metaSnap.exists) return BudgetData.empty();

    final meta = metaSnap.data()!;
    final List<dynamic> headersDyn = (meta['headers'] ?? []) as List<dynamic>;
    final List<dynamic> colTypesDyn = (meta['colTypes'] ?? []) as List<dynamic>;
    final List<dynamic> colWidthsDyn = (meta['colWidths'] ?? []) as List<dynamic>;
    final String? activeWriteId = (meta['activeWriteId'] as String?);

    final headers = headersDyn.map((e) => (e ?? '').toString()).toList();
    final colTypes = colTypesDyn.map((e) => (e ?? '').toString()).toList();
    final colWidths = colWidthsDyn
        .map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 100.0)
        .toList();

    final List<List<String>> table = [];
    if (headers.isNotEmpty) table.add(headers);

    List<String> _padRow(List<String> r) {
      if (headers.isEmpty) return r;
      if (r.length >= headers.length) return r.take(headers.length).toList();
      return [...r, for (int i = r.length; i < headers.length; i++) ''];
    }

    // --- Caminho novo (versão ativa) ---
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

        // tenta por index; se ausente, por orderKey
        Query<Map<String, dynamic>> q = g.reference.collection('items').orderBy('index');
        try {
          final itSnap = await q.get();
          for (final it in itSnap.docs) {
            final data = it.data();
            final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
            table.add(_padRow(values.map((e) => (e ?? '').toString()).toList()));
          }
        } catch (_) {
          // fallback: orderBy orderKey
          final itSnap = await g.reference.collection('items').orderBy('orderKey').get();
          for (final it in itSnap.docs) {
            final data = it.data();
            final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
            table.add(_padRow(values.map((e) => (e ?? '').toString()).toList()));
          }
        }
      }

      return BudgetData(
        tableData: table,
        colTypes: colTypes,
        colWidths: colWidths,
      );
    }

    // --- Fallback: caminho antigo (rows/groups/items) ---
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

    return BudgetData(
      tableData: table,
      colTypes: colTypes,
      colWidths: colWidths,
    );
  }

  void dispose() {}
}

// ----------------- DATA HOLDER -----------------
class BudgetData {
  final List<List<String>> tableData;
  final List<String> colTypes;
  final List<double> colWidths;

  const BudgetData({
    required this.tableData,
    required this.colTypes,
    required this.colWidths,
  });

  bool get isEmpty => tableData.isEmpty;

  factory BudgetData.empty() =>
      const BudgetData(tableData: [], colTypes: [], colWidths: []);
}
