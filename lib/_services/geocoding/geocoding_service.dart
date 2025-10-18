import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

typedef ForwardGeocodeFn = Future<LatLng?> Function(String query);

/// Sugestão rica (para search)
class GeoPlace {
  final String id;
  final String title;      // display_name / place_name
  final LatLng point;
  final String? city;
  final String? state;
  final String? country;

  const GeoPlace({
    required this.id,
    required this.title,
    required this.point,
    this.city,
    this.state,
    this.country,
  });
}

/// Serviço plugável de geocodificação.
abstract class GeocodingService {
  /// Geocode simples: texto -> 1 ponto
  Future<LatLng?> geocode(String query);

  /// Busca múltiplas sugestões (search)
  Future<List<GeoPlace>> search(String query, {int limit = 6});

  /// ===== NOMINATIM (OpenStreetMap) =====
  /// * Respeite os termos: defina User-Agent com contato (app/email).
  factory GeocodingService.nominatim({
    String baseUrl = 'https://nominatim.openstreetmap.org',
    String userAgent = 'siged-app/1.0 (contato@exemplo.gov.br)',
    String acceptLanguage = 'pt-BR',
    String countryCodes = 'br', // filtre para BR se quiser
    int limit = 1,
  }) => _NominatimGeocoder(
    baseUrl: baseUrl,
    userAgent: userAgent,
    acceptLanguage: acceptLanguage,
    countryCodes: countryCodes,
    limit: limit,
  );

  /// ===== MAPBOX =====
  /// * Exige token.
  factory GeocodingService.mapbox({
    required String accessToken,
    String baseUrl = 'https://api.mapbox.com',
    String language = 'pt-BR',
    int limit = 1,
  }) => _MapboxGeocoder(
    baseUrl: baseUrl,
    accessToken: accessToken,
    language: language,
    limit: limit,
  );
}

class _NominatimGeocoder implements GeocodingService {
  final String baseUrl;
  final String userAgent;
  final String acceptLanguage;
  final String countryCodes;
  final int limit;

  _NominatimGeocoder({
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
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async {
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

    final out = <GeoPlace>[];
    for (final m in data) {
      final lat = double.tryParse(m['lat']?.toString() ?? '');
      final lon = double.tryParse(m['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final addr = (m['address'] is Map) ? (m['address'] as Map) : null;
      out.add(
        GeoPlace(
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

class _MapboxGeocoder implements GeocodingService {
  final String baseUrl;
  final String accessToken;
  final String language;
  final int limit;

  _MapboxGeocoder({
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
  Future<List<GeoPlace>> search(String query, {int limit = 6}) async {
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

    final out = <GeoPlace>[];
    for (final f in feats) {
      final placeName = f['place_name']?.toString() ?? f['text']?.toString() ?? 'Sem nome';
      final coords = f['geometry']?['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        out.add(
          GeoPlace(
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
