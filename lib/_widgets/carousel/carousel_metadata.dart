// lib/_datas/widgets/pickedPhoto/carousel_metadata.dart
import 'dart:typed_data';
import 'package:exif/exif.dart' as exif;
import 'package:flutter/foundation.dart';

/// Formatos básicos para sniff de bytes
enum ImgFmt { jpeg, png, webp, heic, gif, bmp, unknown }

ImgFmt sniffFormat(Uint8List bytes) {
  if (bytes.length >= 12) {
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return ImgFmt.jpeg;
    // PNG (assinatura 8 bytes)
    final pngSig = <int>[0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A];
    bool png = true;
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngSig[i]) { png = false; break; }
    }
    if (png) return ImgFmt.png;

    // WEBP "RIFF....WEBP"
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final webp = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff == 'RIFF' && webp == 'WEBP') return ImgFmt.webp;

    // HEIC/HEIF: "ftypheic", "heix", "hevc", "heim" próximo do offset 4
    final box = String.fromCharCodes(bytes.sublist(4, 12));
    if (box.contains('heic') || box.contains('heix') || box.contains('hevc') || box.contains('heim')) {
      return ImgFmt.heic;
    }

    // GIF
    final gif = String.fromCharCodes(bytes.sublist(0, 3));
    if (gif == 'GIF') return ImgFmt.gif;

    // BMP
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return ImgFmt.bmp;
  }
  return ImgFmt.unknown;
}

class CarouselMetadata {
  final String? url;          // (opcional) para itens já salvos
  final String? name;         // (opcional) nome do arquivo
  final DateTime? takenAt;
  final double? lat;
  final double? lng;
  final String? make;
  final String? model;
  final int? orientation;

  // extras úteis quando montamos via UI/Storage
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
    DateTime? _dt;
    final t = m['takenAt'] ?? m['takenAtMs'];
    if (t is int) _dt = DateTime.fromMillisecondsSinceEpoch(t);
    if (t is num) _dt = DateTime.fromMillisecondsSinceEpoch(t.toInt());

    double? _toDouble(x) {
      if (x == null) return null;
      if (x is num) return x.toDouble();
      return double.tryParse(x.toString());
    }

    int? _toInt(x) {
      if (x == null) return null;
      if (x is num) return x.toInt();
      return int.tryParse(x.toString());
    }

    return CarouselMetadata(
      url: m['url']?.toString(),
      name: m['name']?.toString(),
      takenAt: _dt,
      lat: _toDouble(m['lat']),
      lng: _toDouble(m['lng']),
      make: m['make']?.toString(),
      model: m['model']?.toString(),
      orientation: _toInt(m['orientation']),
      uploadedAtMs: _toInt(m['uploadedAtMs']),
      uploadedBy: m['uploadedBy']?.toString(),
    );
  }
}

/// Tenta extrair data/hora do nome do arquivo.
/// Exemplos aceitos:
/// - PHOTO-2024-02-02-21-28-07__1_.jpg
/// - 20240202_212807.jpg
DateTime? parseDateFromFileName(String name) {
  final re1 = RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})[-_](\d{2})');
  final m1 = re1.firstMatch(name);
  if (m1 != null) {
    final y = int.parse(m1.group(1)!);
    final mo = int.parse(m1.group(2)!);
    final d = int.parse(m1.group(3)!);
    final h = int.parse(m1.group(4)!);
    final mi = int.parse(m1.group(5)!);
    final s = int.parse(m1.group(6)!);
    return DateTime(y, mo, d, h, mi, s);
  }

  final re2 = RegExp(r'(\d{8})[_-](\d{6})');
  final m2 = re2.firstMatch(name);
  if (m2 != null) {
    final d1 = m2.group(1)!; // YYYYMMDD
    final d2 = m2.group(2)!; // HHMMSS
    return DateTime(
      int.parse(d1.substring(0,4)),
      int.parse(d1.substring(4,6)),
      int.parse(d1.substring(6,8)),
      int.parse(d2.substring(0,2)),
      int.parse(d2.substring(2,4)),
      int.parse(d2.substring(4,6)),
    );
  }
  return null;
}

/// Lê EXIF com logs e aplica heurísticas de orientação.
/// Se o arquivo não for JPEG, avisamos que EXIF pode não estar disponível.
Future<CarouselMetadata> extractPhotoMetadata(
    Uint8List bytes, {
      String? debugLabel,
    }) async {
  try {
    final fmt = sniffFormat(bytes);
    if (fmt != ImgFmt.jpeg && kDebugMode) {
    }

    final tags = await exif.readExifFromBytes(bytes);

    // ---------- Date ----------
    DateTime? takenAt;
    String? _rawDate = [
      'EXIF DateTimeOriginal',
      'EXIF DateTimeDigitized',
      'Image DateTime',
      'QuickTime CreateDate',
      'QuickTime MediaCreateDate',
    ].map((k) => tags[k]?.toString()).firstWhere(
          (v) => v != null && v.trim().isNotEmpty,
      orElse: () => null,
    );

    DateTime? _parseExifDate(String s) {
      var t = s.trim();
      if (RegExp(r'^\d{4}:\d{2}:\d{2}').hasMatch(t)) {
        final date = t.substring(0, 10).replaceAll(':', '-'); // YYYY-MM-DD
        final rest = t.length > 10 ? t.substring(10).trim() : '';
        t = [date, rest].where((x) => x.isNotEmpty).join(' ');
      }
      return DateTime.tryParse(t) ?? DateTime.tryParse(t.replaceAll('Z', ''));
    }

    if (_rawDate != null) {
      takenAt = _parseExifDate(_rawDate);
    }

    // ---------- GPS ----------
    List<double>? _valuesFromTag(dynamic tag) {
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
          }).toList();
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
        }).toList();
      }
      if (tag is List) {
        return tag.map<double>((e) {
          if (e is num) return e.toDouble();
          return double.tryParse(e.toString()) ?? 0.0;
        }).toList();
      }
      return null;
    }

    double? _dmsToDec(dynamic tag, dynamic ref) {
      final vals = _valuesFromTag(tag);
      if (vals == null || vals.length < 3) return null;
      double dec = vals[0] + (vals[1] / 60.0) + (vals[2] / 3600.0);
      final r = (ref?.toString() ?? '').toUpperCase();
      if (r == 'S' || r == 'W') dec = -dec;
      return dec;
    }

    final lat = _dmsToDec(tags['GPS GPSLatitude'], tags['GPS GPSLatitudeRef']);
    final lng = _dmsToDec(tags['GPS GPSLongitude'], tags['GPS GPSLongitudeRef']);

    // ---------- Make/Model ----------
    final make = tags['Image Make']?.toString();
    final model = tags['Image Model']?.toString();

    // ---------- Orientation ----------
    int? orientation;
    final oriRaw = tags['Image Orientation']?.toString();
    if (oriRaw != null && oriRaw.isNotEmpty) {
      final m = RegExp(r'(\d+)').firstMatch(oriRaw);
      if (m != null) orientation = int.tryParse(m.group(1)!);
    }

    final meta = CarouselMetadata(
      takenAt: takenAt,
      lat: lat,
      lng: lng,
      make: make,
      model: model,
      orientation: orientation,
    );

    return meta;
  } catch (e) {
    return const CarouselMetadata();
  }
}
