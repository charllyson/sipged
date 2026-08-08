// lib/_widgets/images/carousel/services/photo_utils.dart

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_exif_service.dart';

enum ImgFmt {
  jpeg,
  png,
  webp,
  heic,
  gif,
  bmp,
  unknown,
}

class PhotoImageSize {
  const PhotoImageSize({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

class PhotoUtils {
  const PhotoUtils._();

  static String sanitizeName(String name) {
    final clean = name.trim();

    if (clean.isEmpty) return 'foto.jpg';

    return clean.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static String ensureJpgExtension(String name) {
    final clean = sanitizeName(name);

    final idx = clean.lastIndexOf('.');
    final base = idx > 0 ? clean.substring(0, idx) : clean;

    return '$base.jpg';
  }

  static ImgFmt sniffFormat(Uint8List bytes) {
    if (bytes.length >= 12) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return ImgFmt.jpeg;
      }

      const pngSig = <int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ];

      var isPng = true;

      for (int i = 0; i < 8; i++) {
        if (bytes[i] != pngSig[i]) {
          isPng = false;
          break;
        }
      }

      if (isPng) return ImgFmt.png;

      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final webp = String.fromCharCodes(bytes.sublist(8, 12));

      if (riff == 'RIFF' && webp == 'WEBP') {
        return ImgFmt.webp;
      }

      final box = String.fromCharCodes(bytes.sublist(4, 12)).toLowerCase();

      if (box.contains('heic') ||
          box.contains('heix') ||
          box.contains('hevc') ||
          box.contains('heim') ||
          box.contains('heif')) {
        return ImgFmt.heic;
      }

      final gif = String.fromCharCodes(bytes.sublist(0, 3));

      if (gif == 'GIF') {
        return ImgFmt.gif;
      }

      if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return ImgFmt.bmp;
      }
    }

    return ImgFmt.unknown;
  }

  static bool sniffIsHeic(Uint8List bytes) {
    return sniffFormat(bytes) == ImgFmt.heic;
  }

  static DateTime? parseDateFromFileName(String name) {
    final re1 = RegExp(
      r'(\d{4})[-_](\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})',
    );

    final m1 = re1.firstMatch(name);

    if (m1 != null) {
      return DateTime(
        int.parse(m1.group(1)!),
        int.parse(m1.group(2)!),
        int.parse(m1.group(3)!),
        int.parse(m1.group(4)!),
        int.parse(m1.group(5)!),
        int.parse(m1.group(6)!),
      );
    }

    final re2 = RegExp(r'(\d{8})[_-](\d{6})');
    final m2 = re2.firstMatch(name);

    if (m2 != null) {
      final date = m2.group(1)!;
      final time = m2.group(2)!;

      return DateTime(
        int.parse(date.substring(0, 4)),
        int.parse(date.substring(4, 6)),
        int.parse(date.substring(6, 8)),
        int.parse(time.substring(0, 2)),
        int.parse(time.substring(2, 4)),
        int.parse(time.substring(4, 6)),
      );
    }

    return null;
  }

  static Future<Uint8List> readAll(Stream<List<int>> stream) async {
    final bb = BytesBuilder(copy: false);

    await for (final chunk in stream) {
      bb.add(chunk);
    }

    return bb.toBytes();
  }

  static Future<Uint8List> toJpegPreservingExif(Uint8List data) async {
    if (kIsWeb) return data;

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

  static Future<PhotoImageSize?> readImageSize(Uint8List bytes) async {
    try {
      final decoded = await compute(_decodeImageSize, bytes);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> resizeForUpload(
      Uint8List bytes, {
        int maxSide = 1600,
        int quality = 82,
      }) async {
    if (bytes.isEmpty) return bytes;

    return compute(
      _resizeJpegWorker,
      _ResizeArgs(
        bytes: bytes,
        maxSide: maxSide,
        quality: quality,
      ),
    );
  }

  static Future<Uint8List> buildThumbnail(
      Uint8List bytes, {
        int maxSide = 360,
        int quality = 68,
      }) async {
    if (bytes.isEmpty) return bytes;

    return compute(
      _resizeJpegWorker,
      _ResizeArgs(
        bytes: bytes,
        maxSide: maxSide,
        quality: quality,
      ),
    );
  }

  static Future<PhotoData> buildPhotoDataFromBytes({
    required Uint8List original,
    required String originalName,
    String? id,
    DateTime? fallbackTakenAt,
    int? uploadedAtMs,
    String? uploadedBy,
    bool reduceForUpload = false,
    int uploadMaxSide = 1600,
    int uploadQuality = 82,
    bool stamped = false,
  }) async {
    final safeName = sanitizeName(
      originalName.trim().isNotEmpty ? originalName.trim() : 'foto.jpg',
    );

    final fmt = sniffFormat(original);

    Uint8List data = original;

    if (!kIsWeb && fmt != ImgFmt.jpeg) {
      data = await toJpegPreservingExif(data);
    }

    if (reduceForUpload) {
      data = await resizeForUpload(
        data,
        maxSide: uploadMaxSide,
        quality: uploadQuality,
      );
    }

    final finalName = ensureJpgExtension(safeName);

    final extracted = await PhotoExifService.extract(
      original,
      name: finalName,
    );

    final size = await readImageSize(data);

    return PhotoData.fromBytes(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: finalName,
      bytes: data,
      takenAt: extracted.takenAt ??
          parseDateFromFileName(finalName) ??
          fallbackTakenAt,
      lat: extracted.lat,
      lng: extracted.lng,
      make: extracted.make,
      model: extracted.model,
      orientation: extracted.orientation,
      width: size?.width,
      height: size?.height,
      sizeBytes: data.length,
      stamped: stamped,
      uploadedAtMs: uploadedAtMs,
      uploadedBy: uploadedBy,
    );
  }
}

class _ResizeArgs {
  const _ResizeArgs({
    required this.bytes,
    required this.maxSide,
    required this.quality,
  });

  final Uint8List bytes;
  final int maxSide;
  final int quality;
}

PhotoImageSize? _decodeImageSize(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);

  if (decoded == null) return null;

  return PhotoImageSize(
    width: decoded.width,
    height: decoded.height,
  );
}

Uint8List _resizeJpegWorker(_ResizeArgs args) {
  final decoded = img.decodeImage(args.bytes);

  if (decoded == null) return args.bytes;

  final baked = img.bakeOrientation(decoded);

  final maxSide = args.maxSide <= 0 ? 1600 : args.maxSide;

  final width = baked.width;
  final height = baked.height;

  final currentMax = width > height ? width : height;

  img.Image output = baked;

  if (currentMax > maxSide) {
    if (width >= height) {
      output = img.copyResize(
        baked,
        width: maxSide,
        interpolation: img.Interpolation.average,
      );
    } else {
      output = img.copyResize(
        baked,
        height: maxSide,
        interpolation: img.Interpolation.average,
      );
    }
  }

  final encoder = img.JpegEncoder(
    quality: args.quality.clamp(1, 100),
  );

  return Uint8List.fromList(encoder.encode(output));
}