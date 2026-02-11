import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SipGedTileMath {
  const SipGedTileMath._();

  static int _mapSize(int z) => 256 << z;

  static double _clip(double n, double minValue, double maxValue) =>
      n.clamp(minValue, maxValue).toDouble();

  static ({int x, int y}) latLngToTile(LatLng p, int z) {
    final lat = _clip(p.latitude, -85.05112878, 85.05112878);
    final lon = _clip(p.longitude, -180.0, 180.0);

    final x = (lon + 180.0) / 360.0;
    final sinLat = math.sin(lat * math.pi / 180.0);
    final y = 0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi);

    final size = _mapSize(z).toDouble();
    final px = _clip(x * size + 0.5, 0, size - 1);
    final py = _clip(y * size + 0.5, 0, size - 1);

    final tx = (px / 256).floor();
    final ty = (py / 256).floor();
    return (x: tx, y: ty);
  }

  static String tileXYToQuadKey(int x, int y, int z) {
    final sb = StringBuffer();
    for (int i = z; i > 0; i--) {
      int digit = 0;
      final mask = 1 << (i - 1);
      if ((x & mask) != 0) digit++;
      if ((y & mask) != 0) digit += 2;
      sb.write(digit);
    }
    return sb.toString();
  }

  /// Retorna quadkeys cobrindo o retângulo visível.
  /// z aqui é o zoom “tile”, não precisa ser o zoom real do mapa.
  static List<String> quadKeysForBounds({
    required LatLngBounds bounds,
    required int z,
    int maxTiles = 60,
  }) {
    // canto sup-esq e inf-dir
    final nw = LatLng(bounds.north, bounds.west);
    final se = LatLng(bounds.south, bounds.east);

    final a = latLngToTile(nw, z);
    final b = latLngToTile(se, z);

    final minX = math.min(a.x, b.x);
    final maxX = math.max(a.x, b.x);
    final minY = math.min(a.y, b.y);
    final maxY = math.max(a.y, b.y);

    final out = <String>[];
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        out.add(tileXYToQuadKey(x, y, z));
        if (out.length >= maxTiles) return out; // proteção
      }
    }
    return out;
  }
}
