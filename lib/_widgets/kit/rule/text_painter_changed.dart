import 'package:flutter/material.dart';

class TextPainterChanged {
  final TextStyle? style;
  TextPainterChanged({this.style});

  void paint(
      Canvas canvas,
      String text,
      Offset at, {
        double maxWidth = 120,
        TextAlign align = TextAlign.left,
      }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style ?? const TextStyle(fontSize: 11)),
      textAlign: align,
      maxLines: 1,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    )..layout(minWidth: 0, maxWidth: maxWidth);

    double dx = at.dx;
    if (align == TextAlign.center) {
      dx = at.dx + (maxWidth - tp.width) / 2;
    } else if (align == TextAlign.right) {
      dx = at.dx + (maxWidth - tp.width);
    }

    tp.paint(canvas, Offset(dx, at.dy));
  }
}
