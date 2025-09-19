import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';

class PolygonChanged {
  final Polygon polygon;
  final String title;
  final List<dynamic>? properties;
  final Map<String, Color>? mapColors;

  PolygonChanged({
    required this.polygon,
    required this.title,
    this.properties,
    this.mapColors,
  });
}
