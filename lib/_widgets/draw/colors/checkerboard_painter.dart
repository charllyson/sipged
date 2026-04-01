import 'package:flutter/material.dart';

class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 8.0;
    final light = Paint()..color = const Color(0xFFF3F3F3);
    final dark = Paint()..color = const Color(0xFFD7D7D7);

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final isDark = ((x / cell).floor() + (y / cell).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          isDark ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
