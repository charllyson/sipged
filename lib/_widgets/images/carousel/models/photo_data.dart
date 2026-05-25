// lib/_widgets/images/carousel/models/photo_data.dart

import 'dart:typed_data';

import 'package:sipged/_widgets/images/carousel/services/photo_utils.dart';

enum PhotoDataSource {
  url,
  bytes,
}

class PhotoData {
  final String id;
  final String name;

  final String? url;
  final Uint8List? bytes;

  final DateTime? takenAt;
  final double? lat;
  final double? lng;

  /// Endereço resolvido a partir das coordenadas da própria foto.
  final String? address;

  /// Cidade resolvida a partir das coordenadas da própria foto.
  final String? city;

  /// Estado/UF resolvido a partir das coordenadas da própria foto.
  final String? state;

  final String? make;
  final String? model;
  final int? orientation;

  final int? uploadedAtMs;
  final String? uploadedBy;

  const PhotoData({
    required this.id,
    required this.name,
    this.url,
    this.bytes,
    this.takenAt,
    this.lat,
    this.lng,
    this.address,
    this.city,
    this.state,
    this.make,
    this.model,
    this.orientation,
    this.uploadedAtMs,
    this.uploadedBy,
  });

  factory PhotoData.fromUrl({
    required String id,
    required String name,
    required String url,
    DateTime? takenAt,
    double? lat,
    double? lng,
    String? address,
    String? city,
    String? state,
    String? make,
    String? model,
    int? orientation,
    int? uploadedAtMs,
    String? uploadedBy,
  }) {
    return PhotoData(
      id: id,
      name: name,
      url: url,
      takenAt: takenAt,
      lat: lat,
      lng: lng,
      address: address,
      city: city,
      state: state,
      make: make,
      model: model,
      orientation: orientation,
      uploadedAtMs: uploadedAtMs,
      uploadedBy: uploadedBy,
    );
  }

  factory PhotoData.fromBytes({
    required String id,
    required String name,
    required Uint8List bytes,
    DateTime? takenAt,
    double? lat,
    double? lng,
    String? address,
    String? city,
    String? state,
    String? make,
    String? model,
    int? orientation,
    int? uploadedAtMs,
    String? uploadedBy,
  }) {
    return PhotoData(
      id: id,
      name: name,
      bytes: bytes,
      takenAt: takenAt,
      lat: lat,
      lng: lng,
      address: address,
      city: city,
      state: state,
      make: make,
      model: model,
      orientation: orientation,
      uploadedAtMs: uploadedAtMs,
      uploadedBy: uploadedBy,
    );
  }

  PhotoDataSource get source {
    if (bytes != null) return PhotoDataSource.bytes;
    return PhotoDataSource.url;
  }

  bool get isBytes => bytes != null;

  bool get isUrl => url != null && url!.trim().isNotEmpty;

  bool get hasGps => lat != null && lng != null;

  bool get hasAddress {
    return (address?.trim().isNotEmpty ?? false) ||
        (city?.trim().isNotEmpty ?? false) ||
        (state?.trim().isNotEmpty ?? false);
  }

  bool get looksHeic {
    if (bytes != null) {
      return PhotoUtils.sniffFormat(bytes!) == ImgFmt.heic;
    }

    final cleanUrl = (url ?? '').split('?').first.toLowerCase();

    return cleanUrl.endsWith('.heic') || cleanUrl.endsWith('.heif');
  }

  PhotoData copyWith({
    String? id,
    String? name,
    String? url,
    Uint8List? bytes,
    DateTime? takenAt,
    double? lat,
    double? lng,
    String? address,
    String? city,
    String? state,
    String? make,
    String? model,
    int? orientation,
    int? uploadedAtMs,
    String? uploadedBy,
    bool clearUrl = false,
    bool clearBytes = false,
    bool clearTakenAt = false,
    bool clearLat = false,
    bool clearLng = false,
    bool clearAddress = false,
    bool clearCity = false,
    bool clearState = false,
    bool clearMake = false,
    bool clearModel = false,
    bool clearOrientation = false,
    bool clearUploadedAtMs = false,
    bool clearUploadedBy = false,
  }) {
    return PhotoData(
      id: id ?? this.id,
      name: name ?? this.name,
      url: clearUrl ? null : url ?? this.url,
      bytes: clearBytes ? null : bytes ?? this.bytes,
      takenAt: clearTakenAt ? null : takenAt ?? this.takenAt,
      lat: clearLat ? null : lat ?? this.lat,
      lng: clearLng ? null : lng ?? this.lng,
      address: clearAddress ? null : address ?? this.address,
      city: clearCity ? null : city ?? this.city,
      state: clearState ? null : state ?? this.state,
      make: clearMake ? null : make ?? this.make,
      model: clearModel ? null : model ?? this.model,
      orientation: clearOrientation ? null : orientation ?? this.orientation,
      uploadedAtMs: clearUploadedAtMs ? null : uploadedAtMs ?? this.uploadedAtMs,
      uploadedBy: clearUploadedBy ? null : uploadedBy ?? this.uploadedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (url != null) 'url': url,
      if (takenAt != null) 'takenAtMs': takenAt!.millisecondsSinceEpoch,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (orientation != null) 'orientation': orientation,
      if (uploadedAtMs != null) 'uploadedAtMs': uploadedAtMs,
      if (uploadedBy != null) 'uploadedBy': uploadedBy,
    };
  }

  static PhotoData fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }

      return DateTime.tryParse(value.toString());
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();

      return double.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();

      return int.tryParse(value.toString());
    }

    String? parseString(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    final id = map['id']?.toString() ??
        map['url']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();

    final name = map['name']?.toString() ?? 'foto.jpg';

    final takenAtRaw = map['takenAtMs'] ?? map['takenAt'];

    return PhotoData(
      id: id,
      name: name,
      url: parseString(map['url']),
      takenAt: parseDate(takenAtRaw),
      lat: parseDouble(map['lat']),
      lng: parseDouble(map['lng']),
      address: parseString(map['address']),
      city: parseString(map['city']),
      state: parseString(map['state']),
      make: parseString(map['make']),
      model: parseString(map['model']),
      orientation: parseInt(map['orientation']),
      uploadedAtMs: parseInt(map['uploadedAtMs']),
      uploadedBy: parseString(map['uploadedBy']),
    );
  }
}