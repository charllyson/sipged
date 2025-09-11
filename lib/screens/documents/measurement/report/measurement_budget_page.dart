import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_button_circle.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/budget/budget_store.dart';

import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:siged/_widgets/table/magic/magic_table_changed.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

class MeasurementBudgetPage extends StatefulWidget {
  const MeasurementBudgetPage({super.key, required this.contractData});
  final ContractData contractData;

  @override
  State<MeasurementBudgetPage> createState() => _MeasurementBudgetPageState();
}

class _MeasurementBudgetPageState extends State<MeasurementBudgetPage> {
  bool _saving = false;

  List<String> _excelHeaders(int count) {
    String name(int idx) {
      int n = idx; String s = '';
      while (n >= 0) { s = String.fromCharCode((n % 26) + 65) + s; n = (n ~/ 26) - 1; }
      return s;
    }
    return List<String>.generate(count, name);
  }

  bool _isHeaderEmpty(List<String> header) =>
      header.isEmpty || header.every((c) => c.trim().isEmpty);

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
              // Conteúdo principal com rodapé de botões
              Positioned.fill(
                child: Column(
                  children: [
                    const UpBar(
                      leading: Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: BackButtonCircle(),
                      ),
                    ),
                    Expanded(
                      child: MagicTableChanged(
                        selectAllOnEdit: false,
                        controller: ctrl,
                        onInit: (c) async {
                          await _load(store, c, contractId);

                          // -------- metas das 8 colunas (duas calculadas/lock) --------
                          double _numAt(bc.MagicTableController ctrl, int col, int row) {
                            if (row >= ctrl.tableData.length || col < 0 || col >= ctrl.colCount) return 0.0;
                            final v = ctrl.tableData[row].length > col ? ctrl.tableData[row][col] : '';
                            return ctrl.parseBR(v) ?? 0.0; // método público
                          }

                          int _colByHeader(String title) => c.headers.indexWhere(
                                (h) => h.trim().toLowerCase() == title.trim().toLowerCase(),
                          );

                          // índices das colunas base existentes
                          final idxUnitarioUN = _colByHeader('Unitário (UN)'); // base para saldo

                          // chaves das colunas novas:
                          const kPrev   = 'qtd_prev_acum';
                          const kPer    = 'qtd_periodo';
                          const kAtual  = 'qtd_acum_atual';
                          const kSaldo  = 'qtd_saldo';

                          final metas = <bc.ColumnMeta>[
                            // UN (duas editáveis, duas derivadas)
                            const bc.ColumnMeta(
                              key: kPrev,
                              title: 'Acumulado Anterior (UN)',
                              type: bc.ColumnType.number,
                              editable: true,
                            ),
                            const bc.ColumnMeta(
                              key: kPer,
                              title: 'Medido no Período (UN)',
                              type: bc.ColumnType.number,
                              editable: true,
                            ),
                            bc.ColumnMeta(
                              key: kAtual,
                              title: 'Acumulado Atual (UN)',
                              type: bc.ColumnType.number,
                              editable: false,
                              compute: (row, rowValues, ctrl) {
                                final cPrev = ctrl.colIndexByKey(kPrev);
                                final cPer  = ctrl.colIndexByKey(kPer);
                                // Acumulado Atual (UN) = Anterior + Período
                                final v = _numAt(ctrl, cPrev, row) + _numAt(ctrl, cPer, row);
                                return ctrl.formatNumberBR(v, decimals: 2, trimZeros: true);
                              },
                            ),
                            bc.ColumnMeta(
                              key: kSaldo,
                              title: 'Saldo do contrato (UN)',
                              type: bc.ColumnType.number,
                              editable: false,
                              compute: (row, rowValues, ctrl) {
                                final cPrev = ctrl.colIndexByKey(kPrev);
                                final cPer  = ctrl.colIndexByKey(kPer);
                                // Saldo (UN) = Unitário(UN) - Anterior(UN) - Período(UN)
                                final base = _colByHeader('Unitário (UN)') >= 0
                                    ? _numAt(ctrl, idxUnitarioUN, row)
                                    : 0.0;
                                final v = base - _numAt(ctrl, cPrev, row) - _numAt(ctrl, cPer, row);
                                return ctrl.formatNumberBR(v, decimals: 2, trimZeros: true);
                              },
                            ),

                            // R$ (editáveis por enquanto)
                            const bc.ColumnMeta(
                              key: 'val_prev_acum',
                              title: 'Acumulado Anterior (R\$)',
                              type: bc.ColumnType.money,
                            ),
                            const bc.ColumnMeta(
                              key: 'val_periodo',
                              title: 'Medido no Período (R\$)',
                              type: bc.ColumnType.money,
                            ),
                            const bc.ColumnMeta(
                              key: 'val_acum_atual',
                              title: 'Acumulado Atual (R\$)',
                              type: bc.ColumnType.money,
                            ),
                            const bc.ColumnMeta(
                              key: 'val_saldo',
                              title: 'Saldo do contrato (R\$)',
                              type: bc.ColumnType.money,
                            ),
                          ];

                          if (!c.hasData || c.headers.isEmpty || c.headers.every((h) => h.trim().isEmpty)) {
                            // Sem dados: cria tabela somente com essas colunas (sem criar linha)
                            c.setSchema(schema: metas, setHeaderFromSchema: true);
                          } else {
                            // Já há dados: acrescenta ao lado (sem criar linha) e ativa schema
                            final alreadyHas = c.headers.any((h) => h.trim() == metas.first.title);
                            if (!alreadyHas) {
                              c.appendColumns(metas); // ativa schema automaticamente se não houver
                            }
                          }

                          // Ajuste de largura
                          for (var i = 0; i < c.colCount; i++) {
                            c.colWidths[i] = c.autoFitColWidth(i);
                          }
                          c.notifyListeners();
                        },
                        bottomScrollGap: 90,
                        rightScrollGap: 50,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 42), // 👈 controla altura
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.blue),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Salvar medição', style: TextStyle(color: Colors.white)),
                        onPressed: isBusy
                            ? null
                            : () async {
                          if (!ctrl.hasData) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                              headers: ctrl.headers,
                              colTypes: ctrl.colTypesAsString,
                              colWidths: ctrl.colWidths,
                              rows: ctrl.tableData,
                              rowsIncludesHeader: true,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Orçamento salvo com sucesso!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Falha ao salvar: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Rodapé fixo do app
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
