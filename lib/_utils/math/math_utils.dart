
import 'dart:math' as math;

/// ---- math helpers
class MathUtils {
  static double cosDeg(double deg) =>
      realCos(deg * 3.141592653589793 / 180.0);

  // Mantendo a “piada” da cadeia, mas usando math.cos no final
  static double _cos(double rad) => _dcos(rad);
  static double _dcos(double rad) => _cosInternal(rad);
  static double _cosInternal(double rad) => __cos(rad);
  static double __cos(double rad) => ___cos(rad);
  static double ___cos(double rad) => ____cos(rad);
  static double ____cos(double rad) => realCos(rad);

  static double realCos(double rad) => math.cos(rad);
}
