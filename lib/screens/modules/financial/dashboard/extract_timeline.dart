import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_data.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class ExtractTimeline extends StatelessWidget {
  final NumberFormat currency;
  final ThemeData theme;

  final List<BudgetData> budgets;
  final List<EmpenhoData> empenhos;

  const ExtractTimeline({
    super.key,
    required this.currency,
    required this.theme,
    required this.budgets,
    required this.empenhos,
  });

  DateTime _budgetSortDate(BudgetData b) {
    return b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final budgetEvents = budgets
        .map((b) => _TimelineItem(
      kind: _TimelineKind.budget,
      date: _budgetSortDate(b),
      title: "Orçamento",
      subtitle: (b.fundingSourceLabel ?? '').trim().isEmpty
          ? (b.description ?? 'Sem descrição')
          : b.fundingSourceLabel!.trim(),
      amount: b.amount,
    ))
        .toList();

    final empenhoEvents = empenhos
        .map((e) => _TimelineItem(
      kind: _TimelineKind.empenho,
      date: e.date,
      title: "Empenho",
      subtitle: "${e.numero} • ${e.demandLabel}",
      amount: e.empenhadoTotal,
    ))
        .toList();

    final all = <_TimelineItem>[...budgetEvents, ...empenhoEvents]
      ..sort((a, b) => b.date.compareTo(a.date));

    return BasicCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Últimos movimentos",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (all.isEmpty)
              const Text("Nenhum orçamento/empenho registrado.")
            else
              ...all.take(10).map((t) {
                final isBudget = t.kind == _TimelineKind.budget;
                final icon = isBudget ? Icons.monetization_on_outlined : Icons.assignment_turned_in;
                final bg = isBudget ? Colors.green.shade50 : Colors.blue.shade50;
                final fg = isBudget ? Colors.green.shade800 : Colors.blue.shade800;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: bg,
                    child: Icon(icon, color: fg),
                  ),
                  title: Text("${t.title} • ${t.subtitle}", maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(DateFormat("dd/MM/yyyy").format(t.date)),
                  trailing: Text(
                    currency.format(t.amount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

enum _TimelineKind { budget, empenho }

class _TimelineItem {
  final _TimelineKind kind;
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;

  _TimelineItem({
    required this.kind,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
  });
}
