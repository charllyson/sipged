import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'dxf_model.dart';

class RenderResult {
  final ui.Image image;
  final Uint8List? rgba; // RGBA da imagem (opcional)
  final int w, h; // dimensões finais em px
  final DxfModel model; // modelo vetorial parseado
  final Matrix4 modelToImage; // transforma ponto do MODELO → IMAGEM (px)
  final Matrix4 imageToModel; // inversa (IMAGEM → MODELO)

  const RenderResult({
    required this.image,
    required this.rgba,
    required this.w,
    required this.h,
    required this.model,
    required this.modelToImage,
    required this.imageToModel,
  });
}

class RenderService {
  /// Renderiza um DXF ASCII em imagem com traço fino.
  ///
  /// [dxfBytes]  : conteúdo do DXF (ASCII/ANSI/UTF-8/latin1 — autodetect)
  /// [hairlinePx]: espessura do traço percebida na tela (em px), ex.: 0.9
  /// [desiredLongest]: maior lado (w/h) da imagem em px (define resolução)
  /// [pad]       : padding em px ao redor do conteúdo (antes do fit)
  /// [strokeColor]: cor do traço (default: preto)
  /// [backgroundColor]: fundo da imagem (default: transparente)
  static Future<RenderResult> renderDxf({
    required Uint8List dxfBytes,
    double hairlinePx = 0.9,
    double desiredLongest = 3600.0,
    double pad = 0.0,
    Color strokeColor = Colors.black,
    Color backgroundColor = const Color(0x00000000),
  }) async {
    // 1) Parse
    final text = DxfModel.tryDecode(dxfBytes);
    final model = DxfModel.parseAscii(text);

    if (model.isEmpty) {
      throw Exception(
        'DXF sem entidades suportadas (LINE, LWPOLYLINE, CIRCLE, ARC).',
      );
    }

    // 2) Bounds do modelo
    final bb = model.bounds();
    final wUnits = bb.width <= 0 ? 1e-6 : bb.width;
    final hUnits = bb.height <= 0 ? 1e-6 : bb.height;

    // 3) Escala para caber no desiredLongest
    final longestUnits = (wUnits > hUnits) ? wUnits : hUnits;
    final scale = (desiredLongest <= 0 ? 1.0 : (desiredLongest / longestUnits))
        .clamp(0.0001, 1e9);

    // 4) Tamanho final da imagem (px) + padding
    final imgW = (wUnits * scale + pad * 2).ceil().clamp(1, 32768);
    final imgH = (hUnits * scale + pad * 2).ceil().clamp(1, 32768);

    // 5) Canvas / PictureRecorder
    final recorder = ui.PictureRecorder();
    final canvasBounds = Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble());
    final canvas = Canvas(recorder, canvasBounds);

    // Fundo
    canvas.drawRect(
      canvasBounds,
      Paint()..color = backgroundColor,
    );

    // 6) Matriz MODELO→IMAGEM
    final modelToImage = Matrix4.identity()
      ..translateByDouble(pad, pad, 0, 1)
      ..scaleByDouble(scale.toDouble(), scale.toDouble(), 1, 1)
      ..translateByDouble(-bb.left, -bb.top, 0, 1);

    final imageToModel = Matrix4.inverted(modelToImage);

    // Aplica transformação no canvas
    canvas.transform(modelToImage.storage);

    // 7) Stroke fino: converte hairlinePx da tela para espaço do MODELO
    //    Como não temos DPI/zoom de tela aqui, usamos aproximação pelo scale
    final px = hairlinePx.clamp(0.3, 2.0).toDouble();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (px / scale).toDouble()
      ..color = strokeColor;

    // 8) Desenha modelo
    model.drawOn(canvas, stroke);

    // 9) Exporta picture → image
    final picture = recorder.endRecording();
    final img = await picture.toImage(imgW, imgH);

    // 10) RGBA opcional
    Uint8List? view;
    try {
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      view = bd?.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
    } catch (_) {
      // Alguns targets podem não suportar RAW RGBA — ignore e siga só com ui.Image
      view = null;
    }

    return RenderResult(
      image: img,
      rgba: view != null ? Uint8List.fromList(view) : null,
      w: img.width,
      h: img.height,
      model: model,
      modelToImage: modelToImage,
      imageToModel: imageToModel,
    );
  }
}