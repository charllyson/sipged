import 'dart:typed_data';

import 'package:exif/exif.dart' as exif;
import 'package:flutter/foundation.dart';

enum ImgFmt { jpeg, png, webp, heic, gif, bmp, unknown }

ImgFmt sniffFormat(Uint8List bytes) {
  if (bytes.length >= 12) {
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return ImgFmt.jpeg;

    const pngSig = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    var png = true;
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngSig[i]) {
        png = false;
        break;
      }
    }
    if (png) return ImgFmt.png;

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final webp = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff == 'RIFF' && webp == 'WEBP') return ImgFmt.webp;

    final box = String.fromCharCodes(bytes.sublist(4, 12));
    if (box.contains('heic') ||
        box.contains('heix') ||
        box.contains('hevc') ||
        box.contains('heim')) {
      return ImgFmt.heic;
    }

    final gif = String.fromCharCodes(bytes.sublist(0, 3));
    if (gif == 'GIF') return ImgFmt.gif;

    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return ImgFmt.bmp;
  }

  return ImgFmt.unknown;
}

class CarouselMetadata {
  final String? url;
  final String? name;
  final DateTime? takenAt;
  final double? lat;
  final double? lng;
  final String? make;
  final String? model;
  final int? orientation;
  final int? uploadedAtMs;
  final String? uploadedBy;

  const CarouselMetadata({
    this.url,
    this.name,
    this.takenAt,
    this.lat,
    this.lng,
    this.make,
    this.model,
    this.orientation,
    this.uploadedAtMs,
    this.uploadedBy,
  });

  bool get hasGps => lat != null && lng != null;

  CarouselMetadata copyWith({
    String? url,
    String? name,
    DateTime? takenAt,
    double? lat,
    double? lng,
    String? make,
    String? model,
    int? orientation,
    int? uploadedAtMs,
    String? uploadedBy,
  }) {
    return CarouselMetadata(
      url: url ?? this.url,
      name: name ?? this.name,
      takenAt: takenAt ?? this.takenAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      make: make ?? this.make,
      model: model ?? this.model,
      orientation: orientation ?? this.orientation,
      uploadedAtMs: uploadedAtMs ?? this.uploadedAtMs,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }

  Map<String, dynamic> toMap() => {
    if (url != null) 'url': url,
    if (name != null) 'name': name,
    if (takenAt != null) 'takenAt': takenAt!.millisecondsSinceEpoch,
    if (takenAt != null) 'takenAtMs': takenAt!.millisecondsSinceEpoch,
    'lat': lat,
    'lng': lng,
    'make': make,
    'model': model,
    'orientation': orientation,
    if (uploadedAtMs != null) 'uploadedAtMs': uploadedAtMs,
    if (uploadedBy != null) 'uploadedBy': uploadedBy,
  };

  static CarouselMetadata fromMap(Map<String, dynamic> m) {
    DateTime? dt;
    final t = m['takenAt'] ?? m['takenAtMs'];
    if (t is int) dt = DateTime.fromMillisecondsSinceEpoch(t);
    if (t is num) dt = DateTime.fromMillisecondsSinceEpoch(t.toInt());

    double? toDouble(dynamic x) {
      if (x == null) return null;
      if (x is num) return x.toDouble();
      return double.tryParse(x.toString());
    }

    int? toInt(dynamic x) {
      if (x == null) return null;
      if (x is num) return x.toInt();
      return int.tryParse(x.toString());
    }

    return CarouselMetadata(
      url: m['url']?.toString(),
      name: m['name']?.toString(),
      takenAt: dt,
      lat: toDouble(m['lat']),
      lng: toDouble(m['lng']),
      make: m['make']?.toString(),
      model: m['model']?.toString(),
      orientation: toInt(m['orientation']),
      uploadedAtMs: toInt(m['uploadedAtMs']),
      uploadedBy: m['uploadedBy']?.toString(),
    );
  }
}

DateTime? parseDateFromFileName(String name) {
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
    final d1 = m2.group(1)!;
    final d2 = m2.group(2)!;
    return DateTime(
      int.parse(d1.substring(0, 4)),
      int.parse(d1.substring(4, 6)),
      int.parse(d1.substring(6, 8)),
      int.parse(d2.substring(0, 2)),
      int.parse(d2.substring(2, 4)),
      int.parse(d2.substring(4, 6)),
    );
  }

  return null;
}

Future<CarouselMetadata> extractPhotoMetadata(
    Uint8List bytes, {
      String? debugLabel,
    }) async {
  try {
    final tags = await exif.readExifFromBytes(bytes);

    DateTime? takenAt;
    final rawDate = [
      'EXIF DateTimeOriginal',
      'EXIF DateTimeDigitized',
      'Image DateTime',
      'QuickTime CreateDate',
      'QuickTime MediaCreateDate',
    ].map((k) => tags[k]?.toString()).firstWhere(
          (v) => v != null && v.trim().isNotEmpty,
      orElse: () => null,
    );

    DateTime? parseExifDate(String s) {
      var t = s.trim();
      if (RegExp(r'^\d{4}:\d{2}:\d{2}').hasMatch(t)) {
        final date = t.substring(0, 10).replaceAll(':', '-');
        final rest = t.length > 10 ? t.substring(10).trim() : '';
        t = [date, rest].where((x) => x.isNotEmpty).join(' ');
      }
      return DateTime.tryParse(t) ?? DateTime.tryParse(t.replaceAll('Z', ''));
    }

    if (rawDate != null) {
      takenAt = parseExifDate(rawDate);
    }

    List<double>? valuesFromTag(dynamic tag) {
      try {
        final v = tag?.values;
        if (v is List) {
          return v.map<double>((e) {
            if (e is num) return e.toDouble();
            final s = e.toString();
            if (s.contains('/')) {
              final p = s.split('/');
              final a = double.tryParse(p[0]) ?? 0.0;
              final b = double.tryParse(p[1]) ?? 1.0;
              return b == 0 ? 0.0 : a / b;
            }
            return double.tryParse(s) ?? 0.0;
          }).toList(growable: false);
        }
      } catch (_) {}

      final s = tag?.toString();
      if (s is String && s.contains(',')) {
        return s.split(',').map<double>((piece) {
          final t = piece.trim();
          if (t.contains('/')) {
            final p = t.split('/');
            final a = double.tryParse(p[0]) ?? 0.0;
            final b = double.tryParse(p[1]) ?? 1.0;
            return b == 0 ? 0.0 : a / b;
          }
          return double.tryParse(t) ?? 0.0;
        }).toList(growable: false);
      }

      if (tag is List) {
        return tag.map<double>((e) {
          if (e is num) return e.toDouble();
          return double.tryParse(e.toString()) ?? 0.0;
        }).toList(growable: false);
      }

      return null;
    }

    double? dmsToDec(dynamic tag, dynamic ref) {
      final vals = valuesFromTag(tag);
      if (vals == null || vals.length < 3) return null;

      double dec = vals[0] + (vals[1] / 60.0) + (vals[2] / 3600.0);
      final r = (ref?.toString() ?? '').toUpperCase();
      if (r == 'S' || r == 'W') dec = -dec;
      return dec;
    }

    final lat = dmsToDec(tags['GPS GPSLatitude'], tags['GPS GPSLatitudeRef']);
    final lng =
    dmsToDec(tags['GPS GPSLongitude'], tags['GPS GPSLongitudeRef']);

    final make = tags['Image Make']?.toString();
    final model = tags['Image Model']?.toString();

    int? orientation;
    final oriRaw = tags['Image Orientation']?.toString();
    if (oriRaw != null && oriRaw.isNotEmpty) {
      final m = RegExp(r'(\d+)').firstMatch(oriRaw);
      if (m != null) orientation = int.tryParse(m.group(1)!);
    }

    return CarouselMetadata(
      takenAt: takenAt,
      lat: lat,
      lng: lng,
      make: make,
      model: model,
      orientation: orientation,
    );
  } catch (_) {
    return const CarouselMetadata();
  }
}