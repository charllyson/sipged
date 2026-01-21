import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:siged/_blocs/modules/financial/empenhos/empenho_data.dart';

import 'package:siged/_widgets/cards/basic/basic_card.dart';

import 'summary_section.dart';
import 'extract_timeline.dart';
import 'slices_progress_card.dart';
import 'empenho_slices_row.dart';
import 'budget_slices_row.dart';

class FinancialDashboardPage extends StatelessWidget {
  final NumberFormat currency;
  final ThemeData theme;

  final List<BudgetData> budgets;
  final List<EmpenhoData> empenhos;

  final String? selectedEmpenhoId;
  final EmpenhoData? selectedEmpenho;
  final void Function(String? id) onSelectEmpenho;

  // totals já calculados no cubit
  final double totalOrcamento;
  final double totalEmpenhado;
  final double totalMedido;
  final double totalPago;
  final double totalSaldo;

  const FinancialDashboardPage({
    super.key,
    required this.currency,
    required this.theme,
    required this.budgets,
    required this.empenhos,
    required this.selectedEmpenhoId,
    required this.selectedEmpenho,
    required this.onSelectEmpenho,
    required this.totalOrcamento,
    required this.totalEmpenhado,
    required this.totalMedido,
    required this.totalPago,
    required this.totalSaldo,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedEmpenho;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SummarySection(
          totalsOrcamento: totalOrcamento,
          totalsEmpenhado: totalEmpenhado,
          totalsLiquidado: totalMedido,
          totalsPago: totalPago,
          totalsSaldo: max<double>(0.0, totalSaldo),
          theme: theme,
        ),
        const SizedBox(height: 16),

        if (empenhos.isEmpty)
          BasicCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Cadastre um empenho para visualizar os gráficos.",
                style: theme.textTheme.bodyLarge,
              ),
            ),
          )
        else ...[
          // ============================
          // ORÇAMENTO (por fonte)
          // ============================
          BudgetSlicesRow(
            currency: currency,
            budgets: budgets,
          ),
          const SizedBox(height: 12),

          // ============================
          // EMPENHOS (por DEMANDA, fatias = FONTE)
          // ============================
          EmpenhoSlicesRow(
            currency: currency,
            budgets: budgets,
            empenhos: empenhos,
          ),
          const SizedBox(height: 12),

          // ============================
          // PROGRESSO (mantém no "selected" – se existir)
          // ============================
          if (selected != null) ...[
            SlicesProgressCard(
              currency: currency,
              theme: theme,
              empenho: selected,
            ),
            const SizedBox(height: 12),
          ],

          // ============================
          // EXTRATO / TIMELINE (orçamento + empenhos)
          // ============================
          ExtractTimeline(
            currency: currency,
            theme: theme,
            budgets: budgets,
            empenhos: empenhos,
          ),
        ],
      ],
    );
  }
}
