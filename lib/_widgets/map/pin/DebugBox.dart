import 'package:flutter/material.dart';

class DebugBox extends StatelessWidget {
  const DebugBox(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext _) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DebugPainter(),
    );
  }
}

class _DebugPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..style = PaintingStyle.stroke;
    // caixa
    c.drawRect(Offset.zero & s, p);
    // cruz no fundo-centro (onde deve cair o ponto do mapa)
    c.drawLine(Offset(s.width/2, s.height-8), Offset(s.width/2, s.height), p);
    c.drawCircle(Offset(s.width/2, s.height), 3, Paint());
  }
  @override
  bool shouldRepaint(_) => false;
}
