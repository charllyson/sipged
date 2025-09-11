// lib/_widgets/archives/dxf/dxf_renderer.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dxf_model.dart';

class RenderResult {
  final ui.Image image;
  final Uint8List? rgba;
  final int w, h;
  final DxfModel model;
  final Matrix4 modelToImage;
  final Matrix4 imageToModel;

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
  static Future<RenderResult> renderDxf({
    required Uint8List dxfBytes,
    double hairlinePx = 0.9,
    double pad = 0.0,
  }) async {
    final text  = DxfModel.tryDecode(dxfBytes);
    final model = DxfModel.parseAscii(text);
    if (model.isEmpty) {
      throw Exception('DXF sem entidades suportadas (LINE, LWPOLYLINE, CIRCLE, ARC).');
    }

    final bb = model.bounds();
    final wUnits = bb.width  <= 0 ? 1e-6 : bb.width;
    final hUnits = bb.height <= 0 ? 1e-6 : bb.height;

    const desired = 3600.0;
    final scale = desired / (wUnits > hUnits ? wUnits : hUnits);

    final imgW = (wUnits * scale + pad * 2).ceil();
    final imgH = (hUnits * scale + pad * 2).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()),
      Paint()..color = const Color(0x00000000),
    );

    final modelToImage = Matrix4.identity()
      ..translate(pad, pad)
      ..scale(scale, scale)
      ..translate(-bb.left, -bb.top);

    final imageToModel = Matrix4.inverted(modelToImage);
    canvas.transform(modelToImage.storage);

    final px = hairlinePx.clamp(0.3, 2.0).toDouble();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (px / scale).toDouble()
      ..color = Colors.black;

    model.drawOn(canvas, stroke);

    final picture = recorder.endRecording();
    final img = await picture.toImage(imgW, imgH);

    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final view = bd?.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);

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
