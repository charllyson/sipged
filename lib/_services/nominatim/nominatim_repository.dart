

import 'dart:convert';

import 'package:extended_image/extended_image.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/nominatim/nominatim_data.dart';
import 'package:siged/_services/nominatim/nominatim_service.dart';

class NominatimRepository implements NominatimService {
  final String baseUrl;
  final String accessToken;
  final String language;
  final int limit;

  NominatimRepository({
    required this.baseUrl,
    required this.accessToken,
    required this.language,
    required this.limit,
  });

  @override
  Future<LatLng?> geocode(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      '$baseUrl/geocoding/v5/mapbox.places/$encoded.json'
          '?access_token=$accessToken'
          '&language=$language'
          '&limit=$limit',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = json.decode(res.body);
    final feats = data['features'];
    if (feats is List && feats.isNotEmpty) {
      final first = feats.first;
      final coords = first['geometry']?['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  @override
  Future<List<NominatimData>> search(String query, {int limit = 6}) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      '$baseUrl/geocoding/v5/mapbox.places/$encoded.json'
          '?access_token=$accessToken'
          '&language=$language'
          '&limit=$limit',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return const [];

    final data = json.decode(res.body);
    final feats = data['features'];
    if (feats is! List) return const [];

    final out = <NominatimData>[];
    for (final f in feats) {
      final placeName = f['place_name']?.toString() ?? f['text']?.toString() ?? 'Sem nome';
      final coords = f['geometry']?['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        out.add(
          NominatimData(
            id: (f['id'] ?? placeName).toString(),
            title: placeName,
            point: LatLng(lat, lon),
            // Mapbox traz contexto em "context" – opcional parse fino
            city: null,
            state: null,
            country: null,
          ),
        );
      }
    }
    return out;
  }
}
