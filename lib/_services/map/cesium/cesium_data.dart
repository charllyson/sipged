import 'dart:convert';

/// Dados de um marcador utilizado no Cesium.
class CesiumData {
  final double lon;
  final double lat;
  final String? colorHex;
  final String? label;
  final String? idExtra;

  CesiumData({
    required this.lon,
    required this.lat,
    this.colorHex,
    this.label,
    this.idExtra,
  });

  Map<String, dynamic> toJson() => {
    'lon': lon,
    'lat': lat,
    'colorHex': colorHex,
    'label': label,
    'idExtra': idExtra,
  };

  factory CesiumData.fromJson(Map<String, dynamic> json) => CesiumData(
    lon: (json['lon'] as num).toDouble(),
    lat: (json['lat'] as num).toDouble(),
    colorHex: json['colorHex'] as String?,
    label: json['label'] as String?,
    idExtra: json['idExtra'] as String?,
  );

  String encode() => jsonEncode(toJson());
}
