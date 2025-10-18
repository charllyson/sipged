// lib/_widgets/map/pin/pin_changed.dart
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

    // shape (center)
    this.tipFactor = 0.90,  // comprimento do bico: 0.75–1.00
    this.taper = 0.38,      // afunilamento lateral: 0.30–0.45

    // “halo” (auréola) opcional ao redor da cabeça
    this.halo = false,
    this.haloOpacity = 0.25,
    this.haloScale = 1.65,  // raio do halo em múltiplos do raio da cabeça
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

  // halo
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

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    if (anchor == PinAnchor.tip) {
      // ===== Pin ancorado na PONTA (a ponta fica em y = height) =====
      final w = size.width, h = size.height;
      final cx = w / 2, bottom = h;

      // altura total ≈ 2r + tipH
      final r = (h / (2 + tipFactor)).clamp(6.0, h / 2);
      final tipH = r * tipFactor;

      // centro da cabeça sobe para caber o bico
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
        canvas.drawShadow(path, Colors.black.withOpacity(0.28), 3, true);
      }
      if (halo && haloOpacity > 0) {
        canvas.drawCircle(
          center,
          r * haloScale,
          Paint()
            ..isAntiAlias = true
            ..color = Colors.black.withOpacity(haloOpacity),
        );
      }
      canvas.drawPath(path, Paint()..isAntiAlias = true..color = color);

      if (borderColor.alpha > 0) {
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


    // ====== Modo center: cabeça perfeitamente redonda + bico simétrico ======
    final cx = w / 2, cy = h / 2;

    // altura total ≈ 2r + r*tipFactor  → r = h / (2 + tipFactor)
    final r = (h / (2 + tipFactor)).clamp(6.0, h / 2);
    final tipH = r * tipFactor;

    // sobe a cabeça para caber o bico
    final center = Offset(cx, cy - tipH / 2);
    final head = Rect.fromCircle(center: center, radius: r);

    // pontos na base inferior do círculo, levemente abertos (ângulos 210° e 330°)
    Offset onCircle(double deg) {
      final a = deg * math.pi / 180.0;
      return Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
    }

    final pL = onCircle(210); // base esquerda
    final pR = onCircle(330); // base direita
    final tip = Offset(center.dx, center.dy + r + tipH);

    // controles das curvas que descem para o bico (simétricos)
    final cpDownL = Offset(center.dx - r * taper, center.dy + r * 0.70);
    final cpDownR = Offset(center.dx + r * taper, center.dy + r * 0.70);

    final path = Path()
    // 1) cabeça perfeita: círculo completo
      ..addOval(head)
    // 2) rabo (gota) — curva direita e esquerda fechando no pL
      ..moveTo(pR.dx, pR.dy)
      ..quadraticBezierTo(cpDownR.dx, cpDownR.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(cpDownL.dx, cpDownL.dy, pL.dx, pL.dy)
      ..close();

    if (showShadow) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.28), 3, true);
    }

    // halo (auréola translúcida) — fica atrás de tudo
    if (halo && haloOpacity > 0) {
      canvas.drawCircle(
        center,
        r * haloScale,
        Paint()
          ..isAntiAlias = true
          ..color = Colors.black.withOpacity(haloOpacity),
      );
    }

    // corpo
    canvas.drawPath(path, Paint()..isAntiAlias = true..color = color);

    if (borderColor.alpha > 0) {
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
    canvas.drawCircle(center, whiteR, Paint()..isAntiAlias = true..color = Colors.white);
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

    final text = raw.length <= maxLabelChars ? raw : raw.substring(0, maxLabelChars);
    double fontSize;
    switch (text.length) {
      case 1: fontSize = whiteR * 1.15; break;
      case 2: fontSize = whiteR * 0.95; break;
      default: fontSize = whiteR * 0.80; break;
    }

    final style = (labelStyle ??
        const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700))
        .copyWith(fontSize: fontSize, height: 1.0, letterSpacing: 0.5);

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: whiteR * 2.0);

    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) =>
      old.color != color ||
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
