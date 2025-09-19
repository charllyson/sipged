import 'package:flutter/material.dart';

class PinChanged extends StatelessWidget {
  const PinChanged({
    super.key,
    this.size = 34,
    this.color = const Color(0xFFE67E22),
    this.borderColor = const Color(0xFF5A3A12),
    this.showShadow = true,
    this.innerDot = true,
    this.label,
    this.labelStyle,
    this.maxLabelChars = 3, // 👈 agora até 3
  });

  final double size;
  final Color color;
  final Color borderColor;
  final bool showShadow;
  final bool innerDot;
  final String? label;
  final TextStyle? labelStyle;
  final int maxLabelChars;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TipAlignedPinPainter(
        color: color,
        borderColor: borderColor,
        showShadow: showShadow,
        innerDot: innerDot,
        label: label,
        labelStyle: labelStyle,
        maxLabelChars: maxLabelChars,
      ),
    );
  }
}

class _TipAlignedPinPainter extends CustomPainter {
  _TipAlignedPinPainter({
    required this.color,
    required this.borderColor,
    required this.showShadow,
    required this.innerDot,
    required this.label,
    required this.labelStyle,
    required this.maxLabelChars,
  });

  final Color color;
  final Color borderColor;
  final bool showShadow;
  final bool innerDot;
  final String? label;
  final TextStyle? labelStyle;
  final int maxLabelChars;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tip = Offset(w / 2, h);

    // balão + bico
    final r  = w * 0.22;
    final cx = w / 2;
    final cy = h - r - (h * 0.35);
    final balloon = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final neckW = r * 0.9;
    final neckTop = Offset(cx, cy + r * 0.55);
    final p = Path()
      ..addPath(balloon, Offset.zero)
      ..moveTo(cx - neckW / 2, neckTop.dy)
      ..lineTo(cx + neckW / 2, neckTop.dy)
      ..lineTo(tip.dx, tip.dy)
      ..close();

    if (showShadow) {
      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawPath(p, Paint()..color = color);

    // círculo branco
    if (innerDot) {
      final whiteR = r * 0.58;
      final center = Offset(cx, cy);
      canvas.drawCircle(center, whiteR, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        whiteR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = Colors.black12,
      );

      // ===== Texto (até 3 chars) =====
      final raw = (label ?? '').trim().toUpperCase();
      if (raw.isNotEmpty) {
        final text = raw.length <= maxLabelChars ? raw : raw.substring(0, maxLabelChars);

        // tamanho base por comprimento (afinando para 3 letras)
        double fontSize;
        switch (text.length) {
          case 1: fontSize = whiteR * 1.15; break;
          case 2: fontSize = whiteR * 0.95; break;
          default: fontSize = whiteR * 0.80; break; // 3+
        }

        var style = (labelStyle ??
            const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ))
            .copyWith(fontSize: fontSize, height: 1.0, letterSpacing: 0.5);

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
    }
  }

  @override
  bool shouldRepaint(covariant _TipAlignedPinPainter old) =>
      old.color != color ||
          old.borderColor != borderColor ||
          old.showShadow != showShadow ||
          old.innerDot != innerDot ||
          old.label != label ||
          old.labelStyle != labelStyle ||
          old.maxLabelChars != maxLabelChars;
}
