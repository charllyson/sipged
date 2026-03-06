// lib/_services/print/label_bitmap.dart
// Render unificado: PNG preview + bitmap 1-bit (row-aligned) para impressão térmica.
// Inclui logo central no QR: rotacionado 90° para direita e BINARIZADO (monocromático).
//
// ✅ Ajuste principal: logo central dentro de container branco com padding FIXO em mm (bem pequeno),
// ocupando praticamente todo o espaço.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

int _mmToPx(double mm, {int dpi = 203}) => (mm * dpi / 25.4).round();
int _idx(int x, int y, int w) => (y * w + x) * 4;

class MonoBitmap {
  MonoBitmap(this.bytes, this.widthPx, this.heightPx);
  final Uint8List bytes;
  final int widthPx;
  final int heightPx;
}

class LabelLayoutConfig {
  const LabelLayoutConfig({
    this.padMm = 1.5,
    this.qrSideMm,
    this.qrSidePctOfShort = 0.85,
    this.textSizeMm = 2.8,
    this.textMaxLines = 3,
    this.spaceBetweenMm = 0.6,
    this.rotateTextClockwise = false,

    this.matchPreviewTextSizing = true,
    this.previewFontMinPx = 12,
    this.previewFontMaxPx = 16,
    this.textScale = 1.0,

    // ===== Logo no centro do QR =====
    this.enableQrCenterImage = true,
    this.qrCenterAssetPath = 'assets/logos/sipged/sipged-mono.png',

    /// tamanho do logo (proporção do lado do QR)
    this.qrCenterImagePct = 0.28,

    // ⚠️ campos antigos (mantidos só por compatibilidade; NÃO usados no desenho principal)
    this.qrCenterWhitePadPct = 0.16,
    this.qrCenterCornerRadiusPct = 0.18,

    /// ✅ NOVO: padding fixo do cartão branco (mm) — NÃO cresce com o logo
    /// Ex.: 0.10 ~ 0.30mm
    this.qrCenterWhitePadMm = 0.15,

    /// ✅ NOVO: raio fixo (mm)
    this.qrCenterCornerRadiusMm = 0.35,

    /// ✅ Threshold do logo (binarização 1-bit).
    /// Maior => mais pixels viram preto.
    this.qrCenterMonoThreshold = 150,
  });

  final double padMm;
  final double? qrSideMm;
  final double qrSidePctOfShort;

  final double textSizeMm;
  final int textMaxLines;
  final double spaceBetweenMm;

  final bool rotateTextClockwise;

  final bool matchPreviewTextSizing;
  final double previewFontMinPx;
  final double previewFontMaxPx;
  final double textScale;

  final bool enableQrCenterImage;
  final String qrCenterAssetPath;

  final double qrCenterImagePct;

  // legacy (não usado no fluxo refatorado)
  final double qrCenterWhitePadPct;
  final double qrCenterCornerRadiusPct;

  final double qrCenterWhitePadMm;
  final double qrCenterCornerRadiusMm;

  final int qrCenterMonoThreshold;
}

/// fontSize = clamp(min,max, rect.width/12)
double _fontPxLikePreview(Rect rect, LabelLayoutConfig cfg) {
  final raw = rect.width / 12.0;
  return math.max(cfg.previewFontMinPx, math.min(cfg.previewFontMaxPx, raw));
}

// ============================================================================
// ✅ Logo: BINARIZA (PB puro) + ROTACIONA 90° (direita) + CACHE
// ============================================================================

ui.Image? _cachedLogoMonoRot;
Future<ui.Image?>? _cachedLogoMonoRotFuture;
String? _cachedLogoKeyPath;
int? _cachedLogoKeyThr;

Future<ui.Image?> _loadLogoMonoRot90FromAsset(
    String assetPath, {
      required int threshold,
    }) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final img = frame.image;

  final w = img.width;
  final h = img.height;

  final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bd == null) return null;
  final rgba = bd.buffer.asUint8List();

  // rot 90° horário => outW = h, outH = w
  final outW = h;
  final outH = w;
  final out = Uint8List(outW * outH * 4);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = _idx(x, y, w);
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final a = rgba[i + 3];

      // destino (rx,ry) = (h-1-y, x)
      final rx = h - 1 - y;
      final ry = x;
      final oi = _idx(rx, ry, outW);

      if (a < 10) {
        out[oi] = 0;
        out[oi + 1] = 0;
        out[oi + 2] = 0;
        out[oi + 3] = 0;
        continue;
      }

      final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
      final isBlack = lum < threshold;

      out[oi] = isBlack ? 0 : 255;
      out[oi + 1] = isBlack ? 0 : 255;
      out[oi + 2] = isBlack ? 0 : 255;
      out[oi + 3] = 255;
    }
  }

  final comp = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    out,
    outW,
    outH,
    ui.PixelFormat.rgba8888,
        (ui.Image result) => comp.complete(result),
  );
  return comp.future;
}

Future<ui.Image?> getQrCenterLogoMonoRot(LabelLayoutConfig cfg) {
  if (!cfg.enableQrCenterImage) return Future.value(null);

  final path = cfg.qrCenterAssetPath.trim();
  if (path.isEmpty) return Future.value(null);

  final thr = cfg.qrCenterMonoThreshold;

  if (_cachedLogoKeyPath == path && _cachedLogoKeyThr == thr && _cachedLogoMonoRot != null) {
    return Future.value(_cachedLogoMonoRot);
  }
  if (_cachedLogoKeyPath == path && _cachedLogoKeyThr == thr && _cachedLogoMonoRotFuture != null) {
    return _cachedLogoMonoRotFuture!;
  }

  _cachedLogoKeyPath = path;
  _cachedLogoKeyThr = thr;

  _cachedLogoMonoRotFuture = _loadLogoMonoRot90FromAsset(path, threshold: thr).then((img) {
    _cachedLogoMonoRot = img;
    return img;
  }).catchError((_) => null);

  return _cachedLogoMonoRotFuture!;
}

// ============================================================================
// ✅ Helpers de desenho do logo central
// ============================================================================

void _drawQrCenterLogo({
  required Canvas canvas,
  required Rect qrLocalRect, // coordenadas LOCAIS do QR (ex.: 0..qrW)
  required int dpi,
  required LabelLayoutConfig cfg,
  required ui.Image logoMonoRot,
}) {
  final side = (qrLocalRect.width * cfg.qrCenterImagePct).clamp(qrLocalRect.width * 0.10, qrLocalRect.width * 0.35);
  final center = qrLocalRect.center;

  final logoRect = Rect.fromCenter(center: center, width: side, height: side);

  // ✅ padding fixo em mm (bem pequeno)
  final whitePadPx = _mmToPx(cfg.qrCenterWhitePadMm, dpi: dpi).toDouble().clamp(0.0, side * 0.25);
  final whiteRect = logoRect.inflate(whitePadPx);

  // ✅ raio fixo em mm
  final radiusPx = _mmToPx(cfg.qrCenterCornerRadiusMm, dpi: dpi).toDouble().clamp(0.0, whiteRect.shortestSide / 2);

  canvas.drawRRect(
    RRect.fromRectAndRadius(whiteRect, Radius.circular(radiusPx)),
    Paint()..color = Colors.white,
  );

  final src = Rect.fromLTWH(0, 0, logoMonoRot.width.toDouble(), logoMonoRot.height.toDouble());
  final fit = applyBoxFit(BoxFit.contain, src.size, logoRect.size);
  final srcSub = Alignment.center.inscribe(fit.source, src);
  final dstSub = Alignment.center.inscribe(fit.destination, logoRect);

  final p = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  canvas.drawImageRect(logoMonoRot, srcSub, dstSub, p);
}

// ============================================================================
// ✅ Render unificado
// ============================================================================

void _paintUnifiedLabel({
  required Canvas canvas,
  required Size canvasPx,
  required int dpi,
  required String texto,
  required String qrData,
  required LabelLayoutConfig cfg,
  ui.Image? centerLogoMonoRot,
}) {
  canvas.drawRect(Offset.zero & canvasPx, Paint()..color = Colors.white);

  final pad = _mmToPx(cfg.padMm, dpi: dpi).toDouble();
  final space = _mmToPx(cfg.spaceBetweenMm, dpi: dpi).toDouble();

  final content = Rect.fromLTWH(
    pad,
    pad,
    canvasPx.width - pad * 2,
    canvasPx.height - pad * 2,
  );

  final shortSide = math.min(content.width, content.height);

  final qrSidePx = cfg.qrSideMm != null
      ? _mmToPx(cfg.qrSideMm!, dpi: dpi).toDouble()
      : shortSide * cfg.qrSidePctOfShort;

  final qrRectRight = Rect.fromLTWH(
    content.right - qrSidePx,
    content.top + (content.height - qrSidePx) / 2,
    qrSidePx,
    qrSidePx,
  );

  final textW = math.max(0.0, (qrRectRight.left - space) - content.left);

  final tmpTextRectForSizing = Rect.fromLTWH(
    content.left,
    content.top,
    math.max(1, textW),
    content.height,
  );

  final approxBase = cfg.matchPreviewTextSizing
      ? _fontPxLikePreview(tmpTextRectForSizing, cfg)
      : _mmToPx(cfg.textSizeMm, dpi: dpi).toDouble();

  final approxFontPx = math.max(1.0, approxBase * cfg.textScale);
  final minTextW = math.max(8.0, approxFontPx * 1.8);
  final useVerticalStack = textW < minTextW;

  late final Rect qrRect;
  late final Rect textRect;

  if (!useVerticalStack) {
    qrRect = qrRectRight;
    textRect = Rect.fromLTWH(content.left, content.top, textW, content.height);
  } else {
    final qrRectBottom = Rect.fromLTWH(
      content.left + (content.width - qrSidePx) / 2,
      content.bottom - qrSidePx,
      qrSidePx,
      qrSidePx,
    );
    final textH = math.max(0.0, (qrRectBottom.top - space) - content.top);
    qrRect = qrRectBottom;
    textRect = Rect.fromLTWH(content.left, content.top, content.width, textH);
  }

  // ===== QR =====
  final safeQr = (qrData.trim().isEmpty) ? ' ' : qrData.trim();
  final ecc = (cfg.enableQrCenterImage && centerLogoMonoRot != null)
      ? QrErrorCorrectLevel.H
      : QrErrorCorrectLevel.M;

  final qrPainter = QrPainter(
    data: safeQr,
    version: QrVersions.auto,
    gapless: true,
    color: Colors.black,
    emptyColor: Colors.white,
    errorCorrectionLevel: ecc,
  );

  canvas.save();
  canvas.translate(qrRect.left, qrRect.top);
  qrPainter.paint(canvas, Size(qrRect.width, qrRect.height));

  // ✅ Logo PB no centro + cartão branco COM padding FIXO (mm)
  if (cfg.enableQrCenterImage && centerLogoMonoRot != null) {
    _drawQrCenterLogo(
      canvas: canvas,
      qrLocalRect: Rect.fromLTWH(0, 0, qrRect.width, qrRect.height),
      dpi: dpi,
      cfg: cfg,
      logoMonoRot: centerLogoMonoRot,
    );
  }

  canvas.restore();

  // ===== TEXTO =====
  if (textRect.width <= 1 || textRect.height <= 1) return;

  final baseFontPx = cfg.matchPreviewTextSizing
      ? _fontPxLikePreview(textRect, cfg)
      : _mmToPx(cfg.textSizeMm, dpi: dpi).toDouble();

  final fontPx = math.max(1.0, baseFontPx * cfg.textScale);
  final maxW = cfg.rotateTextClockwise ? textRect.height : textRect.width;

  final tp = TextPainter(
    text: TextSpan(
      text: (texto.isEmpty ? ' ' : texto),
      style: TextStyle(
        color: Colors.black,
        fontSize: fontPx,
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: cfg.textMaxLines,
    ellipsis: '…',
  )..layout(maxWidth: math.max(0.0, maxW));

  if (!cfg.rotateTextClockwise) {
    tp.paint(canvas, Offset(textRect.left, textRect.top));
    return;
  }

  canvas.save();
  canvas.translate(textRect.left, textRect.top);
  canvas.translate(textRect.width, 0);
  canvas.rotate(math.pi / 2);
  tp.paint(canvas, Offset.zero);
  canvas.restore();
}

Future<Uint8List> renderLabelPng({
  required double larguraMm,
  required double alturaMm,
  required String texto,
  required String qrData,
  int dpi = 203,
  LabelLayoutConfig cfg = const LabelLayoutConfig(),
}) async {
  final width = _mmToPx(larguraMm, dpi: dpi);
  final height = _mmToPx(alturaMm, dpi: dpi);

  final logo = await getQrCenterLogoMonoRot(cfg);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  _paintUnifiedLabel(
    canvas: canvas,
    canvasPx: Size(width.toDouble(), height.toDouble()),
    dpi: dpi,
    texto: texto,
    qrData: qrData,
    cfg: cfg,
    centerLogoMonoRot: logo,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Uint8List _packMonochromeRowAlignedFromRgba({
  required Uint8List rgba,
  required int width,
  required int height,
  int threshold = 128,
}) {
  final widthBytes = (width + 7) >> 3;
  final out = Uint8List(widthBytes * height);

  int rgbaIdx = 0;
  int outIdx = 0;

  for (int y = 0; y < height; y++) {
    int current = 0;
    int bitPos = 7;

    for (int x = 0; x < width; x++) {
      final r = rgba[rgbaIdx];
      final g = rgba[rgbaIdx + 1];
      final b = rgba[rgbaIdx + 2];
      rgbaIdx += 4;

      final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
      final bit = lum < threshold ? 1 : 0;

      if (bit == 1) current |= (1 << bitPos);

      if (--bitPos < 0) {
        out[outIdx++] = current;
        current = 0;
        bitPos = 7;
      }
    }

    if (bitPos != 7) out[outIdx++] = current;
  }

  return out;
}

Future<MonoBitmap> renderLabelMonoPackedRowAligned({
  required double larguraMm,
  required double alturaMm,
  required String texto,
  required String qrData,
  int dpi = 203,
  int threshold = 128,
  LabelLayoutConfig cfg = const LabelLayoutConfig(),
}) async {
  final width = _mmToPx(larguraMm, dpi: dpi);
  final height = _mmToPx(alturaMm, dpi: dpi);

  final logo = await getQrCenterLogoMonoRot(cfg);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  _paintUnifiedLabel(
    canvas: canvas,
    canvasPx: Size(width.toDouble(), height.toDouble()),
    dpi: dpi,
    texto: texto,
    qrData: qrData,
    cfg: cfg,
    centerLogoMonoRot: logo,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  final mono = _packMonochromeRowAlignedFromRgba(
    rgba: byteData!.buffer.asUint8List(),
    width: width,
    height: height,
    threshold: threshold,
  );

  return MonoBitmap(mono, width, height);
}