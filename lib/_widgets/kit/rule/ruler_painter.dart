import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_widgets/kit/rule/text_painter_changed.dart';
import 'package:siged/_utils/formats/format_field.dart';

class RulerPainter extends CustomPainter {
  final double min;
  final double max;
  final double value; // perKm
  final Map<String, double>? benchmarks;
  final TextStyle? textStyle;

  final bool highlightContract;
  final bool highlightMedia;
  final bool highlightTeto;

  RulerPainter({
    required this.min,
    required this.max,
    required this.value,
    this.benchmarks,
    this.textStyle,
    this.highlightContract = false,
    this.highlightMedia = false,
    this.highlightTeto = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackTop = 24.0;
    final trackHeight = 10.0;
    final left = 6.0;
    final right = size.width - 6.0;

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, trackTop, right - left, trackHeight),
      const Radius.circular(6),
    );

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEFF2FF), Color(0xFFDDE5FF)],
      ).createShader(trackRect.outerRect);
    canvas.drawRRect(trackRect, bgPaint);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFCDD6FF);
    canvas.drawRRect(trackRect, border);

    final (double? media, double? teto) = pickThresholds(benchmarks);

    double clamp(double v) => v < min ? min : (v > max ? max : v);
    double toX(double v) {
      final t = (clamp(v) - min) / (max - min);
      return left + t * (right - left);
    }

    final step = _niceStep(max - min);
    final firstTick = _ceilTo(min, step);
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final tp = TextPainterChanged(style: textStyle);

    for (double v = firstTick; v <= max + 1e-6; v += step) {
      final x = toX(v);
      canvas.drawLine(
        Offset(x, trackTop + trackHeight + 4),
        Offset(x, trackTop + trackHeight + 12),
        tickPaint,
      );
      tp.paint(
        canvas,
        _abbr(v),
        Offset(x - 24, trackTop + trackHeight + 14),
        maxWidth: 48,
        align: TextAlign.center,
      );
    }

    final bmStyle =
    (textStyle ?? const TextStyle()).copyWith(color: const Color(0xFF4C57B7));

    benchmarks?.forEach((label, v) {
      final x = toX(v);
      final isMedia = _isMediaLabel(label);
      final isTeto = _isTetoLabel(label);

      final active  = (isMedia && highlightMedia) || (isTeto && highlightTeto);
      final baseColor = isTeto ? Colors.red : const Color(0xFF4C57B7);

      if (active) {
        final outline = Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, trackTop - 10),
          Offset(x, trackTop + trackHeight + 2),
          outline,
        );

        final inner = Paint()
          ..color = baseColor
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, trackTop - 10),
          Offset(x, trackTop + trackHeight + 2),
          inner,
        );

        final cy = trackTop + trackHeight / 2;
        final r  = 5.0;
        final capFill = Paint()..color = baseColor;
        final capStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black.withOpacity(0.25);

        canvas.drawCircle(Offset(x, cy), r, capFill);
        canvas.drawCircle(Offset(x, cy), r, capStroke);
      } else {
        final bmPaint = Paint()
          ..color = baseColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, trackTop - 10),
          Offset(x, trackTop + trackHeight + 2),
          bmPaint,
        );
      }

      TextPainterChanged(style: bmStyle).paint(
        canvas,
        label,
        Offset(x + 4, trackTop - 22),
        maxWidth: 100,
      );
    });

    final (double? mediaV, double? tetoV) = (media, teto);
    final markerX = toX(value);
    _drawContractMarker(
      canvas: canvas,
      x: markerX,
      trackTop: trackTop,
      trackHeight: trackHeight,
      baseColor: _colorFor(value, mediaV, tetoV),
      label: priceToString(value),
      emphasize: highlightContract,
    );
  }

  void _drawContractMarker({
    required Canvas canvas,
    required double x,
    required double trackTop,
    required double trackHeight,
    required Color baseColor,
    required String label,
    required bool emphasize,
  }) {
    final scale = emphasize ? 1.15 : 1.0;
    final h = 16.0 * scale;
    final w = 8.0 * scale;

    final markerPath = Path()
      ..moveTo(x, trackTop - h)
      ..lineTo(x - w, trackTop - 2)
      ..lineTo(x + w, trackTop - 2)
      ..close();

    final fill = Paint()..color = baseColor;
    canvas.drawPath(markerPath, fill);

    canvas.drawCircle(
      Offset(x, trackTop + trackHeight / 2),
      4 * scale,
      Paint()..color = baseColor,
    );

    if (emphasize) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Colors.black.withOpacity(0.25);
      canvas.drawPath(markerPath, stroke);
      canvas.drawCircle(
        Offset(x, trackTop + trackHeight / 2),
        4 * scale,
        stroke,
      );
    }

    TextPainterChanged(
      style: (textStyle ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
    ).paint(
      canvas,
      label,
      Offset(x - 80, trackTop - 40 * scale),
      maxWidth: 160,
      align: TextAlign.center,
    );
  }

  Color _colorFor(double v, double? media, double? teto) {
    if (teto != null && v > teto) return Colors.red;
    if (media != null && v <= media) return Colors.green;
    return Colors.amber;
  }

  static (double?, double?) pickThresholds(Map<String, double>? bm) {
    if (bm == null || bm.isEmpty) return (null, null);
    double? media = bm['Média'] ?? bm['Media'] ?? bm['Meta'];
    double? teto  = bm['Teto']  ?? bm['Limite'];
    final values = bm.values.toList();
    if (media == null && values.isNotEmpty) media = values.reduce(math.min);
    if (teto == null && values.isNotEmpty)  teto  = values.reduce(math.max);
    return (media, teto);
  }

  static bool _isMediaLabel(String s) {
    final l = s.toLowerCase();
    return l.contains('média') || l.contains('media') || l.contains('meta');
  }

  static bool _isTetoLabel(String s) {
    final l = s.toLowerCase();
    return l.contains('teto') || l.contains('limite');
  }

  static double _niceStep(double span) {
    if (span <= 0) return 1;
    final exp = (math.log(span) / math.ln10).floor();
    final base = math.pow(10.0, exp).toDouble();
    final units = span / base;
    double mult;
    if (units <= 1.2)      mult = 0.2;
    else if (units <= 2.5) mult = 0.5;
    else if (units <= 6)   mult = 1.0;
    else if (units <= 12)  mult = 2.0;
    else                   mult = 5.0;

    final unit = _unit(base);
    if (unit.isNotEmpty) {
      final ord = _orderMagnitude(base);
      final choices = [1, 2, 5].map((m) => m * ord).toList();
      final target = mult * base;
      choices.sort((a, b) => (a - target).abs().compareTo((b - target).abs()));
      return choices.first.toDouble();
    }
    return mult * base;
  }

  static double _ceilTo(double v, double step) => (v / step).ceilToDouble() * step;

  static String _abbr(double v) {
    final abs = v.abs();
    String unit; double div;
    if (abs >= 1e12) { unit = 'T'; div = 1e12; }
    else if (abs >= 1e9) { unit = 'B'; div = 1e9; }
    else if (abs >= 1e6) { unit = 'M'; div = 1e6; }
    else if (abs >= 1e3) { unit = 'k'; div = 1e3; }
    else { return v.toStringAsFixed(0); }
    final scaled = v / div;
    final isIntish = (scaled - scaled.roundToDouble()).abs() < 1e-6;
    final numStr = isIntish ? scaled.toStringAsFixed(0) : scaled.toStringAsFixed(1);
    return '$numStr$unit';
  }

  static String _unit(double v) {
    final a = v.abs();
    if (a >= 1e12) return 'T';
    if (a >= 1e9)  return 'B';
    if (a >= 1e6)  return 'M';
    if (a >= 1e3)  return 'k';
    return '';
  }

  static double _orderMagnitude(double v) {
    final a = v.abs();
    if (a >= 1e12) return 1e12;
    if (a >= 1e9)  return 1e9;
    if (a >= 1e6)  return 1e6;
    if (a >= 1e3)  return 1e3;
    return 1.0;
  }

  @override
  bool shouldRepaint(covariant RulerPainter old) {
    return min != old.min ||
        max != old.max ||
        value != old.value ||
        benchmarks != old.benchmarks ||
        textStyle != old.textStyle ||
        highlightContract != old.highlightContract ||
        highlightMedia != old.highlightMedia ||
        highlightTeto != old.highlightTeto;
  }
}
