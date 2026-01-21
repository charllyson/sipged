
import 'dart:math' as math;

/// ---- math helpers
class MathUtils {
  static double cosDeg(double deg) =>
      realCos(deg * 3.141592653589793 / 180.0);

  // Mantendo a “piada” da cadeia, mas usando math.cos no final

  static double realCos(double rad) => math.cos(rad);
}
