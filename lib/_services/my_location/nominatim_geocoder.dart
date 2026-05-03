// lib/_services/map/map_box/service/nominatim_geocoder.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'nominatim_data.dart';
import 'nominatim_service.dart';

class NominatimGeocoder implements NominatimService {
  final String baseUrl;
  final String userAgent;
  final String acceptLanguage;
  final String countryCodes;
  final int defaultLimit;

  const NominatimGeocoder({
    this.baseUrl = 'https://nominatim.openstreetmap.org',
    required this.userAgent,
    this.acceptLanguage = 'pt-BR',
    this.countryCodes = 'br',
    this.defaultLimit = 6,
  });

  Map<String, String> get _headers {
    return {
      'User-Agent': userAgent,
      'Accept': 'application/json',
    };
  }

  @override
  Future<LatLng?> geocode(String query) async {
    final text = query.trim();

    if (text.isEmpty) return null;

    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {
        'q': text,
        'format': 'jsonv2',
        'limit': '1',
        if (acceptLanguage.isNotEmpty) 'accept-language': acceptLanguage,
        if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
      },
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);

    if (decoded is! List || decoded.isEmpty) return null;

    final first = decoded.first;

    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');

    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }

  @override
  Future<List<NominatimData>> search(
      String query, {
        int limit = 6,
      }) async {
    final text = query.trim();

    if (text.isEmpty) return const <NominatimData>[];

    final uri = Uri.parse('$baseUrl/search').replace(
      queryParameters: {
        'q': text,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '${limit > 0 ? limit : defaultLimit}',
        if (acceptLanguage.isNotEmpty) 'accept-language': acceptLanguage,
        if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
      },
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) return const <NominatimData>[];

    final decoded = jsonDecode(response.body);

    if (decoded is! List) return const <NominatimData>[];

    final output = <NominatimData>[];

    for (final item in decoded) {
      if (item is! Map) continue;

      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');

      if (lat == null || lon == null) continue;

      final address = item['address'] is Map ? item['address'] as Map : null;

      output.add(
        NominatimData(
          id: (item['place_id'] ?? item['osm_id'] ?? item['display_name'])
              .toString(),
          title: item['display_name']?.toString() ?? 'Sem nome',
          point: LatLng(lat, lon),
          city: address?['city']?.toString() ??
              address?['town']?.toString() ??
              address?['village']?.toString(),
          state: address?['state']?.toString(),
          country: address?['country']?.toString(),
        ),
      );
    }

    return output;
  }
}