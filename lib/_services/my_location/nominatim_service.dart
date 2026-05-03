// lib/_services/map/map_box/service/nominatim_service.dart

import 'package:latlong2/latlong.dart';

import 'nominatim_data.dart';

abstract class NominatimService {
  Future<LatLng?> geocode(String query);

  Future<List<NominatimData>> search(
      String query, {
        int limit = 6,
      });
}