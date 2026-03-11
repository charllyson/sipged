import 'package:flutter/material.dart';

enum TextKind { point, area }

class TextFeature {
  TextFeature.point({
    required this.position,
    required this.text,
    required this.fontSize,
    required this.color,
    this.vertical = false,
  })  : kind = TextKind.point,
        areaSize = null;

  TextFeature.area({
    required this.position,
    required this.areaSize,
    required this.text,
    required this.fontSize,
    required this.color,
    this.vertical = false,
  }) : kind = TextKind.area;

  final TextKind kind;
  final Offset position;          // topLeft para área; origem para ponto
  final Size? areaSize;           // só quando kind == area
  final String text;
  final double fontSize;
  final Color color;
  final bool vertical;
}

class MenuTextPainter extends CustomPainter {
  MenuTextPainter({
    required this.items,
    required this.selectedIndex,
    this.draftAreaRect,
  });

  final List<TextFeature> items;
  final int? selectedIndex;
  final Rect? draftAreaRect; // retângulo enquanto arrasta para “texto de área”

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < items.length; i++) {
      final it = items[i];

      TextPainter tp = TextPainter(
        text: TextSpan(
          text: it.text,
          style: TextStyle(
            color: it.color,
            fontSize: it.fontSize,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      Offset paintAt = it.position;

      if (it.kind == TextKind.area && it.areaSize != null) {
        tp.layout(maxWidth: it.areaSize!.width);
        // mostra contorno da área
        final rect = paintAt & it.areaSize!;
        final areaStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x66FFFFFF);
        canvas.drawRect(rect, areaStroke);
      } else {
        tp.layout(maxWidth: 480); // largura “livre” p/ ponto
      }

      tp.paint(canvas, paintAt);

      // seleção
      if (selectedIndex == i) {
        final bounds = _measureBounds(it);
        final sel = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF8CC8FF);
        canvas.drawRect(bounds, sel);
      }
    }

    // rascunho do retângulo de área
    if (draftAreaRect != null) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white70;
      final dash = Path()..addRect(draftAreaRect!);
      canvas.drawPath(dash, p);
    }
  }

  Rect _measureBounds(TextFeature it) {
    final tp = TextPainter(
      text: TextSpan(
        text: it.text,
        style: TextStyle(
          color: it.color,
          fontSize: it.fontSize,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    if (it.kind == TextKind.area && it.areaSize != null) {
      tp.layout(maxWidth: it.areaSize!.width);
      final double h = tp.height.clamp(0.0, it.areaSize!.height).toDouble();
      return Rect.fromLTWH(it.position.dx, it.position.dy, it.areaSize!.width, h);
    } else {
      tp.layout(maxWidth: 480);
      return it.position & tp.size;
    }
  }

  @override
  bool shouldRepaint(covariant MenuTextPainter old) =>
      old.items != items || old.selectedIndex != selectedIndex || old.draftAreaRect != draftAreaRect;
}
