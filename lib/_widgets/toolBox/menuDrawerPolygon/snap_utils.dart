import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

class SnapUtils {
  /// Snapa para a borda com maior gradiente de luminância num raio [snapRadius].
  /// Se o gradiente máximo < [minGradient], retorna o ponto original [p].
  static Offset snapToEdge({
    required Offset p,
    required Uint8List? rgba,
    required int w,
    required int h,
    required int snapRadius,
    required int minGradient,
  }) {
    if (rgba == null) return p;

    int cx = p.dx.round().clamp(0, w - 1);
    int cy = p.dy.round().clamp(0, h - 1);
    int bestG = _gradMagAt(cx, cy, rgba, w, h);
    int bestX = cx, bestY = cy;

    final r = snapRadius.clamp(1, 64).toInt();
    for (int dy = -r; dy <= r; dy++) {
      final yy = cy + dy;
      if (yy < 0 || yy >= h) continue;
      final span = (math.sqrt((r * r - dy * dy).toDouble())).floor();
      for (int dx = -span; dx <= span; dx++) {
        final xx = cx + dx;
        if (xx < 0 || xx >= w) continue;
        final g = _gradMagAt(xx, yy, rgba, w, h);
        if (g > bestG) {
          bestG = g;
          bestX = xx;
          bestY = yy;
        }
      }
    }
    return (bestG >= minGradient)
        ? Offset(bestX.toDouble(), bestY.toDouble())
        : p;
  }

  static int _lumaAt(int x, int y, Uint8List data, int w, int h) {
    if (x < 0 || y < 0 || x >= w || y >= h) return 255;
    final idx = (y * w + x) * 4;
    final r = data[idx + 0];
    final g = data[idx + 1];
    final b = data[idx + 2];
    return ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
  }

  static int _gradMagAt(int x, int y, Uint8List data, int w, int h) {
    final l = _lumaAt(x - 1, y, data, w, h);
    final r = _lumaAt(x + 1, y, data, w, h);
    final u = _lumaAt(x, y - 1, data, w, h);
    final d = _lumaAt(x, y + 1, data, w, h);
    final gx = (r - l).abs();
    final gy = (d - u).abs();
    return gx + gy; // ~0..510
  }
}
