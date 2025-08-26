import 'package:flutter_map/flutter_map.dart';

class PolygonChanged {
  final Polygon polygon;
  final String regionName;
  final List<dynamic>? properties;

  PolygonChanged({
    required this.polygon,
    required this.regionName,
    this.properties,
  });
}
