import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siged/_blocs/modules/financial/empenhos/empenho_data.dart';

import 'package:siged/_widgets/cards/basic/basic_card.dart';

class SlicesProgressCard extends StatelessWidget {
  final NumberFormat currency;
  final ThemeData theme;
  final EmpenhoData empenho;

  const SlicesProgressCard({
    super.key,
    required this.currency,
    required this.theme,
    required this.empenho,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rows = empenho.slices.map((s) {
      final planned = s.amount;
      // ✅ Sem txs, não existe medido/pago. Para não quebrar o card:
      final empenhado = s.amount; // o próprio empenho “executa” a alocação do slice
      final saldo = max<double>(0.0, planned - empenhado);

      return _SliceProgressRow(
        label: s.label,
        planned: planned,
        used: empenhado,
        remaining: saldo,
        currency: currency,
      );
    }).toList();

    return BasicCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Distribuição por demanda (Planejado → Empenhado)",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty) const Text("Nenhuma demanda (fatia) cadastrada."),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _SliceProgressRow extends StatelessWidget {
  final String label;
  final double planned;
  final double used;
  final double remaining;
  final NumberFormat currency;

  const _SliceProgressRow({
    required this.label,
    required this.planned,
    required this.used,
    required this.remaining,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final plannedSafe = max<double>(1.0, planned);
    final usedPct = (used / plannedSafe).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(currency.format(planned), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(height: 14, color: Colors.grey.shade100),
                FractionallySizedBox(
                  widthFactor: usedPct,
                  child: Container(height: 14, color: Colors.blue.shade200),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _chip(context, "Empenhado", currency.format(used), bold: true),
              _chip(context, "Saldo", currency.format(remaining)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String k, String v, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$k: "),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
