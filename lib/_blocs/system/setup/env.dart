// lib/_config/env.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Token do Mapbox.
  ///
  /// Prioridade:
  /// 1) Web: `--dart-define=MAPBOX_ACCESS_TOKEN=...`
  /// 2) Outras plataformas: `.env` (MAPBOX_ACCESS_TOKEN=...)
  static String get mapboxAccessToken {
    // 1) Web: usa compile-time define
    if (kIsWeb) {
      const fromDefine = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
      if (fromDefine.isNotEmpty) return fromDefine;
    }

    // 2) Mobile/Desktop: usa dotenv
    final fromEnv = dotenv.maybeGet('MAPBOX_ACCESS_TOKEN') ?? '';
    return fromEnv;
  }

  /// Token do Cesium Ion (mesma lógica)
  static String get cesiumIonToken {
    if (kIsWeb) {
      const fromDefine = String.fromEnvironment('CESIUM_ION_TOKEN');
      if (fromDefine.isNotEmpty) return fromDefine;
    }

    final fromEnv = dotenv.maybeGet('CESIUM_ION_TOKEN') ?? '';
    return fromEnv;
  }
}
