// lib/screens/_pages/physical_financial/widgets/table/percent_cell.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'percent_bar.dart';

class PhysFinPercentCell extends StatelessWidget {//
  final String serviceKey;
  final int colIndex;
  final double serviceTotalReais;
  final List<double> rowPercents; // lista de % da linha (para somar os outros)
  final double barWidth;
  final NumberFormat money;

  /// Se true, célula não é editável (barra cinza, sem clique)
  final bool readOnly;

  /// Chamado ao tocar para editar (passa alreadyAllocated para o caller abrir o diálogo)
  final Future<void> Function(double alreadyAllocatedPercent)? onChanged;

  /// Cores (ativas e inativas)
  final Color activeBarColor;
  final Color inactiveBarColor;
  final Color trackColor;

  const PhysFinPercentCell({
    super.key,
    required this.serviceKey,
    required this.colIndex,
    required this.serviceTotalReais,
    required this.rowPercents,
    required this.barWidth,
    required this.money,
    this.readOnly = false,
    this.onChanged,
    this.activeBarColor = const Color(0xFF1E88E5),   // azul (aprox. Colors.blue[600])
    this.inactiveBarColor = const Color(0xFF9E9E9E), // cinza (Colors.grey[600])
    this.trackColor = const Color(0xFFE0E0E0),       // trilho (Colors.grey[300])
  });

  @override
  Widget build(BuildContext context) {
    final double p = (colIndex < rowPercents.length) ? rowPercents[colIndex] : 0.0;
    final double valorPeriodo = serviceTotalReais * (p / 100.0);

    Future<void> handleTap() async {
      if (readOnly || onChanged == null) return;
      // soma dos outros períodos
      final alreadyAllocated = rowPercents.asMap().entries
          .where((e) => e.key != colIndex)
          .fold<double>(0.0, (s, e) => s + (e.value));
      await onChanged!(alreadyAllocated);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhysFinPercentBar(
          percent: p,
          width: barWidth,
          height: 24,
          onTap: readOnly ? null : handleTap,
          fillColor: readOnly ? inactiveBarColor : activeBarColor,
          trackColor: trackColor,
          disabled: readOnly,
        ),
        const SizedBox(height: 8),
        Text(
          money.format(valorPeriodo),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.clip,
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }
}
