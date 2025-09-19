import 'package:latlong2/latlong.dart';

// ---------------- modelos internos ----------------
enum GeometryType { line, polygon }

class Geom {
  final GeometryType type;
  final List<LatLng> points;

  const Geom._(this.type, this.points);
  factory Geom.line(List<LatLng> pts) => Geom._(GeometryType.line, pts);
  factory Geom.polygon(List<LatLng> pts) => Geom._(GeometryType.polygon, pts);
}
