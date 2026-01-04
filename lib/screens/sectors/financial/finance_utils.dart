import 'dart:math';

import 'package:siged/_blocs/sectors/financial/empenhos/empenho_data.dart';

class TotalsAll {
  final double empenhado;
  final double liquidado;
  final double pago;

  TotalsAll({
    required this.empenhado,
    required this.liquidado,
    required this.pago,
  });
}

enum FinanceTxType { liquidation, payment }

class FinanceTx {
  final String id;
  final String empenhoId;
  final FinanceTxType type;
  final String sliceLabel;
  final DateTime date;
  final double amount;

  FinanceTx({
    required this.id,
    required this.empenhoId,
    required this.type,
    required this.sliceLabel,
    required this.date,
    required this.amount,
  });
}

class AllocationSlice {
  final String label;
  final double amount;
  AllocationSlice({required this.label, required this.amount});

  AllocationSlice copyWith({String? label, double? amount}) =>
      AllocationSlice(label: label ?? this.label, amount: amount ?? this.amount);
}

double toDoubleBr(String s) {
  final cleaned = s.replaceAll('.', '').replaceAll(',', '.').trim();
  return double.tryParse(cleaned) ?? 0.0;
}

double sumTx(List<FinanceTx> txs, String empenhoId, FinanceTxType type) {
  return txs
      .where((t) => t.empenhoId == empenhoId && t.type == type)
      .fold<double>(0.0, (a, b) => a + b.amount);
}

double sumTxBySlice(List<FinanceTx> txs, String empenhoId, FinanceTxType type, String sliceLabel) {
  return txs
      .where((t) => t.empenhoId == empenhoId && t.type == type && t.sliceLabel == sliceLabel)
      .fold<double>(0.0, (a, b) => a + b.amount);
}

TotalsAll computeTotalsAll(List<EmpenhoData> empenhos, List<FinanceTx> txs) {
  final empenhado = empenhos.fold<double>(0.0, (a, b) => a + b.empenhadoTotal);
  final liquidado = txs.where((t) => t.type == FinanceTxType.liquidation).fold<double>(0.0, (a, b) => a + b.amount);
  final pago = txs.where((t) => t.type == FinanceTxType.payment).fold<double>(0.0, (a, b) => a + b.amount);

  return TotalsAll(empenhado: empenhado, liquidado: liquidado, pago: pago);
}

double clampMin0(double v) => max<double>(0.0, v);
