import 'dart:math' as math;
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';

class EvmSnapshot {
  final double pv;
  final double ev;
  final double ac;
  final double cpi;
  final double spi;
  final double eac;
  final double etc;

  const EvmSnapshot({
    required this.pv,
    required this.ev,
    required this.ac,
    required this.cpi,
    required this.spi,
    required this.eac,
    required this.etc,
  });
}

class EvmCalculator {
  static Map<int, double> plannedCumulative({
    required double totalContractValue,
    required DateTime start,
    required DateTime end,
    Map<int, double>? monthWeights,
  }) {
    if (totalContractValue <= 0 || !end.isAfter(start)) return {};
    final months = _monthsBetween(start, end);
    if (months.isEmpty) return {};

    final weights = <int, double>{
      for (final ym in months) ym: (monthWeights?[ym] ?? 1.0),
    };
    final sumW = weights.values.fold<double>(0.0, (a, b) => a + b);
    if (sumW <= 0) return {};

    final pvByMonth = <int, double>{};
    double acc = 0.0;
    for (final ym in months) {
      final share = totalContractValue * (weights[ym]! / sumW);
      acc += share;
      pvByMonth[ym] = acc;
    }
    return pvByMonth;
  }

  static double earnedValue({
    required double totalContractValue,
    required double physicalPercent,
  }) {
    final p = physicalPercent.clamp(0.0, 1.0);
    return totalContractValue * p;
  }

  static double actualCostUpTo({
    required List<ReportMeasurementData> measurements,
    DateTime? until,
  }) {
    final u = until ?? DateTime.now();
    return measurements.where((m) {
      final d = m.date;
      return d != null && !d.isAfter(u);
    }).fold<double>(0.0, (a, m) => a + (m.value ?? 0.0));
  }

  static EvmSnapshot snapshot({
    required ContractData contract,
    required List<ReportMeasurementData> measurementsOfThisContract,
    required double totalContractValue,
    required DateTime start,
    required DateTime end,
    required DateTime asOf,
    required double physicalPercent,
    Map<int, double>? monthWeights,
  }) {
    final pvCurve = plannedCumulative(
      totalContractValue: totalContractValue,
      start: start,
      end: end,
      monthWeights: monthWeights,
    );

    final ym = _ym(asOf);
    final pv = _valueAtMonth(pvCurve, ym);
    final ev = earnedValue(
      totalContractValue: totalContractValue,
      physicalPercent: physicalPercent,
    );
    final ac = actualCostUpTo(
      measurements: measurementsOfThisContract,
      until: asOf,
    );

    final cpi = (ac > 0) ? ev / ac : 1.0;
    final spi = (pv > 0) ? ev / pv : 1.0;

    final eac = (cpi > 0 && cpi.isFinite) ? totalContractValue / cpi : totalContractValue;
    final etc = math.max(0.0, eac - ac);

    return EvmSnapshot(pv: pv, ev: ev, ac: ac, cpi: cpi, spi: spi, eac: eac, etc: etc);
  }

  static List<int> _monthsBetween(DateTime a, DateTime b) {
    final start = DateTime(a.year, a.month);
    final end = DateTime(b.year, b.month);
    final out = <int>[];
    var cur = start;
    while (!cur.isAfter(end)) {
      out.add(_ym(cur));
      cur = DateTime(cur.year, cur.month + 1);
    }
    return out;
  }

  static int _ym(DateTime d) => d.year * 100 + d.month;

  static double _valueAtMonth(Map<int, double> curve, int ym) {
    final keys = curve.keys.toList()..sort();
    double v = 0.0;
    for (final k in keys) {
      if (k <= ym) v = curve[k]!;
    }
    return v;
  }
}
