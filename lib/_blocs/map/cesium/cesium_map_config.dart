import 'package:siged/_blocs/map/cesium/cesium_data.dart';

class CesiumMapConfig {
  final String accessToken;
  final double lon;
  final double lat;
  final double height;
  final List<CesiumData> markers;

  const CesiumMapConfig({
    required this.accessToken,
    required this.lon,
    required this.lat,
    required this.height,
    required this.markers,
  });

  Map<String, dynamic> toJsonForHtml() => {
    'accessToken': accessToken,
    'lon': lon,
    'lat': lat,
    'height': height,
    'markers': markers.map((m) => m.toJson()).toList(),
  };
}
