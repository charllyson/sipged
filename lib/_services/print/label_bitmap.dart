/*
// lib/_widgets/bluetooth/bitmap/label_bitmap.dart
// Gera a etiqueta como PNG para preview e como bitmap 1-bit (empacotado ROW-ALIGNED)
// usando EXATAMENTE o mesmo desenho (Canvas). Assim, preview == impresso.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

int _mmToPx(double mm, {int dpi = 203}) => (mm * dpi / 25.4).round();

class MonoBitmap {
  MonoBitmap(this.bytes, this.widthPx, this.heightPx);
  final Uint8List bytes;
  final int widthPx;
  final int heightPx;
}

/// Configuração de layout em mm para manter escala real.
class LabelLayoutConfig {
  const LabelLayoutConfig({
    this.padMm = 1.5,
    this.qrSideMm,
    this.qrSidePctOfShort = 0.85,
    this.textSizeMm = 2.8,
    this.textMaxLines = 3,
    this.spaceBetweenMm = 0.6,
    this.rotateTextClockwise = true,
    this.minTextBandMmForRow = 4.0, // NOVO: largura mínima p/ manter “em linha”
    this.forceRow = false,          // NOVO: força linha (mesmo que aperte)
    this.forceColumn = false,       // NOVO: força coluna (QR em cima, texto embaixo)
  });

  final double padMm;
  final double? qrSideMm;
  final double qrSidePctOfShort;
  final double textSizeMm;
  final int textMaxLines;
  final double spaceBetweenMm;
  final bool rotateTextClockwise;

  // Novos
  final double minTextBandMmForRow;
  final bool forceRow;
  final bool forceColumn;
}

/// Pinta o MESMO layout para preview (PNG) e para o bitmap 1-bit.
void _paintUnifiedLabel({
  required Canvas canvas,
  required Size canvasPx,
  required int dpi,
  required String texto,
  required String qrData,
  required LabelLayoutConfig cfg,
}) {
  final paintBg = Paint()..color = Colors.white;
  canvas.drawRect(Offset.zero & canvasPx, paintBg);

  final pad   = _mmToPx(cfg.padMm, dpi: dpi).toDouble();
  final space = _mmToPx(cfg.spaceBetweenMm, dpi: dpi).toDouble();
  final minBandPxForRow = _mmToPx(cfg.minTextBandMmForRow, dpi: dpi).toDouble();

  final content = Rect.fromLTWH(
    pad, pad,
    canvasPx.width - 2 * pad,
    canvasPx.height - 2 * pad,
  );

  // Tamanho do QR
  final double qrSidePx = (cfg.qrSideMm != null)
      ? _mmToPx(cfg.qrSideMm!, dpi: dpi).toDouble()
      : (math.min(content.width, content.height) * cfg.qrSidePctOfShort);

  // Heurística: tenta “em linha”; se a faixa ao lado do QR for pequena, cai para “coluna”.
  bool useRow = true;
  final rowTextBandPx = content.width - qrSidePx - space;
  if (cfg.forceColumn) {
    useRow = false;
  } else if (!cfg.forceRow) {
    useRow = rowTextBandPx >= minBandPxForRow;
  }

  // QR painter
  final qrPainter = QrPainter(
    data: qrData,
    gapless: true,
    version: QrVersions.auto,
    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  );

  // Texto (tamanho em mm → px)
  final fontPx = _mmToPx(cfg.textSizeMm, dpi: dpi).toDouble();
  final tp = TextPainter(
    text: TextSpan(
      text: texto,
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
  );

  if (useRow) {
    // ===== Layout EM LINHA: QR à esquerda + (espaço) + texto girado ao lado =====
    final qrRect = Rect.fromLTWH(content.left, content.top, qrSidePx, qrSidePx);
    final textRect = Rect.fromLTWH(
      qrRect.right + space,
      content.top,
      content.right - (qrRect.right + space),
      content.height,
    );

    // QR
    canvas.save();
    canvas.translate(qrRect.left, qrRect.top);
    qrPainter.paint(canvas, Size(qrRect.width, qrRect.height));
    canvas.restore();

    // Texto girado ocupa a ALTURA do textRect como largura útil
    if (cfg.rotateTextClockwise) {
      tp.layout(maxWidth: textRect.height);
      canvas.save();
      canvas.translate(textRect.left, textRect.bottom);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, const Offset(0, 0));
      canvas.restore();
    } else {
      tp.layout(maxWidth: textRect.width);
      tp.paint(canvas, Offset(textRect.left, textRect.top));
    }
  } else {
    // ===== Layout EM COLUNA: QR em cima + (espaço) + texto girado abaixo =====
    final qrRect = Rect.fromLTWH(
      content.left + (content.width - qrSidePx) / 2, // centraliza horizontalmente
      content.top,
      qrSidePx,
      qrSidePx,
    );
    final textRect = Rect.fromLTWH(
      content.left,
      qrRect.bottom + space,
      content.width,
      content.bottom - (qrRect.bottom + space),
    );

    // QR
    canvas.save();
    canvas.translate(qrRect.left, qrRect.top);
    qrPainter.paint(canvas, Size(qrRect.width, qrRect.height));
    canvas.restore();

    // Texto (girado) usando toda a altura do retângulo de texto
    if (cfg.rotateTextClockwise) {
      tp.layout(maxWidth: textRect.height);
      canvas.save();
      // ancora no canto inferior esquerdo do retângulo de texto
      canvas.translate(textRect.left, textRect.bottom);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, const Offset(0, 0));
      canvas.restore();
    } else {
      tp.layout(maxWidth: textRect.width);
      tp.paint(canvas, Offset(textRect.left, textRect.top));
    }
  }
}


/// ================= Preview PNG =================
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

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  _paintUnifiedLabel(
    canvas: canvas,
    canvasPx: Size(width.toDouble(), height.toDouble()),
    dpi: dpi,
    texto: texto,
    qrData: qrData,
    cfg: cfg,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Empacotador 1-bit ROW-ALIGNED (largura em bytes por linha),
/// compatível com ESC/POS raster e TSPL BITMAP.
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
      final bit = lum < threshold ? 1 : 0; // 1 = preto

      if (bit == 1) current |= (1 << bitPos);
      if (--bitPos < 0) {
        out[outIdx++] = current;
        current = 0;
        bitPos = 7;
      }
    }
    if (bitPos != 7) {
      out[outIdx++] = current;
    }
  }
  return out;
}

/// ================ Bitmap 1-bit para impressão ================
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

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  _paintUnifiedLabel(
    canvas: canvas,
    canvasPx: Size(width.toDouble(), height.toDouble()),
    dpi: dpi,
    texto: texto,
    qrData: qrData,
    cfg: cfg,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = byteData!.buffer.asUint8List();

  final mono = _packMonochromeRowAlignedFromRgba(
    rgba: rgba,
    width: width,
    height: height,
    threshold: threshold,
  );
  return MonoBitmap(mono, width, height);
}
*/
