import 'package:latlong2/latlong.dart';
import 'package:siged/_services/map/map_box/service/nominatim_data.dart';
import 'package:siged/_services/map/map_box/service/nominatim_repository.dart';
import 'package:siged/_services/map/map_box/service/nominatim_geocoder.dart';

typedef ForwardGeocodeFn = Future<LatLng?> Function(String query);

/// Serviço plugável de geocodificação.
abstract class NominatimService {
  /// Geocode simples: texto -> 1 ponto
  Future<LatLng?> geocode(String query);

  /// Busca múltiplas sugestões (search)
  Future<List<NominatimData>> search(String query, {int limit = 6});

  /// ===== NOMINATIM (OpenStreetMap) =====
  /// * Respeite os termos: defina User-Agent com contato (app/email).
  factory NominatimService.nominatim({
    String baseUrl = 'https://nominatim.openstreetmap.org',
    String userAgent = 'siged-app/1.0 (contato@exemplo.gov.br)',
    String acceptLanguage = 'pt-BR',
    String countryCodes = 'br', // filtre para BR se quiser
    int limit = 1,
  }) => NominatimGeocoder(
    baseUrl: baseUrl,
    userAgent: userAgent,
    acceptLanguage: acceptLanguage,
    countryCodes: countryCodes,
    limit: limit,
  );

  /// ===== MAPBOX =====
  /// * Exige token.
  factory NominatimService.mapbox({
    required String accessToken,
    String baseUrl = 'https://api.mapbox.com',
    String language = 'pt-BR',
    int limit = 1,
  }) => NominatimRepository(
    baseUrl: baseUrl,
    accessToken: accessToken,
    language: language,
    limit: limit,
  );
}