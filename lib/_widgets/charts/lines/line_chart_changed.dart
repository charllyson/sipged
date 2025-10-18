import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siged/_widgets/charts/lines/shimmer_line_chart.dart';
import 'package:siged/_utils/formats/format_field.dart';

class LineSeries {
  final String id;
  final String? name;
  final List<double> values;
  final List<String>? labels;       // compat
  final List<DateTime>? dateLabels; // datas por ponto
  final Color? color;
  final bool showArea;
  final double strokeWidth;
  final bool curved;
  final double dotRadius;
  final double selectedDotRadius;

  const LineSeries({
    required this.id,
    required this.values,
    this.name,
    this.labels,
    this.dateLabels,
    this.color,
    this.showArea = true,
    this.strokeWidth = 3,
    this.curved = true,
    this.dotRadius = 3.5,
    this.selectedDotRadius = 6,
  });

  LineSeries orderedCopy(List<int> order) {
    List<T> _apply<T>(List<T> src) => [
      for (final i in order)
        if (i >= 0 && i < src.length) src[i]
    ];
    return LineSeries(
      id: id,
      name: name,
      values: _apply<double>(values),
      labels: labels == null ? null : _apply<String>(labels!),
      dateLabels: dateLabels == null ? null : _apply<DateTime>(dateLabels!),
      color: color,
      showArea: showArea,
      strokeWidth: strokeWidth,
      curved: curved,
      dotRadius: dotRadius,
      selectedDotRadius: selectedDotRadius,
    );
  }
}

class LineChartChanged extends StatefulWidget {
  final List<String> labels;          // compat
  final List<DateTime>? dateLabels;   // eixo X global (preferência)
  final List<double> values;          // compat (1 série)
  final List<LineSeries>? series;

  final int? selectedIndex;
  final void Function(int index)? onPointTap;
  final void Function(String seriesId, int index)? onPointTapSeries;

  final double? larguraGrafico;
  final double? alturaGrafico;

  final String Function(double value)? tooltipFormatter;
  final String? prefix;

  final bool showLegend;

  final List<int>? verticalLinesAt; // marcos

  const LineChartChanged({
    super.key,
    required this.labels,
    required this.values,
    this.series,
    this.dateLabels,
    this.selectedIndex,
    this.onPointTap,
    this.onPointTapSeries,
    this.larguraGrafico,
    this.alturaGrafico = 240,
    this.tooltipFormatter,
    this.prefix,
    this.showLegend = true,
    this.verticalLinesAt,
  });

  @override
  State<LineChartChanged> createState() => _LineChartChangedState();
}

class _LineChartChangedState extends State<LineChartChanged> {
  static const _palette = <Color>[
    Color(0xFFFB8323), Color(0xFF206AF5), Color(0xFF00A86B),
    Color(0xFF8E44AD), Color(0xFFE74C3C), Color(0xFF2C3E50),
    Color(0xFFF1C40F),
  ];
  static const Color _startDotColor = Color(0xFFE53935); // legenda fixa
  static const double _leftTitlesReserved = 56.0;
  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  bool get _usandoSeries => (widget.series != null && widget.series!.isNotEmpty);

  List<int> _orderByDates(List<DateTime> dates) {
    final idx = List<int>.generate(dates.length, (i) => i);
    idx.sort((a, b) => dates[a].compareTo(dates[b]));
    return idx;
  }

  List<T> _applyOrder<T>(List<T> src, List<int> order) => [
    for (final i in order)
      if (i >= 0 && i < src.length) src[i]
  ];

  late final List<int>? _globalOrder = () {
    final ds = widget.dateLabels;
    if (ds != null && ds.isNotEmpty) return _orderByDates(ds);
    return null;
  }();

  List<DateTime>? get _globalDatesEffective {
    final ds = widget.dateLabels;
    if (ds == null || ds.isEmpty) return null;
    if (_globalOrder == null) {
      final copy = [...ds]..sort();
      return copy;
    }
    return _applyOrder<DateTime>(ds, _globalOrder!);
  }

  List<String> get _globalLabelsResolved {
    final g = _globalDatesEffective;
    if (g != null) return g.map(_dateFmt.format).toList();
    return widget.labels;
  }

  List<double> get _legacyValuesEffective {
    if (_globalOrder != null) return _applyOrder<double>(widget.values, _globalOrder!);
    return widget.values;
  }

  List<LineSeries> get _seriesEffective {
    if (!_usandoSeries) return const <LineSeries>[];
    final list = <LineSeries>[];
    for (var s in widget.series!) {
      if (_globalOrder != null) s = s.orderedCopy(_globalOrder!);
      if (s.dateLabels != null && s.dateLabels!.isNotEmpty) {
        final localOrder = _orderByDates(s.dateLabels!);
        s = s.orderedCopy(localOrder);
      }
      list.add(s);
    }
    return list;
  }

  bool get _hasAnyDateLabels {
    if (widget.dateLabels != null && widget.dateLabels!.isNotEmpty) return true;
    if (_usandoSeries) {
      return _seriesEffective.any((s) => (s.dateLabels?.isNotEmpty ?? false));
    }
    return false;
  }

  DateTime? _dateAtIndex(int i) {
    final g = _globalDatesEffective;
    if (g != null && i >= 0 && i < g.length) return g[i];
    if (_usandoSeries) {
      for (final s in _seriesEffective) {
        final ds = s.dateLabels;
        if (ds != null && i >= 0 && i < ds.length) return ds[i];
      }
    }
    return null;
  }

  int _effectiveCount() {
    final globalCount = _globalLabelsResolved.length;
    if (_usandoSeries) {
      final maxSeriesLen = _seriesEffective.map((s) => s.values.length).fold<int>(0, (a, b) => a > b ? a : b);
      return math.max(globalCount, maxSeriesLen);
    } else {
      return math.max(globalCount, _legacyValuesEffective.length);
    }
  }

  bool get _semDados {
    if (_usandoSeries) {
      final s = _seriesEffective;
      return !s.any((e) => e.values.isNotEmpty && e.values.any((v) => v.isFinite));
    } else {
      final vals = _legacyValuesEffective;
      if (vals.isEmpty) return true;
      if (vals.every((v) => !v.isFinite)) return true;
      return false;
    }
  }

  double _bottomReservedSize() {
    if (_hasAnyDateLabels) return 28.0; // só 1 linha
    final hasGlobal = _globalLabelsResolved.isNotEmpty;
    int seriesWithAnyLabel = 0;
    if (_usandoSeries) {
      for (final s in _seriesEffective) {
        if ((s.labels?.isNotEmpty ?? false)) seriesWithAnyLabel++;
      }
    }
    final lines = (hasGlobal ? 1 : 0) + seriesWithAnyLabel;
    if (lines == 0) return 28;
    return 10 + (16.0 * lines);
  }

  double _calcLarguraDinamica(BuildContext context) {
    final larguraMinima = widget.larguraGrafico ?? MediaQuery.of(context).size.width;
    final pointsCount = _effectiveCount();
    final larguraPontos = pointsCount * 50.0;
    return math.max(larguraPontos, larguraMinima);
  }

  List<LineChartBarData> _buildBars() {
    if (!_usandoSeries) {
      final color = const Color(0xFFFB8323);
      final vals = _legacyValuesEffective;
      final spots = <FlSpot>[];
      for (var i = 0; i < vals.length; i++) {
        final v = vals[i];
        if (v.isFinite) spots.add(FlSpot(i.toDouble(), v));
      }
      return [
        LineChartBarData(
          isCurved: true,
          spots: spots,
          barWidth: 4,
          isStrokeCapRound: true,
          gradient: LinearGradient(colors: [color, color]),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.5), color.withOpacity(0.3)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, idx) {
              final isSelected = idx == widget.selectedIndex;
              return FlDotCirclePainter(
                radius: isSelected ? 7 : 4,
                color: isSelected ? Colors.blue : Colors.white,
                strokeWidth: isSelected ? 0 : 2,
                strokeColor: color,
              );
            },
          ),
        ),
      ];
    }

    final bars = <LineChartBarData>[];
    final eff = _seriesEffective;

    for (var i = 0; i < eff.length; i++) {
      final s = eff[i];
      final color = s.color ?? _palette[i % _palette.length];

      final pts = <FlSpot>[];
      for (var j = 0; j < s.values.length; j++) {
        final v = s.values[j];
        if (v.isFinite) pts.add(FlSpot(j.toDouble(), v));
      }

      bars.add(
        LineChartBarData(
          isCurved: s.curved,
          spots: pts,
          barWidth: s.strokeWidth,
          isStrokeCapRound: true,
          color: color,
          belowBarData: BarAreaData(
            show: s.showArea,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.35), color.withOpacity(0.15)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, idx) {
              final isSelected = idx == widget.selectedIndex;
              final isStart = s.id == 'INICIO_OBRA';
              return FlDotCirclePainter(
                radius: isSelected ? s.selectedDotRadius : s.dotRadius,
                // 🔴 “Início da obra” preenchido vermelho na base
                color: isStart ? (s.color ?? _startDotColor) : (isSelected ? Colors.blue : Colors.white),
                strokeWidth: isStart ? 2 : (isSelected ? 0 : 2),
                strokeColor: isStart ? Colors.white : color,
              );
            },
          ),
        ),
      );
    }
    return bars;
  }

  List<LineTooltipItem> _buildTooltipItems(LineTouchTooltipData _, List<LineBarSpot> spots) {
    final items = <LineTooltipItem>[];
    final eff = _seriesEffective;
    for (final lbs in spots) {
      final seriesIndex = lbs.barIndex;
      final y = lbs.y;
      String name = '';
      if (_usandoSeries) {
        final s = eff[seriesIndex];
        name = s.name ?? s.id;
      }
      final text = widget.tooltipFormatter?.call(y) ?? priceToString(y);
      final label = name.isEmpty ? text : '$name: $text';
      items.add(LineTooltipItem(
        label,
        const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
          shadows: [Shadow(blurRadius: 1, color: Colors.black54, offset: Offset(0, 1))],
        ),
      ));
    }
    return items;
  }

  Widget _buildBottomTitle(int i) {
    if (_hasAnyDateLabels) {
      final dt = _dateAtIndex(i);
      if (dt == null) return const SizedBox.shrink();
      return Text(
        _dateFmt.format(dt),
        style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      );
    }
    final children = <Widget>[];
    final globals = _globalLabelsResolved;
    if (i >= 0 && i < globals.length) {
      children.add(Text(
        '${widget.prefix ?? ''}${globals[i]}',
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ));
    }
    if (_usandoSeries) {
      for (var sIdx = 0; sIdx < _seriesEffective.length; sIdx++) {
        final s = _seriesEffective[sIdx];
        if (i < s.values.length && s.labels != null && i < s.labels!.length) {
          final color = s.color ?? _palette[sIdx % _palette.length];
          final txt = s.labels![i];
          if (txt.isNotEmpty) {
            children.add(Text(
              txt,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ));
          }
        }
      }
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _noData() {
    final count = math.max(_effectiveCount(), 12);
    final globals = _globalLabelsResolved;
    final title = globals.isNotEmpty ? globals.first : null;
    return LineChartShimmerWidget(
      pointsCount: count,
      height: widget.alturaGrafico ?? 240,
      chartTitle: title,
    );
  }

  bool get _hasStartMarker {
    if (!_usandoSeries) return false;
    return _seriesEffective.any((s) => s.id == 'INICIO_OBRA');
  }

  @override
  Widget build(BuildContext context) {
    if (_semDados) return _noData();

    final larguraDinamica = _calcLarguraDinamica(context);
    final bars = _buildBars();
    final effectiveCount = _effectiveCount();

    // ---- legenda: "Início da obra" primeiro ----
    final legendWidgets = <Widget>[];
    if (_usandoSeries && widget.showLegend) {
      if (_hasStartMarker || (widget.verticalLinesAt != null && widget.verticalLinesAt!.isNotEmpty)) {
        legendWidgets.add(const _LegendDot(color: _startDotColor, label: 'Início da obra'));
      }
      for (var i = 0; i < _seriesEffective.length; i++) {
        final s = _seriesEffective[i];
        if (s.id == 'INICIO_OBRA') continue; // já adicionamos
        legendWidgets.add(
          _LegendDot(
            color: s.color ?? _palette[i % _palette.length],
            label: s.name ?? s.id,
          ),
        );
      }
    }

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 18.0, bottom: 12.0, top: 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: larguraDinamica,
            height: (widget.alturaGrafico ?? 240) + _bottomReservedSize(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (legendWidgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
                    child: Wrap(spacing: 12, runSpacing: 4, children: legendWidgets),
                  ),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touched) => _buildTooltipItems(LineTouchTooltipData(), touched),
                        ),
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent &&
                              response?.lineBarSpots != null &&
                              response!.lineBarSpots!.isNotEmpty) {
                            final spot = response.lineBarSpots!.first;
                            final idx = spot.spotIndex;
                            if (_usandoSeries && widget.onPointTapSeries != null) {
                              final s = _seriesEffective[spot.barIndex];
                              widget.onPointTapSeries!.call(s.id, idx);
                            }
                            widget.onPointTap?.call(idx);
                          }
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _bottomReservedSize(),
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i > math.max(effectiveCount - 1, 0)) {
                                return const SizedBox.shrink();
                              }
                              return _buildBottomTitle(i);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _leftTitlesReserved,
                            getTitlesWidget: (value, meta) {
                              if (value % 1000000 != 0) return const SizedBox.shrink();
                              final mi = value ~/ 1000000;
                              return Text('$mi M', style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      extraLinesData: ExtraLinesData(
                        verticalLines: (widget.verticalLinesAt ?? const <int>[])
                            .map((x) => VerticalLine(
                          x: x.toDouble(),
                          strokeWidth: 1.5,
                          color: const Color(0xFF9E9E9E),
                          dashArray: [4, 4],
                        ))
                            .toList(),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: const FlGridData(show: true),
                      lineBarsData: bars,
                      minX: 0,
                      maxX: (math.max(effectiveCount - 1, 0)).toDouble(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
