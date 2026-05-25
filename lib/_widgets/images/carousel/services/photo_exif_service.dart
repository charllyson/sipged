// lib/_widgets/images/carousel/services/photo_exif_service.dart

import 'dart:typed_data';

import 'package:exif/exif.dart' as exif;

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';

class PhotoExifService {
  const PhotoExifService._();

  static Future<PhotoData> extract(
      Uint8List bytes, {
        String? id,
        String? name,
      }) async {
    try {
      final tags = await exif.readExifFromBytes(bytes);

      DateTime? takenAt;

      final rawDate = <String>[
        'EXIF DateTimeOriginal',
        'EXIF DateTimeDigitized',
        'Image DateTime',
        'QuickTime CreateDate',
        'QuickTime MediaCreateDate',
      ]
          .map((key) => tags[key]?.toString())
          .firstWhere(
            (value) => value != null && value.trim().isNotEmpty,
        orElse: () => null,
      );

      if (rawDate != null) {
        takenAt = _parseExifDate(rawDate);
      }

      final lat = _dmsToDecimal(
        tags['GPS GPSLatitude'],
        tags['GPS GPSLatitudeRef'],
      );

      final lng = _dmsToDecimal(
        tags['GPS GPSLongitude'],
        tags['GPS GPSLongitudeRef'],
      );

      final make = _clean(tags['Image Make']?.toString());
      final model = _clean(tags['Image Model']?.toString());

      int? orientation;
      final orientationRaw = tags['Image Orientation']?.toString();

      if (orientationRaw != null && orientationRaw.trim().isNotEmpty) {
        final match = RegExp(r'(\d+)').firstMatch(orientationRaw);

        if (match != null) {
          orientation = int.tryParse(match.group(1)!);
        }
      }

      return PhotoData(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name ?? '',
        takenAt: takenAt,
        lat: lat,
        lng: lng,
        make: make,
        model: model,
        orientation: orientation,
      );
    } catch (_) {
      return PhotoData(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name ?? '',
      );
    }
  }

  static String? _clean(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    return text;
  }

  static DateTime? _parseExifDate(String value) {
    var text = value.trim();

    if (RegExp(r'^\d{4}:\d{2}:\d{2}').hasMatch(text)) {
      final date = text.substring(0, 10).replaceAll(':', '-');
      final rest = text.length > 10 ? text.substring(10).trim() : '';

      text = <String>[
        date,
        rest,
      ].where((e) => e.isNotEmpty).join(' ');
    }

    return DateTime.tryParse(text) ??
        DateTime.tryParse(text.replaceAll('Z', ''));
  }

  static double? _dmsToDecimal(dynamic tag, dynamic ref) {
    final values = _valuesFromTag(tag);

    if (values == null || values.length < 3) {
      return null;
    }

    double decimal = values[0] + values[1] / 60.0 + values[2] / 3600.0;

    final direction = (ref?.toString() ?? '').trim().toUpperCase();

    final isSouthOrWest =
        direction == 'S' ||
            direction == 'W' ||
            direction.startsWith('SOUTH') ||
            direction.startsWith('WEST') ||
            direction.contains(' S') ||
            direction.contains(' W');

    if (isSouthOrWest) {
      decimal = -decimal;
    }

    return decimal;
  }

  static List<double>? _valuesFromTag(dynamic tag) {
    try {
      final values = tag?.values;

      if (values is exif.IfdRatios) {
        return values.ratios
            .map<double>((ratio) => ratio.toDouble())
            .toList(growable: false);
      }

      if (values is List) {
        return values.map<double>(_parseNumber).toList(growable: false);
      }
    } catch (_) {}

    final text = tag?.toString();

    if (text is String && text.trim().isNotEmpty) {
      final normalized = text
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      if (normalized.contains(',')) {
        return normalized
            .split(',')
            .map<double>(_parseNumber)
            .toList(growable: false);
      }

      final matches = RegExp(r'[-+]?\d+(?:\.\d+)?(?:/\d+(?:\.\d+)?)?')
          .allMatches(normalized)
          .map((m) => m.group(0))
          .whereType<String>()
          .toList(growable: false);

      if (matches.length >= 3) {
        return matches.map<double>(_parseNumber).toList(growable: false);
      }
    }

    if (tag is List) {
      return tag.map<double>(_parseNumber).toList(growable: false);
    }

    return null;
  }

  static double _parseNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim();

    if (text.contains('/')) {
      final parts = text.split('/');

      final a = double.tryParse(parts[0].trim()) ?? 0.0;
      final b = double.tryParse(parts.length > 1 ? parts[1].trim() : '1') ?? 1.0;

      return b == 0 ? 0.0 : a / b;
    }

    return double.tryParse(text) ?? 0.0;
  }
}