// lib/screens/_pages/physical_financial/physfin_models.dart
import 'package:flutter/material.dart';

class PhysFinRow {
  final String key;          // serviceKey
  final int item;            // 1..N
  final String descricao;    // label
  final double valor;        // total do serviço em R$
  final List<double> percent; // percentuais por período

  PhysFinRow({
    required this.key,
    required this.item,
    required this.descricao,
    required this.valor,
    required this.percent,
  });
}

class PhysFinTotals {
  final List<double> parciais;   // por período (R$)
  final List<double> acumulados; // por período (R$)
  final double totalGeral;       // soma dos serviços

  PhysFinTotals({
    required this.parciais,
    required this.acumulados,
    required this.totalGeral,
  });
}

class PhysFinWidths {
  final double itemCol;
  final double descCol;
  final double? extraCol;   // ⬅️ opcional
  final double percentCol;
  final double valueCol;
  final double barVisual;

  const PhysFinWidths({
    required this.itemCol,
    required this.descCol,
    this.extraCol,
    required this.percentCol,
    required this.valueCol,
    required this.barVisual,
  });
}

class PhysFinMeasured {
  final double descColWidth;
  final double valueColWidth;
  const PhysFinMeasured({required this.descColWidth, required this.valueColWidth});
}

/// Configuração da coluna extra (aparece à direita da DESCRIÇÃO)
class PhysFinExtraColumn {
  final String header;
  final double width;
  final Widget Function(BuildContext context, PhysFinRow row) cellBuilder;

  const PhysFinExtraColumn({
    required this.header,
    required this.width,
    required this.cellBuilder,
  });
}
