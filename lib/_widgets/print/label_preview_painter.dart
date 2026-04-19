import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sipged/_widgets/print/label_bitmap.dart';

enum PreviewSection {
  none,
  cycle,
  label,
  gap,
  qr,
  text,
  padding,
  widthRuler,
  heightRuler,
}

class LabelPreviewLayout {
  final Rect cycleRect;
  final Rect labelRect;
  final Rect gapRect;
  final Rect innerRect;
  final Rect qrRect;
  final Rect textRect;

  final Rect widthRulerRect;
  final Rect heightRulerRect;
  final Rect gapRulerRect;

  const LabelPreviewLayout({
    required this.cycleRect,
    required this.labelRect,
    required this.gapRect,
    required this.innerRect,
    required this.qrRect,
    required this.textRect,
    required this.widthRulerRect,
    required this.heightRulerRect,
    required this.gapRulerRect,
  });

  PreviewSection sectionAt(Offset p) {
    if (widthRulerRect.contains(p)) return PreviewSection.widthRuler;
    if (heightRulerRect.contains(p)) return PreviewSection.heightRuler;
    if (gapRulerRect.contains(p)) return PreviewSection.gap;

    if (qrRect.contains(p)) return PreviewSection.qr;
    if (textRect.contains(p)) return PreviewSection.text;

    if (labelRect.contains(p)) return PreviewSection.padding;
    return PreviewSection.none;
  }
}

class LabelPreviewPainter extends CustomPainter {
  LabelPreviewPainter({
    required this.larguraMm,
    required this.alturaMm,
    required this.gapMm,
    required this.text,
    required this.qrData,
    required this.cfg,
    required this.theme,
    this.selectedSection = PreviewSection.none,
    this.onLayout,
    this.centerLogoMonoRot,
  });

  final double larguraMm;
  final double alturaMm;
  final double gapMm;

  final String text;
  final String qrData;
  final LabelLayoutConfig cfg;
  final ThemeData theme;

  final PreviewSection selectedSection;
  final void Function(LabelPreviewLayout layout)? onLayout;

  /// ✅ Logo PB + rotacionado vindo do PreviewPanel
  final ui.Image? centerLogoMonoRot;

  static const double _outerMargin = 14.0;
  static const double _rulerBand = 38.0;
  static const double _gapFromLabelToRuler = 15.0;
  static const double _innerTextPadding = 4.0;
  static const double _majorLen = 10.0;
  static const double _minorLen = 6.0;

  double _mmToPreviewPx(double mm, double scale) => mm * scale;

  @override
  void paint(Canvas canvas, Size size) {
    final wMm = math.max(1.0, larguraMm);
    final hMm = math.max(1.0, alturaMm);
    final gMm = math.max(0.0, gapMm);

    final totalMmH = hMm + gMm;

    final availW = math.max(10.0, size.width - _outerMargin * 2 - _rulerBand);
    final availH = math.max(10.0, size.height - _outerMargin * 2 - _rulerBand);

    final scale = math.min(availW / wMm, availH / totalMmH);

    final drawW = wMm * scale;
    final drawHLabel = hMm * scale;
    final drawHGap = gMm * scale;
    final drawHTotal = totalMmH * scale;

    final blockW = drawW + _rulerBand;
    final blockH = drawHTotal + _rulerBand;

    final blockLeft = (size.width - blockW) / 2;
    final blockTop = (size.height - blockH) / 2;

    final left = blockLeft + _rulerBand;
    final top = blockTop + _rulerBand;

    final labelRect = Rect.fromLTWH(left, top, drawW, drawHLabel);
    final gapRect = Rect.fromLTWH(left, top + drawHLabel, drawW, drawHGap);
    final cycleRect = Rect.fromLTWH(left, top, drawW, drawHTotal);

    final labelFill = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final labelStroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final gapRulerRect = Rect.fromLTWH(
      labelRect.left - _rulerBand,
      gapRect.top,
      _rulerBand,
      gapRect.height,
    );

    final gapFill = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final dashStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cycleStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cycleRect, const Radius.circular(8)),
      cycleStroke,
    );

    if (drawHGap > 0.5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(gapRect, const Radius.circular(6)),
        gapFill,
      );
      _drawDashedRect(
        canvas,
        gapRect.deflate(1.5),
        dashStroke,
        dash: 6,
        gap: 5,
      );
      _drawCenteredCaption(
        canvas,
        gapRect,
        'GAP',
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      labelFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      labelStroke,
    );

    final padPx = _mmToPreviewPx(math.max(0.0, cfg.padMm), scale);
    final inner = labelRect.deflate(padPx);

    final padStroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (inner.width > 10 && inner.height > 10) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(6)),
        padStroke,
      );
    }

    final shortSidePx = math.min(inner.width, inner.height);
    final qrSidePx = shortSidePx;
    final spacePx = _mmToPreviewPx(math.max(0.0, cfg.spaceBetweenMm), scale);

    final qrRect = Rect.fromLTWH(
      inner.left + (inner.width - qrSidePx) / 2,
      inner.bottom - qrSidePx,
      qrSidePx,
      qrSidePx,
    );

    final textH = math.max(0.0, (qrRect.top - spacePx) - inner.top);
    final textRect = Rect.fromLTWH(inner.left, inner.top, inner.width, textH);

    final widthRulerRect = Rect.fromLTWH(
      labelRect.left,
      labelRect.top - _rulerBand,
      labelRect.width,
      _rulerBand,
    );

    final heightRulerRect = Rect.fromLTWH(
      labelRect.left - _rulerBand,
      labelRect.top,
      _rulerBand,
      labelRect.height,
    );

    onLayout?.call(
      LabelPreviewLayout(
        cycleRect: cycleRect,
        labelRect: labelRect,
        gapRect: gapRect,
        innerRect: inner,
        qrRect: qrRect,
        textRect: textRect,
        widthRulerRect: widthRulerRect,
        heightRulerRect: heightRulerRect,
        gapRulerRect: gapRulerRect,
      ),
    );

    final qrBg = Paint()..color = Colors.white.withValues(alpha: 0.98);
    final qrStroke = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(qrRect, const Radius.circular(6)),
      qrBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(qrRect, const Radius.circular(6)),
      qrStroke,
    );

    final qrInset = math.max(3.0, qrRect.width * 0.06);
    final qrDrawRect = qrRect.deflate(qrInset);
    final safeData = (qrData.trim().isEmpty) ? ' ' : qrData.trim();

    try {
      final ecc = (cfg.enableQrCenterImage && centerLogoMonoRot != null)
          ? QrErrorCorrectLevel.H
          : QrErrorCorrectLevel.M;

      final qp = QrPainter(
        data: safeData,
        version: QrVersions.auto,
        gapless: true,
        errorCorrectionLevel: ecc,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
      );

      canvas.save();
      canvas.translate(qrDrawRect.left, qrDrawRect.top);
      qp.paint(canvas, Size(qrDrawRect.width, qrDrawRect.height));

      if (cfg.enableQrCenterImage && centerLogoMonoRot != null) {
        final side = (qrDrawRect.width * cfg.qrCenterImagePct)
            .clamp(qrDrawRect.width * 0.10, qrDrawRect.width * 0.35);

        final logoRect = Rect.fromCenter(
          center: Offset(qrDrawRect.width / 2, qrDrawRect.height / 2),
          width: side,
          height: side,
        );

        final whitePadPx = _mmToPreviewPx(cfg.qrCenterWhitePadMm, scale)
            .clamp(0.0, side * 0.25);

        final whiteRect = logoRect.inflate(whitePadPx);

        final radiusPx = _mmToPreviewPx(cfg.qrCenterCornerRadiusMm, scale)
            .clamp(0.0, whiteRect.shortestSide / 2);

        canvas.drawRRect(
          RRect.fromRectAndRadius(whiteRect, Radius.circular(radiusPx)),
          Paint()..color = Colors.white,
        );

        final src = Rect.fromLTWH(
          0,
          0,
          centerLogoMonoRot!.width.toDouble(),
          centerLogoMonoRot!.height.toDouble(),
        );

        final fit = applyBoxFit(BoxFit.contain, src.size, logoRect.size);
        final srcSub = Alignment.center.inscribe(fit.source, src);
        final dstSub = Alignment.center.inscribe(fit.destination, logoRect);

        final p = Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false;

        canvas.drawImageRect(centerLogoMonoRot!, srcSub, dstSub, p);
      }

      canvas.restore();
    } catch (_) {}

    final textFill = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.18);
    final textStroke = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (textRect.height > 6) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(6)),
        textFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(6)),
        textStroke,
      );

      final caption = (text.isEmpty ? '(sem texto)' : text);
      _drawTextBlock(canvas, textRect.deflate(8), caption);
    }

    _drawMmRuler(
      canvas,
      labelRect: labelRect,
      gapRect: gapRect,
      wMm: wMm,
      hMm: hMm,
      gMm: gMm,
      scale: scale,
    );

    _drawSelectionOverlay(
      canvas,
      selectedSection: selectedSection,
      wMm: wMm,
      hMm: hMm,
      gMm: gMm,
      scale: scale,
      cycleRect: cycleRect,
      labelRect: labelRect,
      gapRect: gapRect,
      innerRect: inner,
      qrRect: qrRect,
      textRect: textRect,
      widthRulerRect: widthRulerRect,
      heightRulerRect: heightRulerRect,
      gapRulerRect: gapRulerRect,
    );
  }

  void _drawSelectionOverlay(
      Canvas canvas, {
        required PreviewSection selectedSection,
        required double wMm,
        required double hMm,
        required double gMm,
        required double scale,
        required Rect cycleRect,
        required Rect labelRect,
        required Rect gapRect,
        required Rect innerRect,
        required Rect qrRect,
        required Rect textRect,
        required Rect widthRulerRect,
        required Rect heightRulerRect,
        required Rect gapRulerRect,
      }) {
    if (selectedSection == PreviewSection.none) return;

    if (selectedSection == PreviewSection.widthRuler ||
        selectedSection == PreviewSection.heightRuler ||
        selectedSection == PreviewSection.gap) {
      _drawRulerSelection(
        canvas,
        selectedSection: selectedSection,
        labelRect: labelRect,
        gapRect: gapRect,
        wMm: wMm,
        hMm: hMm,
        gMm: gMm,
        scale: scale,
      );
      return;
    }

    Rect? r;
    double radius = 8;

    switch (selectedSection) {
      case PreviewSection.cycle:
        r = cycleRect;
        radius = 8;
        break;
      case PreviewSection.label:
        r = labelRect;
        radius = 8;
        break;
      case PreviewSection.gap:
        r = gapRect;
        radius = 6;
        break;
      case PreviewSection.qr:
        r = qrRect;
        radius = 6;
        break;
      case PreviewSection.text:
        r = textRect;
        radius = 6;
        break;
      case PreviewSection.padding:
        r = innerRect;
        radius = 6;
        break;
      case PreviewSection.widthRuler:
      case PreviewSection.heightRuler:
      case PreviewSection.none:
        r = null;
        break;
    }

    if (r == null) return;

    final glow = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final stroke = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rr =
    RRect.fromRectAndRadius(r.inflate(2.0), Radius.circular(radius));
    canvas.drawRRect(rr, glow);
    canvas.drawRRect(rr, stroke);
  }

  void _drawRulerSelection(
      Canvas canvas, {
        required PreviewSection selectedSection,
        required Rect labelRect,
        required Rect gapRect,
        required double wMm,
        required double hMm,
        required double gMm,
        required double scale,
      }) {
    final baseY = labelRect.top - _gapFromLabelToRuler;
    final baseX = labelRect.left - _gapFromLabelToRuler;

    final glow = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    final stroke = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    void drawLineGlow(Offset a, Offset b) {
      canvas.drawLine(a, b, glow);
      canvas.drawLine(a, b, stroke);
    }

    if (selectedSection == PreviewSection.widthRuler) {
      drawLineGlow(
        Offset(labelRect.left, baseY),
        Offset(labelRect.right, baseY),
      );
      return;
    }

    if (selectedSection == PreviewSection.heightRuler) {
      drawLineGlow(
        Offset(baseX, labelRect.top),
        Offset(baseX, labelRect.bottom),
      );
      return;
    }

    if (selectedSection == PreviewSection.gap) {
      if (gMm <= 0.001 || gapRect.height <= 0.5) return;
      drawLineGlow(
        Offset(baseX, gapRect.top),
        Offset(baseX, gapRect.bottom),
      );
    }
  }

  void _drawMmRuler(
      Canvas canvas, {
        required Rect labelRect,
        required Rect gapRect,
        required double wMm,
        required double hMm,
        required double gMm,
        required double scale,
      }) {
    final tickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1;

    final baselinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..strokeWidth = 1.2;

    final rulerTextStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.55),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    final baseY = labelRect.top - _gapFromLabelToRuler;
    canvas.drawLine(
      Offset(labelRect.left, baseY),
      Offset(labelRect.right, baseY),
      baselinePaint,
    );

    final stepW = _niceStepMm(wMm);
    for (double mm = 0; mm <= wMm + 0.001; mm += stepW) {
      final x = labelRect.left + mm * scale;
      final isMajor = (mm % (stepW * 2) == 0);
      final len = isMajor ? _majorLen : _minorLen;
      canvas.drawLine(Offset(x, baseY), Offset(x, baseY - len), tickPaint);
    }

    final topMin = baseY + _innerTextPadding;
    final topMax = labelRect.top - _innerTextPadding;
    final centerY = (topMin + topMax) / 2;
    _drawCenteredText(
      canvas,
      Offset(labelRect.center.dx, centerY),
      '${wMm.toStringAsFixed(1)}mm',
      rulerTextStyle,
    );

    final baseX = labelRect.left - _gapFromLabelToRuler;
    canvas.drawLine(
      Offset(baseX, labelRect.top),
      Offset(baseX, labelRect.bottom),
      baselinePaint,
    );

    final stepH = _niceStepMm(hMm);
    for (double mm = 0; mm <= hMm + 0.001; mm += stepH) {
      final y = labelRect.top + mm * scale;
      final isMajor = (mm % (stepH * 2) == 0);
      final len = isMajor ? _majorLen : _minorLen;
      canvas.drawLine(Offset(baseX, y), Offset(baseX - len, y), tickPaint);
    }

    final leftMin = baseX + _innerTextPadding;
    final leftMax = labelRect.left - _innerTextPadding;
    final centerX = (leftMin + leftMax) / 2;

    _drawCenteredRotatedText(
      canvas,
      center: Offset(centerX, labelRect.center.dy),
      text: '${hMm.toStringAsFixed(1)}mm',
      style: rulerTextStyle,
      angleRad: math.pi / 2,
    );

    if (gMm > 0.001 && gapRect.height > 0.5) {
      canvas.drawLine(
        Offset(baseX, gapRect.top),
        Offset(baseX, gapRect.bottom),
        baselinePaint,
      );

      final stepG = _niceStepMm(gMm);
      for (double mm = 0; mm <= gMm + 0.001; mm += stepG) {
        final y = gapRect.top + mm * scale;
        final isMajor = (mm % (stepG * 2) == 0);
        final len = isMajor ? _majorLen : _minorLen;
        canvas.drawLine(Offset(baseX, y), Offset(baseX - len, y), tickPaint);
      }

      _drawCenteredRotatedText(
        canvas,
        center: Offset(centerX, gapRect.center.dy),
        text: '${gMm.toStringAsFixed(1)}mm',
        style: rulerTextStyle,
        angleRad: math.pi / 2,
      );
    }
  }

  double _niceStepMm(double lengthMm) {
    if (lengthMm <= 20) return 2;
    if (lengthMm <= 60) return 5;
    if (lengthMm <= 120) return 10;
    return 20;
  }

  void _drawCenteredText(
      Canvas canvas,
      Offset center,
      String text,
      TextStyle style,
      ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 999);

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawCenteredRotatedText(
      Canvas canvas, {
        required Offset center,
        required String text,
        required TextStyle style,
        required double angleRad,
      }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 999);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleRad);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _drawCenteredCaption(
      Canvas canvas,
      Rect rect,
      String text, {
        required Color color,
        required double fontSize,
        required FontWeight fontWeight,
      }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: rect.width - 6);

    final dx = rect.left + (rect.width - tp.width) / 2;
    final dy = rect.top + (rect.height - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawTextBlock(Canvas canvas, Rect rect, String main) {
    final base = math.max(12.0, math.min(16.0, rect.width / 12.0));
    final font = math.max(1.0, base * cfg.textScale);

    final styleMain = TextStyle(
      color: Colors.black.withValues(alpha: 0.85),
      fontSize: font,
      fontWeight: FontWeight.w800,
    );

    final tp = TextPainter(
      text: TextSpan(text: main, style: styleMain),
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0.0, rect.width));

    tp.paint(canvas, rect.topLeft);
  }

  void _drawDashedRect(
      Canvas canvas,
      Rect rect,
      Paint paint, {
        double dash = 6,
        double gap = 5,
      }) {
    _drawDashedLine(
      canvas,
      rect.topLeft,
      rect.topRight,
      paint,
      dash: dash,
      gap: gap,
    );
    _drawDashedLine(
      canvas,
      rect.topRight,
      rect.bottomRight,
      paint,
      dash: dash,
      gap: gap,
    );
    _drawDashedLine(
      canvas,
      rect.bottomRight,
      rect.bottomLeft,
      paint,
      dash: dash,
      gap: gap,
    );
    _drawDashedLine(
      canvas,
      rect.bottomLeft,
      rect.topLeft,
      paint,
      dash: dash,
      gap: gap,
    );
  }

  void _drawDashedLine(
      Canvas canvas,
      Offset a,
      Offset b,
      Paint paint, {
        double dash = 6,
        double gap = 5,
      }) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0.1) return;

    final ux = dx / dist;
    final uy = dy / dist;

    double t = 0;
    while (t < dist) {
      final t2 = math.min(t + dash, dist);
      canvas.drawLine(
        Offset(a.dx + ux * t, a.dy + uy * t),
        Offset(a.dx + ux * t2, a.dy + uy * t2),
        paint,
      );
      t += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant LabelPreviewPainter old) {
    return old.larguraMm != larguraMm ||
        old.alturaMm != alturaMm ||
        old.gapMm != gapMm ||
        old.text != text ||
        old.qrData != qrData ||
        old.selectedSection != selectedSection ||
        old.centerLogoMonoRot != centerLogoMonoRot ||
        old.cfg.padMm != cfg.padMm ||
        old.cfg.qrSidePctOfShort != cfg.qrSidePctOfShort ||
        old.cfg.textMaxLines != cfg.textMaxLines ||
        old.cfg.textScale != cfg.textScale ||
        old.cfg.enableQrCenterImage != cfg.enableQrCenterImage ||
        old.cfg.qrCenterImagePct != cfg.qrCenterImagePct ||
        old.cfg.qrCenterWhitePadMm != cfg.qrCenterWhitePadMm ||
        old.cfg.qrCenterCornerRadiusMm != cfg.qrCenterCornerRadiusMm ||
        old.cfg.qrCenterMonoThreshold != cfg.qrCenterMonoThreshold;
  }
}