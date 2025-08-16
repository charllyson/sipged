import 'package:flutter_map/flutter_map.dart';

class RegionalPolygon {
  final Polygon polygon;
  final String regionName;
  final List<dynamic>? properties;

  RegionalPolygon({
    required this.polygon,
    required this.regionName,
    this.properties,
  });
}
