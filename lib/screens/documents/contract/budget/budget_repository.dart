// budget_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetSnapshot {
  final List<List<String>> tableData;
  final List<String> colTypes;
  final List<double> colWidths;

  const BudgetSnapshot({
    required this.tableData,
    required this.colTypes,
    required this.colWidths,
  });

  bool get isEmpty => tableData.isEmpty;

  factory BudgetSnapshot.empty() =>
      const BudgetSnapshot(tableData: [], colTypes: [], colWidths: []);
}

class BudgetRepository {
  CollectionReference<Map<String, dynamic>> _base(String contractId) =>
      FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('budget');

  /// ---------- SAVE (aninhado) ----------
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

    // 2) limpa subcoleção rows anterior (opcional mas recomendado)
    final rowsCol = metaRef.collection('rows');
    final oldGroups = await rowsCol.get();
    for (final g in oldGroups.docs) {
      // apaga items
      final items = await g.reference.collection('items').get();
      for (final it in items.docs) {
        await it.reference.delete();
      }
      await g.reference.delete();
    }

    // 3) regrava grupos + itens
    // Se a primeira linha é o cabeçalho (como na sua grade), pule-a:
    final startIndex = rowsIncludesHeader ? 1 : 0;

    // util: normaliza tamanho de linha
    List<String> _padRow(List<String> r) {
      if (r.length >= headers.length) return r.take(headers.length).toList();
      return [...r, for (int i = r.length; i < headers.length; i++) ''];
    }

    // Detecta linhas de seção (ex.: "3" na col 0 e título em MAIÚSCULO na col 1)
    bool _isSectionRow(List<String> r) {
      if (r.isEmpty) return false;
      final c0 = r[0].trim();
      if (int.tryParse(c0) == null) return false;
      if (r.length < 2) return true; // aceita mesmo sem título
      final title = r[1].trim();
      final onlyLetters = title.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ ]'), '');
      return onlyLetters.isNotEmpty && onlyLetters == onlyLetters.toUpperCase();
    }

    // item “código” tipo 3.8.1, 1.2.10, etc
    final codeRe = RegExp(r'^\d+(?:\.\d+)+$');

    String _orderKeyFromCode(String code) {
      // 3.8.1 -> 0003 0008 0001 (string para ordenar lexicograficamente)
      final parts = code.split('.');
      return parts.map((p) => p.padLeft(4, '0')).join('');
    }

    int currentGroupOrder = -1;
    String currentGroupId = '';
    String currentGroupTitle = '';

    // contador crescente para "index" (mantém ordem exata como veio da planilha)
    int runningIndex = 0;

    for (int r = startIndex; r < rows.length; r++) {
      final row = _padRow(rows[r]);
      if (row.every((c) => c.trim().isEmpty)) continue;

      final c0 = row[0].trim();

      if (_isSectionRow(row)) {
        // fecha grupo anterior? (nada a fazer; já salvamos itens à medida que aparecem)
        // abre novo grupo
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

      // é item?
      if (codeRe.hasMatch(c0)) {
        if (currentGroupId.isEmpty) {
          // Se veio um item antes de qualquer seção, crie um grupo 0
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

        final depth = c0.split('.').length; // 2 => 1.1; 3 => 3.1.10 etc
        final orderKey = _orderKeyFromCode(c0);

        await itemsCol.add({
          'code': c0,
          'depth': depth,
          'index': runningIndex, // para manter a ordem original
          'orderKey': orderKey,  // para ordenações estáveis por código
          'values': row,         // linha completa conforme grade
          'updatedAt': FieldValue.serverTimestamp(),
        });

        runningIndex++;
      }
      // linhas vazias/intermediárias simplesmente são ignoradas
    }
  }

  /// ---------- LOAD (aninhado) ----------
  Future<BudgetSnapshot> loadBudgetNested(String contractId) async {
    final metaRef = _base(contractId).doc('meta');
    final metaSnap = await metaRef.get();
    if (!metaSnap.exists) return BudgetSnapshot.empty();

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

    // pega grupos na ordem
    final groups = await rowsCol.orderBy('order').get();

    // vamos reconstruir a tableData: cabeçalho + seções + itens
    final List<List<String>> table = [];
    if (headers.isNotEmpty) table.add(headers);

    // util para preencher linhas no tamanho do cabeçalho
    List<String> _padRow(List<String> r) {
      if (headers.isEmpty) return r;
      if (r.length >= headers.length) return r.take(headers.length).toList();
      return [...r, for (int i = r.length; i < headers.length; i++) ''];
    }

    for (final g in groups.docs) {
      final gData = g.data();
      final order = (gData['order'] ?? '').toString();
      final title = (gData['title'] ?? '').toString();

      // adiciona a linha de seção (como vinha da planilha)
      if (order.isNotEmpty || title.isNotEmpty) {
        final sectionRow = _padRow([order, title, '', '', '', '']);
        table.add(sectionRow);
      }

      // itens ordenados pelo "index" para manter a ordem original
      final items = await g.reference
          .collection('items')
          .orderBy('index')
          .get();

      for (final it in items.docs) {
        final data = it.data();
        final List<dynamic> values = (data['values'] ?? []) as List<dynamic>;
        final row = _padRow(values.map((e) => (e ?? '').toString()).toList());
        table.add(row);
      }
    }

    return BudgetSnapshot(
      tableData: table,
      colTypes: colTypes,
      colWidths: colWidths,
    );
  }
}
