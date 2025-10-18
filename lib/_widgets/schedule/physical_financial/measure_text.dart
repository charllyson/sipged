import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';

class PhysFinMeasure {
  static double measureMaxTextWidth({
    required BuildContext context,
    required List<String> strings,
    TextStyle style = const TextStyle(fontSize: 14),
    double padding = 24.0,
    double safety = 0.0,
    ui.TextDirection textDirection = ui.TextDirection.ltr,
  }) {
    final scale = MediaQuery.textScaleFactorOf(context);
    double maxW = 0;
    for (final s in strings) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: textDirection,
        textScaleFactor: scale,
        maxLines: 1,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      if (tp.width > maxW) maxW = tp.width;
    }
    return maxW + padding + safety;
  }
}
