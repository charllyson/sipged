
import 'package:latlong2/latlong.dart';

/// Sugestão rica (para search)
class NominatimData {
  final String id;
  final String title;      // display_name / place_name
  final LatLng point;
  final String? city;
  final String? state;
  final String? country;

  const NominatimData({
    required this.id,
    required this.title,
    required this.point,
    this.city,
    this.state,
    this.country,
  });
}