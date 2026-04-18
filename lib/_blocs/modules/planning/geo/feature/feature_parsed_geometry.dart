
import 'package:latlong2/latlong.dart';

class FeatureParsedGeometry {
  final List<LatLng> markerPoints;
  final List<List<LatLng>> lineParts;
  final List<List<LatLng>> polygonRings;

  const FeatureParsedGeometry({
    this.markerPoints = const [],
    this.lineParts = const [],
    this.polygonRings = const [],
  });
}
