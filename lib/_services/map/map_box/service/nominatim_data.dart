// lib/_services/map/map_box/service/nominatim_data.dart

import 'package:latlong2/latlong.dart';

class NominatimData {
  final String id;
  final String title;
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