// lib/_widgets/toolBox/menuDrawerPolygon/polygon_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/schedule/civil/polygon_feature.dart';

class PolygonPainter extends CustomPainter {
  PolygonPainter({
    required this.features,
    required this.current,
    required this.colorForIndex,    // cor da BORDA (aleatória)
    required this.fillColorForIndex,// cor do PREENCHIMENTO (por status)
    this.percentForIndex,           // 0..100 (opcional)
    this.hasPhotosForIndex,         // bool (opcional)
    this.hasCommentForIndex,        // bool (opcional)
    required this.hoverSnap,
    required this.selectedIndex,
  });

  final List<PolygonFeature> features;
  final List<Offset> current;

  /// Borda aleatória (como antes)
  final Color Function(int index, {double s, double v}) colorForIndex;

  /// Preenchimento por status (você já passa do widget)
  final Color Function(int index, {double s, double v}) fillColorForIndex;

  /// Dados extras para o rótulo
  final double? Function(int index)? percentForIndex;
  final bool Function(int index)? hasPhotosForIndex;
  final bool Function(int index)? hasCommentForIndex;

  final Offset? hoverSnap;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < features.length; i++) {
      final feat = features[i];
      final poly = feat.points;
      if (poly.length < 3) continue;

      final strokeColor = colorForIndex(i);
      final fillColor = fillColorForIndex(i);
      final isSelected = selectedIndex == i;

      // fill
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor;
      final path = Path()..addPolygon(poly, true);
      canvas.drawPath(path, fill);

      // stroke com glow opcional se selecionado
      if (isSelected) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..color = Colors.black.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawPath(path, glow);
      }

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.2 : 2.0
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor;
      canvas.drawPath(path, stroke);

      // ===== RÓTULO CENTRALIZADO =====
      _drawCenteredLabel(canvas, feat, i);
    }

    // preview da linha em desenho
    if (current.isNotEmpty) {
      final preview = colorForIndex(features.length);
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = preview.withValues(alpha: 0.9);

      final path = Path()..moveTo(current.first.dx, current.first.dy);
      for (int i = 1; i < current.length; i++) {
        path.lineTo(current[i].dx, current[i].dy);
      }

      final dashed = Path();
      for (final metric in path.computeMetrics()) {
        double d = 0;
        const dashLen = 8.0, gap = 6.0;
        while (d < metric.length) {
          final n = (d + dashLen).clamp(0.0, metric.length).toDouble();
          dashed.addPath(metric.extractPath(d, n), Offset.zero);
          d = n + gap;
        }
      }
      canvas.drawPath(dashed, dash);

      final dot = Paint()..color = preview.withValues(alpha: 0.95);
      for (final p in current) {
        canvas.drawCircle(p, 3.5, dot);
      }
    }

    // marcador do snap
    if (hoverSnap != null) {
      final p = hoverSnap!;
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(p.translate(0, 0.5), 8, shadow);

      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white;
      canvas.drawCircle(p, 8, ring);

      final core = Paint()..color = Colors.deepOrangeAccent;
      canvas.drawCircle(p, 4.5, core);
    }
  }

  void _drawCenteredLabel(Canvas canvas, PolygonFeature feat, int index) {
    final name = feat.name.trim();
    final pct = percentForIndex?.call(index);
    final showPct = pct != null;
    final hasPhoto = hasPhotosForIndex?.call(index) ?? false;
    final hasComment = hasCommentForIndex?.call(index) ?? false;
    final iconsCount = (hasPhoto ? 1 : 0) + (hasComment ? 1 : 0);

    // ----- TextPainters -----
    final tpName = TextPainter(
      text: TextSpan(
        text: name.isEmpty ? ' ' : name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 260);

    TextPainter? tpPct;
    if (showPct) {
      tpPct = TextPainter(
        text: TextSpan(
          text: '${pct.round()}%',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    }

    // ----- Ícones como "texto" (facilita centralizar) -----
    const iconSize = 16.0;
    const iconGap = 6.0;

    TextPainter? tpPhoto;
    if (hasPhoto) {
      tpPhoto = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.photo_camera.codePoint),
          style: const TextStyle(
            fontSize: iconSize,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    TextPainter? tpComment;
    if (hasComment) {
      tpComment = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.comment_outlined.codePoint),
          style: const TextStyle(
            fontSize: iconSize,
            color: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    final iconsRowWidth = iconsCount == 0
        ? 0.0
        : (iconSize * iconsCount) + (iconGap * math.max(0, iconsCount - 1));

    // Largura máxima do bloco
    final maxW = [
      tpName.width,
      if (tpPct != null) tpPct.width,
      iconsRowWidth,
    ].fold<double>(0.0, (p, e) => math.max(p, e));

    // Altura total (com espaçamentos entre linhas)
    const gapLine = 4.0;
    final totalH = tpName.height +
        (tpPct?.height ?? 0) +
        (iconsCount > 0 ? iconSize : 0) +
        (tpPct != null ? gapLine : 0) +
        (iconsCount > 0 ? gapLine : 0);

    // Fundo "glow"
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: feat.centroid,
        width: maxW + 18,
        height: totalH + 14,
      ),
      const Radius.circular(8),
    );
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(bgRect, bg);

    // Y inicial (topo do bloco)
    double y = feat.centroid.dy - totalH / 2;

    // ---- Linha 1: Nome (centralizada) ----
    final nameX = feat.centroid.dx - (tpName.width / 2);
    tpName.paint(canvas, Offset(nameX, y));
    y += tpName.height + (tpPct != null || iconsCount > 0 ? gapLine : 0);

    // ---- Linha 2: Percentual (centralizado, se existir) ----
    if (tpPct != null) {
      final pctX = feat.centroid.dx - (tpPct.width / 2);
      tpPct.paint(canvas, Offset(pctX, y));
      y += tpPct.height + (iconsCount > 0 ? gapLine : 0);
    }

    // ---- Linha 3: Ícones (centralizados, se existirem) ----
    if (iconsCount > 0) {
      double x = feat.centroid.dx - (iconsRowWidth / 2);
      if (tpPhoto != null) {
        tpPhoto.paint(canvas, Offset(x, y));
        x += iconSize + iconGap;
      }
      if (tpComment != null) {
        tpComment.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant PolygonPainter old) {
    return old.features != features ||
        old.current != current ||
        old.hoverSnap != hoverSnap ||
        old.selectedIndex != selectedIndex;
  }
}
