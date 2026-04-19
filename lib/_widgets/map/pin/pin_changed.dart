import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PinAnchor { tip, center }

class PinChanged extends StatelessWidget {
  const PinChanged({
    super.key,
    this.size = 40,
    this.color = Colors.black26,
    this.borderColor = const Color(0x00000000),
    this.showShadow = true,
    this.innerDot = true,
    this.label,
    this.labelStyle,
    this.maxLabelChars = 3,
    this.anchor = PinAnchor.center,
    this.tipFactor = 0.90,
    this.taper = 0.38,
    this.halo = false,
    this.haloOpacity = 0.25,
    this.haloScale = 1.65,
  });

  final double size;
  final Color color;
  final Color borderColor;
  final bool showShadow;
  final bool innerDot;
  final String? label;
  final TextStyle? labelStyle;
  final int maxLabelChars;
  final PinAnchor anchor;

  final double tipFactor;
  final double taper;

  final bool halo;
  final double haloOpacity;
  final double haloScale;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PinPainter(
        color: color,
        borderColor: borderColor,
        showShadow: showShadow,
        innerDot: innerDot,
        label: label,
        labelStyle: labelStyle,
        maxLabelChars: maxLabelChars,
        anchor: anchor,
        tipFactor: tipFactor,
        taper: taper,
        halo: halo,
        haloOpacity: haloOpacity,
        haloScale: haloScale,
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({
    required this.color,
    required this.borderColor,
    required this.showShadow,
    required this.innerDot,
    required this.label,
    required this.labelStyle,
    required this.maxLabelChars,
    required this.anchor,
    required this.tipFactor,
    required this.taper,
    required this.halo,
    required this.haloOpacity,
    required this.haloScale,
  });

  final Color color;
  final Color borderColor;
  final bool showShadow;
  final bool innerDot;
  final String? label;
  final TextStyle? labelStyle;
  final int maxLabelChars;
  final PinAnchor anchor;
  final double tipFactor;
  final double taper;
  final bool halo;
  final double haloOpacity;
  final double haloScale;

  int _channel255(double normalized) {
    return (normalized * 255.0).round().clamp(0, 255);
  }

  bool get _hasBorderAlpha => _channel255(borderColor.a) > 0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (anchor == PinAnchor.tip) {
      final cx = w / 2;
      final bottom = h;

      final r = (h / (2 + tipFactor)).clamp(6.0, h / 2);
      final tipH = r * tipFactor;

      final center = Offset(cx, bottom - (tipH + r));
      final head = Rect.fromCircle(center: center, radius: r);

      Offset onCircle(double deg) {
        final a = deg * math.pi / 180.0;
        return Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      }

      final pL = onCircle(210);
      final pR = onCircle(330);
      final tip = Offset(cx, bottom);

      final cpDownL = Offset(center.dx - r * taper, center.dy + r * 0.70);
      final cpDownR = Offset(center.dx + r * taper, center.dy + r * 0.70);

      final path = Path()
        ..addOval(head)
        ..moveTo(pR.dx, pR.dy)
        ..quadraticBezierTo(cpDownR.dx, cpDownR.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(cpDownL.dx, cpDownL.dy, pL.dx, pL.dy)
        ..close();

      if (showShadow) {
        canvas.drawShadow(path, Colors.black.withValues(alpha: 0.28), 3, true);
      }

      if (halo && haloOpacity > 0) {
        canvas.drawCircle(
          center,
          r * haloScale,
          Paint()
            ..isAntiAlias = true
            ..color = Colors.black.withValues(alpha: haloOpacity),
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..isAntiAlias = true
          ..color = color,
      );

      if (_hasBorderAlpha) {
        canvas.drawPath(
          path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7
            ..color = borderColor,
        );
      }

      _paintInnerDotAndText(canvas, center, r * 0.95);
      return;
    }

    final cx = w / 2;
    final cy = h / 2;

    final r = (h / (2 + tipFactor)).clamp(6.0, h / 2);
    final tipH = r * tipFactor;

    final center = Offset(cx, cy - tipH / 2);
    final head = Rect.fromCircle(center: center, radius: r);

    Offset onCircle(double deg) {
      final a = deg * math.pi / 180.0;
      return Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
    }

    final pL = onCircle(210);
    final pR = onCircle(330);
    final tip = Offset(center.dx, center.dy + r + tipH);

    final cpDownL = Offset(center.dx - r * taper, center.dy + r * 0.70);
    final cpDownR = Offset(center.dx + r * taper, center.dy + r * 0.70);

    final path = Path()
      ..addOval(head)
      ..moveTo(pR.dx, pR.dy)
      ..quadraticBezierTo(cpDownR.dx, cpDownR.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(cpDownL.dx, cpDownL.dy, pL.dx, pL.dy)
      ..close();

    if (showShadow) {
      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.28), 3, true);
    }

    if (halo && haloOpacity > 0) {
      canvas.drawCircle(
        center,
        r * haloScale,
        Paint()
          ..isAntiAlias = true
          ..color = Colors.black.withValues(alpha: haloOpacity),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..color = color,
    );

    if (_hasBorderAlpha) {
      canvas.drawPath(
        path,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = borderColor,
      );
    }

    _paintInnerDotAndText(canvas, center, r * 0.95);
  }

  void _paintInnerDotAndText(Canvas canvas, Offset center, double r) {
    if (!innerDot) return;

    final whiteR = r * 0.58;
    canvas.drawCircle(
      center,
      whiteR,
      Paint()
        ..isAntiAlias = true
        ..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      whiteR,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.black12,
    );

    final raw = (label ?? '').trim().toUpperCase();
    if (raw.isEmpty) return;

    final text = raw.length <= maxLabelChars
        ? raw
        : raw.substring(0, maxLabelChars);

    double fontSize;
    switch (text.length) {
      case 1:
        fontSize = whiteR * 1.15;
        break;
      case 2:
        fontSize = whiteR * 0.95;
        break;
      default:
        fontSize = whiteR * 0.80;
        break;
    }

    final style = (labelStyle ??
        const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ))
        .copyWith(
      fontSize: fontSize,
      height: 1.0,
      letterSpacing: 0.5,
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: whiteR * 2.0);

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) {
    return old.color != color ||
        old.borderColor != borderColor ||
        old.showShadow != showShadow ||
        old.innerDot != innerDot ||
        old.label != label ||
        old.labelStyle != labelStyle ||
        old.maxLabelChars != maxLabelChars ||
        old.anchor != anchor ||
        old.tipFactor != tipFactor ||
        old.taper != taper ||
        old.halo != halo ||
        old.haloOpacity != haloOpacity ||
        old.haloScale != haloScale;
  }
}

class PinAureola extends StatelessWidget {
  final Color color;
  final String label;

  const PinAureola({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: color.withValues(alpha: 0.35),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}