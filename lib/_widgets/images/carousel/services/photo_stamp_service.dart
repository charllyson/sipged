// lib/_widgets/images/carousel/services/photo_stamp_service.dart

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';

class PhotoStampService {
  const PhotoStampService._();

  static Future<Uint8List> stampPhoto({
    required PhotoData photo,
  }) async {
    final bytes = photo.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw ArgumentError('A foto não possui bytes para carimbar.');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    final imagePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, width, height),
      Rect.fromLTWH(0, 0, width, height),
      imagePaint,
    );

    paintStampOnCanvas(
      canvas: canvas,
      visibleImageRect: Rect.fromLTWH(0, 0, width, height),
      scaleBase: math.min(width, height),
      photo: photo,
    );

    final picture = recorder.endRecording();

    final stampedImage = await picture.toImage(
      image.width,
      image.height,
    );

    final byteData = await stampedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    stampedImage.dispose();

    if (byteData == null) {
      throw StateError('Não foi possível gerar a imagem carimbada.');
    }

    return byteData.buffer.asUint8List();
  }

  /// Pintura visual do carimbo.
  ///
  /// Use este método para overlay em preview/galeria sem alterar os bytes.
  static void paintStampOnCanvas({
    required Canvas canvas,
    required Rect visibleImageRect,
    required double scaleBase,
    required PhotoData photo,
  }) {
    final rect = visibleImageRect;

    if (rect.width <= 0 || rect.height <= 0) return;

    final fontSize = (scaleBase * 0.030).clamp(12.0, 34.0).toDouble();
    final outerPadding = (scaleBase * 0.022).clamp(10.0, 28.0).toDouble();
    final innerPadding = (scaleBase * 0.016).clamp(8.0, 20.0).toDouble();
    final radius = (scaleBase * 0.018).clamp(8.0, 18.0).toDouble();

    final lines = stampLines(photo);

    final painter = TextPainter(
      text: TextSpan(
        text: lines.join('\n'),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.16,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.86),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
      maxLines: 4,
      ellipsis: '…',
    );

    painter.layout(
      minWidth: 0,
      maxWidth: rect.width * 0.68,
    );

    final stampWidth = painter.width + (innerPadding * 2);
    final stampHeight = painter.height + (innerPadding * 2);

    final left = (rect.right - stampWidth - outerPadding).clamp(
      rect.left + outerPadding,
      rect.right - stampWidth - outerPadding,
    );

    final top = (rect.bottom - stampHeight - outerPadding).clamp(
      rect.top + outerPadding,
      rect.bottom - stampHeight - outerPadding,
    );

    final stampRect = Rect.fromLTWH(
      left,
      top,
      stampWidth,
      stampHeight,
    );

    final shadowRRect = RRect.fromRectAndRadius(
      stampRect.shift(const Offset(0, 2)),
      Radius.circular(radius),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawRRect(shadowRRect, shadowPaint);

    final backgroundRRect = RRect.fromRectAndRadius(
      stampRect,
      Radius.circular(radius),
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.58);

    canvas.drawRRect(backgroundRRect, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (scaleBase * 0.002).clamp(0.8, 2.0).toDouble();

    canvas.drawRRect(backgroundRRect, borderPaint);

    painter.paint(
      canvas,
      Offset(
        stampRect.left + innerPadding,
        stampRect.top + innerPadding,
      ),
    );
  }

  static List<String> stampLines(PhotoData photo) {
    final address = photo.address?.trim();

    return <String>[
      _formatDate(photo.takenAt),
      _coordLine(photo),
      address == null || address.isEmpty ? 'Endereço não disponível' : address,
      _cityStateLine(photo),
    ];
  }

  static String _formatDate(DateTime? value) {
    final date = value ?? DateTime.now();

    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  static String _coordLine(PhotoData photo) {
    final lat = photo.lat;
    final lng = photo.lng;

    if (lat == null || lng == null) {
      return 'Sem coordenadas na foto';
    }

    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  static String _cityStateLine(PhotoData photo) {
    final city = photo.city?.trim() ?? '';
    final state = photo.state?.trim() ?? '';

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city - $state';
    }

    if (city.isNotEmpty) {
      return city;
    }

    if (state.isNotEmpty) {
      return state;
    }

    return 'Cidade não disponível';
  }
}