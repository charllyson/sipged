

import 'dart:convert';

import 'package:extended_image/extended_image.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/map/map_box/service/nominatim_data.dart';
import 'package:siged/_services/map/map_box/service/nominatim_service.dart';

class NominatimGeocoder implements NominatimService {
  final String baseUrl;
  final String userAgent;
  final String acceptLanguage;
  final String countryCodes;
  final int limit;

  NominatimGeocoder({
    required this.baseUrl,
    required this.userAgent,
    required this.acceptLanguage,
    required this.countryCodes,
    required this.limit,
  });

  @override
  Future<LatLng?> geocode(String query) async {
    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'limit': '$limit',
      if (acceptLanguage.isNotEmpty) 'accept-language': acceptLanguage,
      if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
    });

    final res = await http.get(uri, headers: {
      'User-Agent': userAgent, // **OBRIGATÓRIO** no Nominatim
    });

    if (res.statusCode != 200) return null;
    final data = json.decode(res.body);
    if (data is List && data.isNotEmpty) {
      final item = data.first;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat != null && lon != null) return LatLng(lat, lon);
    }
    return null;
  }

  @override
  Future<List<NominatimData>> search(String query, {int limit = 6}) async {
    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '$limit',
      if (acceptLanguage.isNotEmpty) 'accept-language': acceptLanguage,
      if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
    });

    final res = await http.get(uri, headers: {
      'User-Agent': userAgent, // **OBRIGATÓRIO**
    });

    if (res.statusCode != 200) return const [];

    final data = json.decode(res.body);
    if (data is! List) return const [];

    final out = <NominatimData>[];
    for (final m in data) {
      final lat = double.tryParse(m['lat']?.toString() ?? '');
      final lon = double.tryParse(m['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final addr = (m['address'] is Map) ? (m['address'] as Map) : null;
      out.add(
        NominatimData(
          id: (m['place_id'] ?? m['osm_id'] ?? m['display_name']).toString(),
          title: (m['display_name']?.toString() ?? 'Sem nome'),
          point: LatLng(lat, lon),
          city: addr?['city']?.toString() ??
              addr?['town']?.toString() ??
              addr?['village']?.toString(),
          state: addr?['state']?.toString(),
          country: addr?['country']?.toString(),
        ),
      );
    }
    return out;
  }
}