import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_class.dart';

class TreemapPainter extends CustomPainter {
  final List<TreemapItem> items;
  final Map<TreemapItem, Rect> outRects;
  final TreemapItem? selected;

  /// intensidade 0..1 por item (0 = bem apagado, 1 = cor cheia)
  final Map<TreemapItem, double>? intensityByItem;

  TreemapPainter(
      this.items, {
        required this.outRects,
        required this.selected,
        this.intensityByItem,
      });

  @override
  void paint(Canvas canvas, Size size) {
    outRects.clear();
    if (size.isEmpty) return;

    final total = items.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    _drawSquarify(canvas, rect, List.of(items), total);

    // Seleção sem cantos arredondados (borda)
    if (selected != null && outRects[selected] != null) {
      final r = outRects[selected]!;
      final paintGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = Colors.black.withValues(alpha: 0.25);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawRect(r.inflate(1.5), paintGlow);
      canvas.drawRect(r, paint);
    }
  }

  void _drawSquarify(
      Canvas canvas,
      Rect rect,
      List<TreemapItem> list,
      double total,
      ) {
    if (list.isEmpty || rect.isEmpty || total <= 0) return;

    if (list.length == 1) {
      final item = list.first;

      // intensidade 0..1
      double factor = 1.0;
      if (intensityByItem != null && intensityByItem![item] != null) {
        factor = intensityByItem![item]!.clamp(0.0, 1.0);
      }

      // mapeia 0..1 -> 0.25..1.0 para nunca sumir totalmente
      const minAlpha = 0.25;
      const maxAlpha = 1.0;
      final alphaFactor = minAlpha + (maxAlpha - minAlpha) * factor;

      final paint = Paint()
        ..color = item.color.withValues(alpha: alphaFactor);

      // bloco folha (sem arredondamento)
      canvas.drawRect(rect, paint);

      // salva retângulo para hit-test
      outRects[item] = rect;

      // texto dinâmico
      final txtColor = (item.color.computeLuminance() > 0.5)
          ? Colors.black87
          : Colors.white;
      final baseFontSize =
      (rect.shortestSide * 0.22).clamp(8.0, 18.0);

      final tp = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            color: txtColor,
            fontSize: baseFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 8);

      tp.paint(canvas, rect.topLeft + const Offset(4, 4));
      return;
    }

    // ordena desc (em cópia local)
    list.sort((a, b) => b.value.compareTo(a.value));

    // split simples
    final half = list.length ~/ 2;
    final first = list.sublist(0, half);
    final second = list.sublist(half);

    final firstTotal = first.fold<double>(0, (s, e) => s + e.value);
    final ratio = firstTotal <= 0 ? 0.0 : (firstTotal / total).clamp(0.0, 1.0);

    if (rect.width > rect.height) {
      final wLeft = rect.width * ratio;
      final left =
      Rect.fromLTWH(rect.left, rect.top, wLeft, rect.height);
      final right = Rect.fromLTWH(
        rect.left + wLeft,
        rect.top,
        rect.width - wLeft,
        rect.height,
      );
      if (!left.isEmpty && firstTotal > 0) {
        _drawSquarify(canvas, left, first, firstTotal);
      }
      final secondTotal = total - firstTotal;
      if (!right.isEmpty && secondTotal > 0) {
        _drawSquarify(canvas, right, second, secondTotal);
      }
    } else {
      final hTop = rect.height * ratio;
      final top =
      Rect.fromLTWH(rect.left, rect.top, rect.width, hTop);
      final bottom = Rect.fromLTWH(
        rect.left,
        rect.top + hTop,
        rect.width,
        rect.height - hTop,
      );
      if (!top.isEmpty && firstTotal > 0) {
        _drawSquarify(canvas, top, first, firstTotal);
      }
      final secondTotal = total - firstTotal;
      if (!bottom.isEmpty && secondTotal > 0) {
        _drawSquarify(canvas, bottom, second, secondTotal);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TreemapPainter old) =>
      old.items != items ||
          old.selected != selected ||
          old.intensityByItem != intensityByItem;
}
