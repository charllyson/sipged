// lib/_services/map/map_box/mapbox_key_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:siged/_blocs/system/setup/env.dart';

class MapboxKeyService {
  static String get accessToken {
    // 1) Tenta via Env (ex: dart-define em produção)
    String token = Env.mapboxAccessToken;

    // 2) Fallback para o .env antigo em modo dev
    if (token.trim().isEmpty) {
      token = dotenv.maybeGet('MAPBOX_ACCESS_TOKEN')?.trim() ?? '';
    }

    if (token.trim().isEmpty) {
      throw Exception(
        'MAPBOX_ACCESS_TOKEN não configurado.\n'
            '→ Web (produção): passe --dart-define=MAPBOX_ACCESS_TOKEN=...\n'
            '→ Dev/Mobile/Desktop: defina no arquivo .env',
      );
    }
    return token;
  }
}
