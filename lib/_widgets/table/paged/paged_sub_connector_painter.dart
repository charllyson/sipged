import 'package:flutter/material.dart';

class PagedSubConnectorPainter extends CustomPainter {
  const PagedSubConnectorPainter({
    required this.color,
    required this.thickness,
  });

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = size.width * 0.50;
    final topY = 0.0;
    final midY = size.height * 0.45;
    final endX = size.width * 0.82;

    final path = Path()
      ..moveTo(x, topY)
      ..lineTo(x, midY)
      ..quadraticBezierTo(x, midY + 6, endX, midY + 6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PagedSubConnectorPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.thickness != thickness;
  }
}

