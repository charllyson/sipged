// lib/_blocs/modules/operation/photo_utils.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class PhotoUtils {
  static String sanitizeName(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');

  static String ensureJpgExtension(String name) {
    final idx = name.lastIndexOf('.');
    final base = (idx > 0) ? name.substring(0, idx) : name;
    return '$base.jpg';
  }

  static Future<Uint8List> readAll(Stream<List<int>> s) async {
    final bb = BytesBuilder(copy: false);
    await for (final chunk in s) {
      bb.add(chunk);
    }
    return bb.toBytes();
  }

  static Future<Uint8List> toJpegPreservingExif(Uint8List data) async {
    if (kIsWeb) return data; // plugin não suporta web
    try {
      final out = await FlutterImageCompress.compressWithList(
        data,
        quality: 95,
        format: CompressFormat.jpeg,
        keepExif: true,
      );
      return Uint8List.fromList(out);
    } catch (_) {
      return data;
    }
  }

  /// Converte para JPEG se necessário, extrai metadados, ajusta takenAt.
  static Future<({Uint8List bytes, String name, pm.CarouselMetadata meta})>
  convertAndExtract({
    required Uint8List original,
    required String originalName,
    DateTime? fallbackTakenAt,
  }) async {
    final safeName = sanitizeName(originalName.isNotEmpty ? originalName : 'foto');
    final fmt = pm.sniffFormat(original);
    Uint8List data = original;

    // Mobile: converte para JPEG se não for JPEG (mantendo EXIF)
    if (!kIsWeb && fmt != pm.ImgFmt.jpeg) {
      data = await toJpegPreservingExif(data);
    }

    String finalName = (fmt == pm.ImgFmt.jpeg) ? safeName : ensureJpgExtension(safeName);

    var meta = await pm.extractPhotoMetadata(data, debugLabel: finalName);
    meta = meta.copyWith(
      name: meta.name ?? finalName,
      takenAt: meta.takenAt ?? pm.parseDateFromFileName(finalName) ?? fallbackTakenAt,
    );

    return (bytes: data, name: finalName, meta: meta);
  }
}
