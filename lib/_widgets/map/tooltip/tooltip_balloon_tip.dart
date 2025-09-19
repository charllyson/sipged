import 'package:flutter/material.dart';

enum BalloonDirection { down, up }

/// Triângulo do balão (a “setinha” que aponta para o pin).
/// Use logo abaixo (ou acima) do card.
/// Ex.: `BalloonTip(color: Colors.black87)`

/// Dica: quando o tooltip fica acima do pin, use `direction: BalloonDirection.down`
/// para a seta apontar para baixo (em direção ao pin).
class TooltipBalloonTip extends StatelessWidget {
  const TooltipBalloonTip({
    super.key,
    this.color = Colors.black87,
    this.borderColor,
    this.width = 14,
    this.height = 7,
    this.direction = BalloonDirection.down,
    this.shadow = true,
  });

  final Color color;
  final Color? borderColor;
  final double width;
  final double height;
  final BalloonDirection direction;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BalloonTipPainter(
        color: color,
        borderColor: borderColor,
        direction: direction,
        shadow: shadow,
      ),
    );
  }
}

class _BalloonTipPainter extends CustomPainter {
  _BalloonTipPainter({
    required this.color,
    required this.borderColor,
    required this.direction,
    required this.shadow,
  });

  final Color color;
  final Color? borderColor;
  final BalloonDirection direction;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Triângulo isósceles: base em cima/baixo conforme direção
    final path = Path();
    if (direction == BalloonDirection.down) {
      // base no topo, vértice para baixo (aponta para o pin)
      path
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w / 2, h)
        ..close();
    } else {
      // base embaixo, vértice para cima
      path
        ..moveTo(0, h)
        ..lineTo(w, h)
        ..lineTo(w / 2, 0)
        ..close();
    }

    if (shadow) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.25), 2, true);
    }

    final fill = Paint()..color = color;
    canvas.drawPath(path, fill);

    if (borderColor != null) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..color = borderColor!;
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonTipPainter old) =>
      old.color != color ||
          old.borderColor != borderColor ||
          old.direction != direction ||
          old.shadow != shadow;
}
