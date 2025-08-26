import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisged/_blocs/documents/contracts/budget/budget_data.dart';

class BudgetBloc {
  CollectionReference<Map<String, dynamic>> _base(String contractId) =>
      FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('budget');

  // ---------- SAVE (aninhado) ----------
  Future<void> saveBudgetNested({
    required String contractId,
    required List<String> headers,
    required List<String> colTypes,
    required List<double> colWidths,
    required List<List<String>> rows,
    bool rowsIncludesHeader = true,
  }) async {
    final metaRef = _base(contractId).doc('meta');

    // 1) salva meta
    await metaRef.set({
      'headers': headers,
      'colTypes': colTypes,
      'colWidths': colWidths,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2) limpa subcoleção rows anterior
    final rowsCol = metaRef.collection('rows');
    final oldGroups = await rowsCol.get();
    for (final g in oldGroups.docs) {
      final items = await g.reference.collection('items').get();
      for (final it in items.docs) {
        await it.reference.delete();
      }
      await g.reference.delete();
    }

    // 3) regrava grupos + itens
    final startIndex = rowsIncludesHeader ? 1 : 0;

    List<String> _padRow(List<String> r) {
      if (r.length >= headers.length) return r.take(headers.length).toList();
      return [...r, for (int i = r.length; i < headers.length; i++) ''];
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

    int currentGroupOrder = -1;
    String currentGroupId = '';
    String currentGroupTitle = '';
    int runningIndex = 0;

    for (int r = startIndex; r < rows.length; r++) {
      final row = _padRow(rows[r]);
      if (row.every((c) => c.trim().isEmpty)) continue;

      final c0 = row[0].trim();

      if (_isSectionRow(row)) {
        currentGroupOrder = int.tryParse(c0) ?? (currentGroupOrder + 1);
        currentGroupId = currentGroupOrder.toString();
        currentGroupTitle = (row.length > 1 ? row[1].trim() : '');

        await rowsCol.doc(currentGroupId).set({
          'order': currentGroupOrder,
          'title': currentGroupTitle,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        continue;
      }

      if (codeRe.hasMatch(c0)) {
        if (currentGroupId.isEmpty) {
          currentGroupOrder = 0;
          currentGroupId = '0';
          currentGroupTitle = '';
          await rowsCol.doc(currentGroupId).set({
            'order': currentGroupOrder,
            'title': currentGroupTitle,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        final itemsCol = rowsCol.doc(currentGroupId).collection('items');
        final depth = c0.split('.').length;
        final orderKey = _orderKeyFromCode(c0);

        await itemsCol.add({
          'code': c0,
          'depth': depth,
          'index': runningIndex,
          'orderKey': orderKey,
          'values': row,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        runningIndex++;
      }
    }
  }

  // ---------- LOAD (aninhado) ----------
  Future<BudgetData> loadBudgetNested(String contractId) async {
    final metaRef = _base(contractId).doc('meta');
    final metaSnap = await metaRef.get();
    if (!metaSnap.exists) return BudgetData.empty();

    final meta = metaSnap.data()!;
    final List<dynamic> headersDyn = (meta['headers'] ?? []) as List<dynamic>;
    final List<dynamic> colTypesDyn = (meta['colTypes'] ?? []) as List<dynamic>;
    final List<dynamic> colWidthsDyn = (meta['colWidths'] ?? []) as List<dynamic>;

    final headers = headersDyn.map((e) => (e ?? '').toString()).toList();
    final colTypes = colTypesDyn.map((e) => (e ?? '').toString()).toList();
    final colWidths = colWidthsDyn
        .map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 100.0)
        .toList();

    final rowsCol = metaRef.collection('rows');
    final groups = await rowsCol.orderBy('order').get();

    final List<List<String>> table = [];
    if (headers.isNotEmpty) table.add(headers);

    List<String> _padRow(List<String> r) {
      if (headers.isEmpty) return r;
      if (r.length >= headers.length) return r.take(headers.length).toList();
      return [...r, for (int i = r.length; i < headers.length; i++) ''];
    }

    for (final g in groups.docs) {
      final gData = g.data();
      final order = (gData['order'] ?? '').toString();
      final title = (gData['title'] ?? '').toString();

      if (order.isNotEmpty || title.isNotEmpty) {
        final sectionRow = _padRow([order, title, '', '', '', '']);
        table.add(sectionRow);
      }

      final items = await g.reference.collection('items').orderBy('index').get();

      for (final it in items.docs) {
        final data = it.data();
        final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
        final row = _padRow(values.map((e) => (e ?? '').toString()).toList());
        table.add(row);
      }
    }

    return BudgetData(
      tableData: table,
      colTypes: colTypes,
      colWidths: colWidths,
    );
  }

  /// Como não há streams/timers, o dispose é no-op — existe só para Provider aceitar `dispose:`.
  void dispose() {}
}
