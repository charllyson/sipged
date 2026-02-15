// lib/_widgets/charts/lines/line_chart_changed.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/charts/lines/shimmer_line_chart.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class LineSeries {
  final String id;
  final String? name;
  final List<double> values;
  final List<String>? labels; // compat
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
    List<T> apply<T>(List<T> src) => [
      for (final i in order)
        if (i >= 0 && i < src.length) src[i]
    ];
    return LineSeries(
      id: id,
      name: name,
      values: apply<double>(values),
      labels: labels == null ? null : apply<String>(labels!),
      dateLabels: dateLabels == null ? null : apply<DateTime>(dateLabels!),
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
  // ===== Header opcional (SectionTitle embutido) =====
  final String? headerTitle;
  final String? headerSubtitle;
  final IconData? headerIcon;

  final List<String> labels; // compat
  final List<DateTime>? dateLabels; // eixo X global (preferência)
  final List<double> values; // compat (1 série)
  final List<LineSeries>? series;

  final int? selectedIndex;
  final void Function(int index)? onPointTap;
  final void Function(String seriesId, int index)? onPointTapSeries;

  /// ✅ Largura do gráfico (também usada agora para CONSTRANGER a largura do card,
  /// evitando "unbounded width" em Row dentro de scroll horizontal).
  final double? larguraGrafico;

  /// ✅ Altura TOTAL do card (e não apenas do canvas do chart).
  /// Isso garante que, com/sem header, o card mantenha a mesma altura.
  final double? alturaGrafico;

  final String Function(double value)? tooltipFormatter;
  final String? prefix;

  final bool showLegend;
  final List<int>? verticalLinesAt; // marcos

  /// ✅ Formato do eixo X quando usar dateLabels.
  final DateFormat? axisDateFormat;

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
    this.headerTitle,
    this.headerSubtitle,
    this.headerIcon,
    this.axisDateFormat,
  });

  @override
  State<LineChartChanged> createState() => _LineChartChangedState();
}

class _LineChartChangedState extends State<LineChartChanged> {
  static const _palette = <Color>[
    Color(0xFF6E7BFF),
    Color(0xFFB66DFF),
    Color(0xFF2DD4BF),
    Color(0xFFFFB703),
    Color(0xFFFF4D6D),
    Color(0xFF60A5FA),
    Color(0xFFA3E635),
  ];

  // ✅ padrão laranja
  static const Color _orange1 = Color(0xFFFB8323);
  static const Color _orange2 = Color(0xFFFFA24D);

  static const Color _startDotColor = Color(0xFFE53935);
  static final DateFormat _fallbackDateFmtFull = DateFormat('dd/MM/yyyy');

  DateFormat get _axisDateFmt => widget.axisDateFormat ?? DateFormat('dd/MM');
  bool get _usandoSeries => (widget.series != null && widget.series!.isNotEmpty);

  bool get _showHeader =>
      (widget.headerTitle != null && widget.headerTitle!.trim().isNotEmpty) ||
          (widget.headerSubtitle != null && widget.headerSubtitle!.trim().isNotEmpty) ||
          widget.headerIcon != null;

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
    return _applyOrder<DateTime>(ds, _globalOrder);
  }

  List<double> get _legacyValuesEffective {
    if (_globalOrder != null) return _applyOrder<double>(widget.values, _globalOrder);
    return widget.values;
  }

  List<LineSeries> get _seriesEffective {
    if (!_usandoSeries) return const <LineSeries>[];
    final list = <LineSeries>[];
    for (var s in widget.series!) {
      if (_globalOrder != null) s = s.orderedCopy(_globalOrder);
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
    final globalCount = (_globalDatesEffective?.length ?? 0);
    if (_usandoSeries) {
      final maxSeriesLen = _seriesEffective.map((s) => s.values.length).fold<int>(
        0,
            (a, b) => a > b ? a : b,
      );
      return math.max(globalCount, maxSeriesLen);
    }
    return math.max(globalCount, _legacyValuesEffective.length);
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

  double _calcLarguraDinamica(BuildContext context) {
    final larguraMinima = widget.larguraGrafico ?? MediaQuery.of(context).size.width;
    final pointsCount = _effectiveCount();
    final larguraPontos = pointsCount * 50.0;
    return math.max(larguraPontos, larguraMinima);
  }

  double _maxY() {
    double maxV = 0;
    if (_usandoSeries) {
      for (final s in _seriesEffective) {
        for (final v in s.values) {
          if (v.isFinite) maxV = math.max(maxV, v);
        }
      }
    } else {
      for (final v in _legacyValuesEffective) {
        if (v.isFinite) maxV = math.max(maxV, v);
      }
    }
    return math.max(6.0, maxV + (maxV * 0.08) + 2.0);
  }

  double _safeMinY() => 0;

  double _yInterval(double safeMaxY) {
    if (safeMaxY <= 0) return 1;
    final raw = safeMaxY / 3.0;
    final pow10 = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final n = raw / pow10;
    double step;
    if (n < 1.5) {
      step = 1 * pow10;
    } else if (n < 3.5) {
      step = 2 * pow10;
    } else if (n < 7.5) {
      step = 5 * pow10;
    } else {
      step = 10 * pow10;
    }
    return math.max(1, step);
  }

  String _formatAxisY(double v) {
    final a = v.abs();
    if (a >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)} M';
    }
    if (a >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)} K';
    }
    return v.toInt().toString();
  }

  String _fixLabelToDateIfPossible(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return s;

    final parsed = DateTime.tryParse(s.replaceAll(' ', 'T'));
    if (parsed != null) return _axisDateFmt.format(parsed);

    final ddmmyyyy = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (ddmmyyyy.hasMatch(s)) {
      try {
        final dt = _fallbackDateFmtFull.parseStrict(s);
        return _axisDateFmt.format(dt);
      } catch (_) {
        return s;
      }
    }

    final ddmm = RegExp(r'^\d{2}/\d{2}$');
    if (ddmm.hasMatch(s)) return s;

    return '${widget.prefix ?? ''}$s';
  }

  double _bottomReservedSize() => 28.0;

  // ✅ largura "segura" do card (para não ficar unbounded)
  double _cardWidth(BuildContext context) {
    final w = widget.larguraGrafico;
    if (w != null && w.isFinite && w > 0) {
      return math.max(320.0, w);
    }
    return MediaQuery.of(context).size.width;
  }

  // ✅ altura total do card (fixa), garantindo consistência com/sem header
  double _cardHeight(BuildContext context) {
    final h = widget.alturaGrafico;
    if (h != null && h.isFinite && h > 0) return h.toDouble();
    return 240.0;
  }

  List<LineChartBarData> _buildBars({
    required bool isDark,
    required Color surface,
  }) {
    if (!_usandoSeries) {
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
          barWidth: 3,
          isStrokeCapRound: true,
          gradient: const LinearGradient(colors: [_orange1, _orange2]),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _orange1.withValues(alpha: 0.28),
                _orange1.withValues(alpha: 0.00),
              ],
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, idx) {
              final isSelected = idx == widget.selectedIndex;
              return FlDotCirclePainter(
                radius: isSelected ? 6.5 : 3.2,
                color: isSelected ? const Color(0xFF206AF5) : surface,
                strokeWidth: 2,
                strokeColor: isSelected
                    ? const Color(0xFF206AF5)
                    : (isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.10)),
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
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.00),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, idx) {
              final isSelected = idx == widget.selectedIndex;
              final isStart = s.id == 'INICIO_OBRA';
              final fill = isStart
                  ? (s.color ?? _startDotColor)
                  : (isSelected ? const Color(0xFF206AF5) : surface);
              final stroke = isStart
                  ? Colors.white
                  : (isSelected
                  ? const Color(0xFF206AF5)
                  : (isDark
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.10)));

              return FlDotCirclePainter(
                radius: isSelected ? s.selectedDotRadius : s.dotRadius,
                color: fill,
                strokeWidth: 2,
                strokeColor: stroke,
              );
            },
          ),
        ),
      );
    }
    return bars;
  }

  List<LineTooltipItem> _buildTooltipItems(
      BuildContext context,
      List<LineBarSpot> spots,
      ) {
    final theme = Theme.of(context);
    final items = <LineTooltipItem>[];
    final eff = _seriesEffective;

    for (final lbs in spots) {
      final seriesIndex = lbs.barIndex;
      final y = lbs.y;

      String name = '';
      if (_usandoSeries && seriesIndex >= 0 && seriesIndex < eff.length) {
        final s = eff[seriesIndex];
        name = s.name ?? s.id;
      }

      final text = widget.tooltipFormatter?.call(y) ?? SipGedFormatMoney.doubleToText(y);
      final label = name.isEmpty ? text : '$name: $text';

      items.add(
        LineTooltipItem(
          label,
          theme.textTheme.labelMedium!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            shadows: const [
              Shadow(
                blurRadius: 1,
                color: Colors.black54,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildBottomTitle(BuildContext context, int i) {
    final theme = Theme.of(context);

    if (_hasAnyDateLabels) {
      final dt = _dateAtIndex(i);
      if (dt == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          _axisDateFmt.format(dt),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.labelSmall?.color?.withOpacity(0.65),
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      );
    }

    if (i < 0 || i >= widget.labels.length) return const SizedBox.shrink();
    final fixed = _fixLabelToDateIfPossible(widget.labels[i]);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        fixed,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.labelSmall?.color?.withOpacity(0.65),
        ),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  bool get _hasStartMarker {
    if (!_usandoSeries) return false;
    return _seriesEffective.any((s) => s.id == 'INICIO_OBRA');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final larguraDinamica = _calcLarguraDinamica(context);

    final safeMaxY = _maxY();
    final safeMinY = _safeMinY();
    final yInterval = _yInterval(safeMaxY);

    final surface = isDark ? const Color(0xFF0B0F17) : Colors.white;

    // ✅ Constrange a largura e FIXA a altura do CARD
    final cardWidth = _cardWidth(context);
    final cardHeight = _cardHeight(context);

    // ======= SHIMMER (SEM DADOS) =======
    if (_semDados) {
      final count = math.max(_effectiveCount(), 12);

      return SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: BasicCard(
          isDark: isDark,
          padding: const EdgeInsets.only(left: 12, right: 18, bottom: 12, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showHeader)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SectionTitle(
                    title: widget.headerTitle ?? 'Série',
                    subtitle: widget.headerSubtitle ?? 'Sem dados no recorte',
                    icon: widget.headerIcon ?? Icons.show_chart_rounded,
                  ),
                ),

              // ✅ Ocupa SEMPRE o restante da altura do card
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasH = constraints.maxHeight.isFinite
                        ? math.max(80.0, constraints.maxHeight)
                        : 200.0;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: larguraDinamica,
                        height: canvasH,
                        child: LineChartShimmerWidget(
                          pointsCount: count,
                          height: canvasH,
                          chartTitle: widget.headerTitle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final effectiveCount = _effectiveCount();
    final bars = _buildBars(isDark: isDark, surface: surface);

    final legendWidgets = <Widget>[];
    if (_usandoSeries && widget.showLegend) {
      if (_hasStartMarker ||
          (widget.verticalLinesAt != null && widget.verticalLinesAt!.isNotEmpty)) {
        legendWidgets.add(const _LegendDot(color: _startDotColor, label: 'Início da obra'));
      }
      for (var i = 0; i < _seriesEffective.length; i++) {
        final s = _seriesEffective[i];
        if (s.id == 'INICIO_OBRA') continue;
        legendWidgets.add(
          _LegendDot(
            color: s.color ?? _palette[i % _palette.length],
            label: s.name ?? s.id,
          ),
        );
      }
    }

    return SizedBox(
      width: cardWidth,
      height: cardHeight, // ✅ altura fixa: com/sem header, fica igual
      child: BasicCard(
        isDark: isDark,
        padding: const EdgeInsets.only(left: 12, right: 18, bottom: 12, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SectionTitle(
                  title: widget.headerTitle ?? 'Série',
                  subtitle: widget.headerSubtitle ?? 'Evolução no tempo',
                  icon: widget.headerIcon ?? Icons.show_chart_rounded,
                ),
              ),
            if (legendWidgets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: legendWidgets,
                ),
              ),

            // ✅ O gráfico ocupa o restante SEM estourar altura
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasH = constraints.maxHeight.isFinite
                      ? math.max(80.0, constraints.maxHeight)
                      : 200.0;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: larguraDinamica,
                      height: canvasH,
                      child: RepaintBoundary(
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (math.max(effectiveCount - 1, 0)).toDouble(),
                            minY: safeMinY,
                            maxY: safeMaxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: yInterval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                strokeWidth: 1,
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  interval: yInterval,
                                  getTitlesWidget: (v, _) {
                                    return Text(
                                      _formatAxisY(v),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.textTheme.labelSmall?.color?.withOpacity(0.60),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  },
                                ),
                              ),
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
                                    return _buildBottomTitle(context, i);
                                  },
                                ),
                              ),
                            ),
                            extraLinesData: ExtraLinesData(
                              verticalLines: (widget.verticalLinesAt ?? const <int>[])
                                  .map(
                                    (x) => VerticalLine(
                                  x: x.toDouble(),
                                  strokeWidth: 1.5,
                                  color: const Color(0xFF9E9E9E).withValues(alpha: 0.85),
                                  dashArray: const [4, 4],
                                ),
                              )
                                  .toList(),
                            ),
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => const Color(0xFF121A2D),
                                tooltipBorderRadius: BorderRadius.circular(12),
                                tooltipPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                getTooltipItems: (touched) => _buildTooltipItems(context, touched),
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
                            lineBarsData: bars,
                          ),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.labelSmall?.color?.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

/// SectionTitle embutido (opcional no LineChartChanged)
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.70);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 10),

        /// ✅ TROCA CRÍTICA:
        /// Expanded + unbounded width (Row dentro de scroll horizontal) = crash.
        /// Flexible(loose) evita esse problema.
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: subColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
