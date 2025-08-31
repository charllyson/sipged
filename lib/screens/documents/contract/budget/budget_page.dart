import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/budget/budget_store.dart';

import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:siged/_widgets/table/magic/magic_table_changed.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, required this.contractData});
  final ContractData contractData;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool _saving = false;

  // --------- helpers ---------
  List<String> _excelHeaders(int count) {
    String name(int idx) {
      int n = idx;
      String s = '';
      while (n >= 0) {
        s = String.fromCharCode((n % 26) + 65) + s;
        n = (n ~/ 26) - 1;
      }
      return s;
    }
    return List<String>.generate(count, name);
  }

  bool _isHeaderEmpty(List<String> header) =>
      header.isEmpty || header.every((c) => c.trim().isEmpty);

  // --------- load com saneamento ---------
  Future<void> _load(
      BudgetStore store,
      bc.MagicTableController ctrl,
      String id,
      ) async {
    await store.ensureFor(id);
    final snap = store.cacheFor(id);

    if (snap == null || snap.tableData.isEmpty) {
      ctrl.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );
      return;
    }

    final table = snap.tableData
        .map<List<String>>((row) => row.map((e) => e.toString()).toList())
        .toList();

    if (table.isEmpty) {
      ctrl.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );
      return;
    }

    final int colCount = table.first.length;
    if (_isHeaderEmpty(table.first)) {
      table[0] = _excelHeaders(colCount);
    }

    List<String> types = snap.colTypes.map((e) => e.toString()).toList();
    if (types.length != colCount) {
      types = List<String>.generate(colCount, (i) => i < types.length ? types[i] : 'auto');
    }

    List<double> widths = snap.colWidths.map((e) => e.toDouble()).toList();
    if (widths.length != colCount) {
      widths = List<double>.generate(colCount, (i) => i < widths.length ? widths[i] : 120.0);
    }

    ctrl.loadFromSnapshot(
      table: table,
      colTypesAsString: types,
      widths: widths,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractId = widget.contractData.id!;
    return ChangeNotifierProvider<bc.MagicTableController>(
      create: (_) => bc.MagicTableController(
        cellPadHorizontal: const EdgeInsets.symmetric(horizontal: 12).horizontal,
      ),
      builder: (context, _) {
        final ctrl = context.watch<bc.MagicTableController>();
        final store = context.read<BudgetStore>();
        final isLoading = context.select<BudgetStore, bool>(
              (s) => s.loadingFor(contractId),
        );
        final isBusy = isLoading || _saving;

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: BackgroundClean()),

              // Conteúdo principal (sem padding inferior fixo)
              Positioned.fill(
                child: MagicTableChanged(
                  selectAllOnEdit: false,
                  controller: ctrl,
                  onInit: (c) => _load(store, c, contractId),

                  // 👇 vãos que aparecem só no fim da rolagem
                  bottomScrollGap: 90,
                  rightScrollGap: 60,

                  floatingActionsBuilder: (ctx, c) => [
                    FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      heroTag: 'pasteExcel',
                      tooltip: 'Colar do Excel (Ctrl+V)',
                      onPressed: isBusy ? null : () => c.pasteFromClipboard(),
                      child: const Icon(Icons.paste),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      heroTag: 'saveBudget',
                      tooltip: 'Salvar orçamento no Firestore',
                      onPressed: isBusy
                          ? null
                          : () async {
                        if (!c.hasData) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Nada para salvar. Cole dados do Excel primeiro.'),
                            ),
                          );
                          return;
                        }
                        setState(() => _saving = true);
                        try {
                          await store.saveBudget(
                            contractId: contractId,
                            headers: c.headers,
                            colTypes: c.colTypesAsString,
                            colWidths: c.colWidths,
                            rows: c.tableData,
                            rowsIncludesHeader: true,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Orçamento salvo com sucesso!')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Falha ao salvar: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                      child: const Icon(Icons.save),
                    ),
                  ],
                ),
              ),

              // Rodapé fixo
              const Align(
                alignment: Alignment.bottomCenter,
                child: FootBar(),
              ),

              // Overlay de busy (carregando / salvando)
              if (isBusy) ...[
                const ModalBarrier(dismissible: false, color: Colors.black38),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(blurRadius: 10, spreadRadius: 1, color: Colors.black26)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                        const SizedBox(width: 12),
                        Text(
                          _saving ? 'Salvando orçamento...' : 'Carregando orçamento...',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
