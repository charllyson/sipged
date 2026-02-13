import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:sipged/_widgets/table/simple/simple_table_changed.dart';

class BudgetTableSection extends StatelessWidget {
  final List<BudgetData> items;
  final BudgetData? selected;
  final NumberFormat currency;

  final void Function(BudgetData e) onSelect;
  final Future<void> Function(BudgetData e)? onDelete;

  const BudgetTableSection({
    super.key,
    required this.items,
    required this.selected,
    required this.currency,
    required this.onSelect,
    this.onDelete,
  });

  String _s(String? v) => (v ?? '').trim();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SimpleTableChanged<BudgetData>(
          constraints: constraints,
          listData: items,
          selectedItem: selected,
          onTapItem: onSelect,

          // ✅ quando não é null, SimpleTableChanged cria a coluna "APAGAR"
          onDelete: onDelete == null ? null : (e) => onDelete!(e),

          columnTitles: const [
            'EXERCÍCIO',
            'CONTRATANTE',
            'FONTE',
            'CÓDIGO',
            'DESCRIÇÃO',
            'VALOR',
          ],
          columnGetters: [
                (e) => e.year.toString(),
                (e) => _s(e.companyLabel),
                (e) => _s(e.fundingSourceLabel),
                (e) => _s(e.budgetCode),
                (e) => _s(e.description),
                (e) => currency.format(e.amount),
          ],

          // ✅ IMPORTANTE: agora precisa ter +1 largura por causa da coluna APAGAR
          // (6 colunas + 1 delete = 7)
          columnWidths: const [110, 260, 220, 160, 420, 140, 56],

          // ✅ alinha as 6 colunas de dados; a coluna APAGAR é tratada internamente
          columnTextAligns: const [
            TextAlign.center, // exercício
            TextAlign.center,   // contratante
            TextAlign.center, // fonte
            TextAlign.center, // código
            TextAlign.left,   // descrição
            TextAlign.right,  // valor
          ],
        );
      },
    );
  }
}
