// lib/_services/geoJson/stakes_up_right.dart
import 'package:flutter/material.dart';

/// ======= UI do risco + bolha (texto com contorno) =======
class StakesUpRight extends StatelessWidget {
  final String label;
  final double normalAngle; // mantido p/ compatibilidade
  final double tickPx;      // mantido p/ compatibilidade

  const StakesUpRight({
    super.key,
    required this.label,
    required this.normalAngle,
    required this.tickPx,
  });

  @override
  Widget build(BuildContext context) {
    const strokeW = 3.0;

    // camada de contorno em branco
    final strokeText = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.0,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..color = const Color(0xFFFFFFFF).withOpacity(0.95),
      ),
    );

    // camada de preenchimento (preto) + sombra leve
    final fillText = Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.0,
        shadows: [
          Shadow(offset: Offset(0, 1), blurRadius: 1.5, color: Color(0x55000000)),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        strokeText,
        fillText,
      ],
    );
  }
}
