import 'dart:math';

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/cards/expandable/expandable_card.dart';
import 'package:sipged/_widgets/layout/responsive_section/responsive_section_row.dart';

class SummarySection extends StatelessWidget {
  final double totalsOrcamento;
  final double totalsEmpenhado;
  final double totalsLiquidado;
  final double totalsPago;
  final double totalsSaldo;

  final ThemeData theme;

  const SummarySection({
    super.key,
    required this.totalsOrcamento,
    required this.totalsEmpenhado,
    required this.totalsLiquidado,
    required this.totalsPago,
    required this.totalsSaldo,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final saldoSafe = max<double>(0.0, totalsSaldo);

    return ResponsiveSectionRow(
      smallBreakpoint: 900,
      sidePadding: 0,
      gap: 12,
      verticalGap: 12,
      children: [
            (context, m, i) => ExpandableCard(
          title: "Orçamento",
          icon: Icons.monetization_on_outlined,
          colorIcon: theme.colorScheme.primary,
          totalOverride: totalsOrcamento,
          loading: false,
          formatAsCurrency: true,
        ),
            (context, m, i) => ExpandableCard(
          title: "Empenhado",
          icon: Icons.assignment_turned_in,
          colorIcon: theme.colorScheme.primary,
          totalOverride: totalsEmpenhado,
          loading: false,
          formatAsCurrency: true,
        ),
            (context, m, i) => ExpandableCard(
          title: "Medido",
          icon: Icons.fact_check,
          colorIcon: theme.colorScheme.primary,
          totalOverride: totalsLiquidado,
          loading: false,
          formatAsCurrency: true,
        ),
            (context, m, i) => ExpandableCard(
          title: "Pago",
          icon: Icons.payments,
          colorIcon: theme.colorScheme.primary,
          totalOverride: totalsPago,
          loading: false,
          formatAsCurrency: true,
        ),
            (context, m, i) => ExpandableCard(
          title: "Saldo",
          icon: Icons.account_balance_wallet,
          colorIcon: theme.colorScheme.primary,
          totalOverride: saldoSafe,
          loading: false,
          formatAsCurrency: true,
        ),
      ],
    );
  }
}
