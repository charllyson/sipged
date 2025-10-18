import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/process/validity/validity_store.dart';
import 'package:siged/_blocs/process/validity/validity_data.dart';
import 'package:siged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';

class CurvaSPvSeries {
  final String id;
  final String name;

  /// Valores planejados na sequência das datas abaixo.
  final List<double> values;

  /// Datas absolutas desta série (mesmo length de `values` desejável).
  final List<DateTime> dates;

  final Color? color;
  final bool showArea;

  const CurvaSPvSeries({
    required this.id,
    required this.name,
    required this.values,
    required this.dates,
    this.color,
    this.showArea = true,
  });
}

class CurvaSChart extends StatelessWidget {
  final List<ReportMeasurementData> filteredMeasurements;
  final int? selectedIndex;
  final void Function(int index)? onPointTap;

  /// Planejado multi-séries (contratado + termos) — obrigatório agora.
  final List<CurvaSPvSeries> pvMultiSeries;

  /// contrato para buscar a ORDEM DE INÍCIO
  final String contractId;

  const CurvaSChart({
    super.key,
    required this.filteredMeasurements,
    required this.selectedIndex,
    required this.contractId,
    required this.pvMultiSeries,
    this.onPointTap,
  });

  // ===== helpers =====
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _normalize(String s) => s
      .toUpperCase()
      .replaceAll('Í', 'I')
      .replaceAll('Á', 'A')
      .replaceAll('Ã', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Ê', 'E')
      .replaceAll('Ç', 'C');

  DateTime? _getStartDateFromStore(BuildContext context) {
    final store = context.read<ValidityStore>();
    store.ensureFor(contractId);
    final list = store.listFor(contractId);
    final found = list.firstWhere(
          (v) => _normalize(v.ordertype ?? '').contains('INICIO'),
      orElse: () => ValidityData(orderdate: null),
    );
    return found.orderdate;
  }

  List<DateTime> _buildTimelineUnion(Set<DateTime> sources) {
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final map = <String, DateTime>{};
    for (final d in sources) {
      map.putIfAbsent(key(d), () => d);
    }
    final list = map.values.toList()..sort();
    return list;
  }

  List<double> _alignValues({
    required List<DateTime> global,
    required List<DateTime> dates,
    required List<double> values,
  }) {
    final out = List<double>.filled(global.length, double.nan);
    for (int i = 0; i < dates.length && i < values.length; i++) {
      final d = dates[i];
      final gi = global.indexWhere((g) => _sameDay(g, d));
      if (gi != -1) out[gi] = values[i];
    }
    return out;
  }

  /// Garante que `values` tenha o MESMO comprimento de `dates`.
  /// Se `values` for menor, repete o último valor; se estiver vazio, usa 0.
  List<double> _padValuesToDatesLength(List<double> values, int targetLen) {
    if (targetLen <= 0) return const <double>[];
    if (values.isEmpty) return List<double>.filled(targetLen, 0.0);

    final out = List<double>.from(values);
    final last = values.last;
    while (out.length < targetLen) out.add(last);
    if (out.length > targetLen) out.removeRange(targetLen, out.length);
    return out;
  }

  /// Mascara a série para existir apenas entre primeira→última data do termo.
  List<double> _maskOutsideRange({
    required List<double> aligned,
    required List<DateTime> global,
    required List<DateTime> seriesDates,
  }) {
    if (seriesDates.isEmpty) return List<double>.filled(global.length, double.nan);

    final first = seriesDates.first;
    final last  = seriesDates.last;

    final startIdx = global.indexWhere((d) => _sameDay(d, first));
    final endIdx   = global.indexWhere((d) => _sameDay(d, last));

    if (startIdx == -1 || endIdx == -1) {
      return List<double>.filled(global.length, double.nan);
    }

    final out = List<double>.from(aligned);
    for (var i = 0; i < out.length; i++) {
      if (i < startIdx || i > endIdx) out[i] = double.nan;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _getStartDateFromStore(context);

    // AC (realizado)
    final acWithDate  = filteredMeasurements.where((m) => m.date != null).toList();
    final acValuesRaw = acWithDate.map((m) => m.value ?? 0.0).toList();
    final acDatesRaw  = acWithDate.map((m) => m.date!).toList();

    // Datas por série (já vêm prontas em pvMultiSeries)
    final pvDatesPerSeries = <String, List<DateTime>>{
      for (final s in pvMultiSeries)
        s.id: (List<DateTime>.from(s.dates)..sort())
    };

    // Timeline global (AC + início + todos PVs)
    final union = <DateTime>{...acDatesRaw};
    if (startDate != null) union.add(startDate);
    for (final ds in pvDatesPerSeries.values) {
      union.addAll(ds);
    }
    final globalTimeline = _buildTimelineUnion(union);

    // AC alinhado
    final acValues = _alignValues(global: globalTimeline, dates: acDatesRaw, values: acValuesRaw);

    // Ordena PVs por primeira data
    final orderedPv = List<CurvaSPvSeries>.from(pvMultiSeries)
      ..sort((a, b) {
        final da = pvDatesPerSeries[a.id]!.firstOrNull;
        final db = pvDatesPerSeries[b.id]!.firstOrNull;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    // Constrói séries para o LineChartChanged
    const acColor = Color(0xFFFB8323);
    const startDotColor = Color(0xFFE53935);

    final series = <LineSeries>[
      for (final s in orderedPv) () {
        final dates = pvDatesPerSeries[s.id] ?? const <DateTime>[];
        final padded = _padValuesToDatesLength(s.values, dates.length);
        final aligned = _alignValues(global: globalTimeline, dates: dates, values: padded);
        final masked  = _maskOutsideRange(global: globalTimeline, aligned: aligned, seriesDates: dates);
        return LineSeries(
          id: s.id,
          name: s.name,
          values: masked,
          dateLabels: globalTimeline,
          color: s.color,
          showArea: s.showArea,
          curved: true,
        );
      }(),

      // AC
      LineSeries(
        id: 'AC',
        name: 'Realizado',
        values: acValues,
        dateLabels: globalTimeline,
        color: acColor,
        showArea: true,
        curved: true,
      ),
    ];

    // marcador do início
    int? startX;
    if (startDate != null) {
      startX = globalTimeline.indexWhere((d) => _sameDay(d, startDate));
      if (startX != -1) {
        final marker = List<double>.filled(globalTimeline.length, double.nan);
        marker[startX] = 0.0;
        series.add(
          LineSeries(
            id: 'INICIO_OBRA',
            name: 'Início da obra',
            values: marker,
            dateLabels: globalTimeline,
            color: startDotColor,
            showArea: false,
            strokeWidth: 0.0,
            curved: false,
            dotRadius: 7,
            selectedDotRadius: 9,
          ),
        );
      } else {
        startX = null;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        child: LineChartChanged(
          alturaGrafico: 300,
          dateLabels: globalTimeline,
          labels: const <String>[], // legado do componente, ignorado
          values: const <double>[],
          series: series,
          verticalLinesAt: (startX == null) ? null : <int>[startX],
          selectedIndex: selectedIndex,
          onPointTap: (index) => onPointTap?.call(index),
          tooltipFormatter: (v) => priceToString(v),
          showLegend: true,
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
